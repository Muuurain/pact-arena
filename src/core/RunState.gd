class_name RunState
extends RefCounted
## Complete mutable run state (hero, wave progression, economy, 6 weapon slots,
## passive items, Blood Pacts, synergies, and mid-run resume serialization).

var hero_id: String = "hero_crimson_blade"
var wave: int = 1
var endless_mode: bool = false
var victory_reached: bool = false
var is_run_over: bool = false

var crystals: int = 20
var level: int = 1
var xp: float = 0.0
var next_xp: float = 14.0
var pending_level_ups: int = 0
var pending_chests: int = 0
var total_kills: int = 0
var elites_killed: int = 0
var bosses_killed: int = 0
var max_crystals_held: int = 20
var wave_kills: int = 0

var max_weapons: int = 6
var current_hp: float = 45.0
var revives_left: int = 0
var undying_growth_waves: int = 0

## Each entry: {"id": String, "tier": int (1..4), "awakening": String}
var weapons: Array[Dictionary] = []
## Each entry: item_id String
var items: Array[String] = []
## Activated Blood Pact IDs
var pacts: Array[String] = []
## Active Heat Protocol IDs for this run
var active_heats: Array[String] = []
## Shop lock entries: [{"kind":"weapon"|"item", "id":String, "tier":int}]
var locked_shop_offers: Array[Dictionary] = []
var shop_offers: Array[Dictionary] = []
var shop_rerolls: int = 0
var phase: String = "combat" # "combat" | "shop" | "pact"

var stats: StatBlock = StatBlock.new()
var synergy_info: Dictionary = {}
var weapon_kills_this_run: Dictionary = {}
var levelup_mods: Dictionary = {}


func start_new_run(p_hero_id: String, starting_weapon_id: String, heats_list: Array[String]) -> void:
	hero_id = p_hero_id
	active_heats = heats_list.duplicate()
	wave = 1
	endless_mode = false
	victory_reached = false
	is_run_over = false
	level = 1
	xp = 0.0
	next_xp = CombatFormulas.calc_xp_needed(1)
	pending_level_ups = 0
	pending_chests = 0
	total_kills = 0
	elites_killed = 0
	bosses_killed = 0
	wave_kills = 0
	items.clear()
	pacts.clear()
	weapons.clear()
	locked_shop_offers.clear()
	shop_offers.clear()
	shop_rerolls = 0
	weapon_kills_this_run.clear()
	levelup_mods.clear()
	undying_growth_waves = 0
	phase = "combat"

	var hdef := GameData.get_hero(hero_id)
	max_weapons = int(hdef.get("max_weapons", 6))

	var w_id := starting_weapon_id if not starting_weapon_id.is_empty() else String(hdef.get("default_weapon", "wpn_chainsaw"))
	weapons.append({"id": w_id, "tier": 1, "awakening": ""})

	crystals = 18 + int(roundf(SaveManager.get_talent_value("tal_start_gold")))
	max_crystals_held = crystals
	revives_left = int(SaveManager.get_talent_rank("tal_revive"))

	recompute_effective_stats()
	current_hp = stats.get_stat("max_hp")


func recompute_effective_stats() -> void:
	stats.reset_to_base()

	# 1. Meta Sanctuary Talents
	stats.apply_dict({
		"max_hp": SaveManager.get_talent_value("tal_max_hp"),
		"pickup_radius": SaveManager.get_talent_value("tal_magnet"),
		"luck": SaveManager.get_talent_value("tal_tier_luck"),
	})

	# 2. Hero passive base mods
	var hdef := GameData.get_hero(hero_id)
	stats.apply_dict(hdef.get("stat_mods", {}))
	if hero_id == "hero_void_weaver":
		stats.apply_dict({"elemental_damage": 14.0, "damage_pct": 12.0})
	elif hero_id == "hero_gilded_pactkeeper":
		var stacks := int(crystals / 50)
		stats.apply_dict({"damage_pct": float(stacks * 12)})

	# 3. Heat penalties
	if active_heats.has("heat_fragile"):
		stats.apply_dict({"armor": -2.0})

	# 4. Weapon Mastery micro-bonuses
	var mastery_dmg := 0.0
	for w in weapons:
		var m_lv := SaveManager.get_weapon_mastery_level(String(w["id"]))
		mastery_dmg += float(maxi(0, m_lv - 1)) * 3.0
	if mastery_dmg > 0.0:
		stats.apply_dict({"damage_pct": mastery_dmg})

	# 5. Passive Items & Level-Up Stat Upgrades
	for item_id in items:
		var idef := GameData.get_item(item_id)
		stats.apply_dict(idef.get("mods", {}))
	stats.apply_dict(levelup_mods)

	# 6. Blood Pacts
	for pid in pacts:
		var pdef := GameData.get_pact(pid)
		stats.apply_dict(pdef.get("mods", {}))
	if pacts.has("pact_undying_sacrifice") and undying_growth_waves > 0:
		stats.apply_dict({"damage_pct": float(undying_growth_waves * 8)})
	var pact_master_bonus := SaveManager.get_talent_value("tal_pact_boost") * float(pacts.size())
	if pact_master_bonus > 0.0:
		stats.apply_dict({"damage_pct": pact_master_bonus})

	# 7. Synergies
	synergy_info = SynergyEngine.evaluate(weapons, hero_id)
	stats.apply_dict(synergy_info.get("stat_mods", {}))

	# 8. Bounds & Pact hard caps
	stats.clamp_combat_bounds(pacts)
	if pacts.has("pact_undying_sacrifice"):
		stats.set_stat("max_hp", maxf(1.0, stats.get_stat("max_hp") * 0.90))

	current_hp = minf(current_hp, stats.get_stat("max_hp"))


func get_dynamic_combat_mods() -> Dictionary:
	var dmg_pct_add := 0.0
	var as_pct_add := 0.0
	var max_hp := maxf(1.0, stats.get_stat("max_hp"))
	var missing_pct := clampf((max_hp - current_hp) / max_hp * 100.0, 0.0, 100.0)

	if hero_id == "hero_frenzied_butcher":
		dmg_pct_add += missing_pct * 1.2
	if pacts.has("pact_crazy_overdrive"):
		as_pct_add += missing_pct * 2.2

	var flags: Dictionary = synergy_info.get("flags", {})
	if bool(flags.get("blood_frenzy", false)):
		as_pct_add += minf(60.0, float(wave_kills) * 2.0)

	return {"damage_pct_add": dmg_pct_add, "attack_speed_pct_add": as_pct_add}


func add_crystals(amount: int) -> void:
	crystals = maxi(0, crystals + amount)
	if crystals > max_crystals_held:
		max_crystals_held = crystals
	if hero_id == "hero_gilded_pactkeeper":
		recompute_effective_stats()
	EventBus.crystals_changed.emit(crystals)


func add_xp(amount: float) -> void:
	xp += amount
	while xp >= next_xp:
		xp -= next_xp
		level += 1
		pending_level_ups += 1
		next_xp = CombatFormulas.calc_xp_needed(level)
		EventBus.sfx_requested.emit("sfx_level_up", 0.0)
	EventBus.player_xp_changed.emit(xp, next_xp, level)


func can_add_or_merge_weapon(weapon_id: String, tier: int) -> Dictionary:
	# Returns {"ok": bool, "mode": "merge"|"equip"|"replace"|"full", "merge_idx": int}
	if tier < 4:
		for i in range(weapons.size()):
			var w: Dictionary = weapons[i]
			if String(w["id"]) == weapon_id and int(w["tier"]) == tier:
				return {"ok": true, "mode": "merge", "merge_idx": i}
	if weapons.size() < max_weapons:
		return {"ok": true, "mode": "equip", "merge_idx": -1}
	var best_replace_idx := -1
	var lowest_tier := tier
	for i in range(weapons.size()):
		var w: Dictionary = weapons[i]
		if String(w["id"]) == weapon_id:
			var existing_tier := int(w["tier"])
			if existing_tier < lowest_tier:
				lowest_tier = existing_tier
				best_replace_idx = i
	if best_replace_idx != -1:
		return {"ok": true, "mode": "replace", "merge_idx": best_replace_idx}
	return {"ok": false, "mode": "full", "merge_idx": -1}


func add_or_merge_weapon(weapon_id: String, tier: int) -> Dictionary:
	var chk := can_add_or_merge_weapon(weapon_id, tier)
	if not bool(chk["ok"]):
		return {"success": false, "awakened_slot": -1}
	var awakened_slot := -1
	var mode := String(chk["mode"])
	if mode == "merge":
		var idx := int(chk["merge_idx"])
		var new_tier := mini(4, int(weapons[idx]["tier"]) + 1)
		weapons[idx]["tier"] = new_tier
		if new_tier == 4 and String(weapons[idx].get("awakening", "")).is_empty():
			awakened_slot = idx
	elif mode == "replace":
		var idx := int(chk["merge_idx"])
		weapons[idx] = {"id": weapon_id, "tier": tier, "awakening": ""}
		if tier == 4:
			awakened_slot = idx
	else:
		weapons.append({"id": weapon_id, "tier": tier, "awakening": ""})
		if tier == 4:
			awakened_slot = weapons.size() - 1
	recompute_effective_stats()
	EventBus.run_state_updated.emit()
	return {"success": true, "awakened_slot": awakened_slot}


func try_merge_slots(idx_a: int, idx_b: int) -> int:
	if idx_a == idx_b or idx_a < 0 or idx_b < 0 or idx_a >= weapons.size() or idx_b >= weapons.size():
		return -1
	var wa: Dictionary = weapons[idx_a]
	var wb: Dictionary = weapons[idx_b]
	if String(wa["id"]) != String(wb["id"]) or int(wa["tier"]) != int(wb["tier"]) or int(wa["tier"]) >= 4:
		return -1
	var keep := mini(idx_a, idx_b)
	var drop := maxi(idx_a, idx_b)
	var new_tier := int(weapons[keep]["tier"]) + 1
	weapons[keep]["tier"] = new_tier
	weapons.remove_at(drop)
	recompute_effective_stats()
	EventBus.run_state_updated.emit()
	if new_tier == 4 and String(weapons[keep].get("awakening", "")).is_empty():
		return keep
	return -2 # merged cleanly, no awakening needed


func sell_weapon_slot(idx: int) -> int:
	if weapons.size() <= 1 or idx < 0 or idx >= weapons.size():
		return 0
	var w: Dictionary = weapons[idx]
	var wdef := GameData.get_weapon(String(w["id"]))
	var price := CombatFormulas.calc_shop_price(int(wdef.get("price", 18)), int(w["tier"]), wave, 0.0, false)
	var refund := maxi(5, int(roundf(float(price) * 0.6)))
	weapons.remove_at(idx)
	add_crystals(refund)
	recompute_effective_stats()
	EventBus.run_state_updated.emit()
	return refund


func apply_blood_pact(pact_id: String) -> Dictionary:
	if pacts.has(pact_id):
		return {}
	pacts.append(pact_id)
	var extra_info := {}
	if pact_id == "pact_lone_wolf":
		max_weapons = maxi(1, max_weapons - 1)
		if weapons.size() > max_weapons:
			weapons.remove_at(weapons.size() - 1)
	elif pact_id == "pact_burn_boats":
		current_hp = maxf(1.0, floorf(current_hp * 0.5))
		add_crystals(85)
		var pool := GameData.weapons
		var pick: Dictionary = pool[randi() % pool.size()]
		var res := add_or_merge_weapon(String(pick["id"]), 3)
		if not bool(res["success"]):
			# Replace lowest tier weapon if full
			var low_idx := 0
			for i in range(weapons.size()):
				if int(weapons[i]["tier"]) < int(weapons[low_idx]["tier"]):
					low_idx = i
			weapons[low_idx] = {"id": String(pick["id"]), "tier": 3, "awakening": ""}
		extra_info["gift_weapon"] = String(pick["name"])
	elif pact_id == "pact_undying_sacrifice":
		revives_left += 1

	recompute_effective_stats()
	EventBus.run_state_updated.emit()
	return extra_info


func complete_wave_economy() -> Dictionary:
	var base_harvest := int(roundf(stats.get_stat("harvesting") * 0.8 + float(wave * 3)))
	var interest_rate := 0.05 + SaveManager.get_talent_value("tal_interest") / 100.0
	if hero_id == "hero_gilded_pactkeeper":
		interest_rate += 0.15
	if pacts.has("pact_glass_cannon"):
		interest_rate += 0.25
	if pacts.has("pact_time_rush"):
		interest_rate += 0.35

	var interest := mini(180, int(floorf(float(crystals) * interest_rate)))
	add_crystals(base_harvest + interest)

	if pacts.has("pact_undying_sacrifice"):
		undying_growth_waves += 1

	# Full heal between waves unless Toxic Blood prevents direct heal
	if not pacts.has("pact_toxic_blood"):
		current_hp = stats.get_stat("max_hp")

	return {"harvest": base_harvest, "interest": interest}


func calc_ember_reward() -> int:
	var base := wave * 14 + int(total_kills / 8) + bosses_killed * 55 + elites_killed * 8
	if victory_reached:
		base += 45
	var heat_mult := 1.0 + float(active_heats.size()) * 0.25
	var meta_mult := 1.0 + SaveManager.get_talent_value("tal_ember_gain") / 100.0
	return maxi(10, int(roundf(float(base) * heat_mult * meta_mult)))


func to_dict() -> Dictionary:
	return {
		"hero_id": hero_id,
		"wave": wave,
		"endless_mode": endless_mode,
		"victory_reached": victory_reached,
		"crystals": crystals,
		"level": level,
		"xp": xp,
		"next_xp": next_xp,
		"pending_level_ups": pending_level_ups,
		"pending_chests": pending_chests,
		"total_kills": total_kills,
		"elites_killed": elites_killed,
		"bosses_killed": bosses_killed,
		"max_crystals_held": max_crystals_held,
		"max_weapons": max_weapons,
		"current_hp": current_hp,
		"revives_left": revives_left,
		"undying_growth_waves": undying_growth_waves,
		"weapons": weapons,
		"items": items,
		"pacts": pacts,
		"active_heats": active_heats,
		"locked_shop_offers": locked_shop_offers,
		"shop_offers": shop_offers,
		"shop_rerolls": shop_rerolls,
		"phase": phase,
		"weapon_kills_this_run": weapon_kills_this_run,
		"levelup_mods": levelup_mods,
	}


func from_dict(d: Dictionary) -> void:
	hero_id = String(d.get("hero_id", "hero_crimson_blade"))
	wave = int(d.get("wave", 1))
	endless_mode = bool(d.get("endless_mode", false))
	victory_reached = bool(d.get("victory_reached", false))
	crystals = int(d.get("crystals", 20))
	level = int(d.get("level", 1))
	xp = float(d.get("xp", 0.0))
	next_xp = float(d.get("next_xp", 14.0))
	pending_level_ups = int(d.get("pending_level_ups", 0))
	pending_chests = int(d.get("pending_chests", 0))
	total_kills = int(d.get("total_kills", 0))
	elites_killed = int(d.get("elites_killed", 0))
	bosses_killed = int(d.get("bosses_killed", 0))
	max_crystals_held = int(d.get("max_crystals_held", crystals))
	max_weapons = int(d.get("max_weapons", 6))
	current_hp = float(d.get("current_hp", 45.0))
	revives_left = int(d.get("revives_left", 0))
	undying_growth_waves = int(d.get("undying_growth_waves", 0))

	weapons.clear()
	for w in d.get("weapons", []):
		weapons.append(w)
	items.clear()
	for it in d.get("items", []):
		items.append(String(it))
	pacts.clear()
	for p in d.get("pacts", []):
		pacts.append(String(p))
	active_heats.clear()
	for h in d.get("active_heats", []):
		active_heats.append(String(h))
	locked_shop_offers.clear()
	for lk in d.get("locked_shop_offers", []):
		locked_shop_offers.append(lk)
	shop_offers.clear()
	for so in d.get("shop_offers", []):
		shop_offers.append(so)
	shop_rerolls = int(d.get("shop_rerolls", 0))
	phase = String(d.get("phase", "shop"))
	weapon_kills_this_run = d.get("weapon_kills_this_run", {}).duplicate()
	levelup_mods = d.get("levelup_mods", {}).duplicate()
	is_run_over = false
	recompute_effective_stats()


func apply_levelup_choice(stat_key: String, amount: float) -> void:
	levelup_mods[stat_key] = float(levelup_mods.get(stat_key, 0.0)) + amount
	pending_level_ups = maxi(0, pending_level_ups - 1)
	recompute_effective_stats()
	if stat_key == "max_hp" and not pacts.has("pact_toxic_blood"):
		current_hp = minf(stats.get_stat("max_hp"), current_hp + amount)
	EventBus.run_state_updated.emit()
