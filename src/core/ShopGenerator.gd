class_name ShopGenerator
extends RefCounted
## Generates shop weapon/item offers, level-up stat choices, and Blood Pact offers
## respecting Luck, Ban list, Heat inflation, and locked offers.


static func generate_shop_offers(run: RunState) -> Array[Dictionary]:
	var offers: Array[Dictionary] = []
	for lk in run.locked_shop_offers:
		var copy := (lk as Dictionary).duplicate(true)
		copy["locked"] = true
		offers.append(copy)

	var bans := SaveManager.get_ban_list()
	var discount := SaveManager.get_talent_value("tal_shop_discount")
	if run.pacts.has("pact_bounty_hunt"):
		discount += 35.0
	var heat_inf := run.active_heats.has("heat_inflation")
	var luck := run.stats.get_stat("luck")

	var valid_weapons: Array[Dictionary] = []
	for w in GameData.weapons:
		if not bans.has(String(w["id"])):
			valid_weapons.append(w)
	if valid_weapons.is_empty():
		valid_weapons = GameData.weapons

	var valid_items: Array[Dictionary] = []
	for it in GameData.items:
		if not bans.has(String(it["id"])):
			valid_items.append(it)
	if valid_items.is_empty():
		valid_items = GameData.items

	while offers.size() < 4:
		var is_weapon := randf() < (0.56 if run.weapons.size() < run.max_weapons else 0.42)
		if is_weapon:
			var w: Dictionary = valid_weapons[randi() % valid_weapons.size()]
			var tier := _roll_tier(run.wave, luck, run.pacts.has("pact_bounty_hunt"))
			var price := CombatFormulas.calc_shop_price(int(w["price"]), tier, run.wave, discount, heat_inf)
			offers.append({
				"kind": "weapon",
				"id": String(w["id"]),
				"tier": tier,
				"price": price,
				"locked": false,
			})
		else:
			var it: Dictionary = valid_items[randi() % valid_items.size()]
			var tier := int(it.get("tier", 1))
			var price := CombatFormulas.calc_shop_price(int(it["price"]), 1, run.wave, discount, heat_inf)
			offers.append({
				"kind": "item",
				"id": String(it["id"]),
				"tier": tier,
				"price": price,
				"locked": false,
			})

	return offers


static func _roll_tier(wave: int, luck: float, bounty_boost: bool) -> int:
	var luck_factor := maxf(0.0, luck) * 0.004
	var w_bonus := float(maxi(0, wave - 1)) * 0.032
	if bounty_boost:
		luck_factor += 0.16
	var r := randf()
	var p4 := clampf((w_bonus - 0.14) * 0.4 + luck_factor * 0.25, 0.0, 0.18)
	var p3 := clampf(w_bonus * 0.65 + luck_factor * 0.6, 0.02, 0.34)
	var p2 := clampf(0.18 + w_bonus * 1.1 + luck_factor, 0.18, 0.50)
	if r < p4:
		return 4
	if r < p4 + p3:
		return 3
	if r < p4 + p3 + p2:
		return 2
	return 1


static func generate_levelup_choices(luck: float) -> Array[Dictionary]:
	var pool := [
		{"stat": "max_hp", "base": 6.0, "title": "狂血体魄"},
		{"stat": "damage_pct", "base": 8.0, "title": "血怒增幅"},
		{"stat": "attack_speed_pct", "base": 10.0, "title": "神经超频"},
		{"stat": "melee_damage", "base": 3.0, "title": "重刃淬火"},
		{"stat": "ranged_damage", "base": 3.0, "title": "穿甲弹芯"},
		{"stat": "elemental_damage", "base": 4.0, "title": "奥术共鸣"},
		{"stat": "crit_chance_pct", "base": 6.0, "title": "致命直觉"},
		{"stat": "life_steal", "base": 3.0, "title": "贪婪吸血"},
		{"stat": "armor", "base": 2.0, "title": "深渊铁壁"},
		{"stat": "dodge_pct", "base": 5.0, "title": "幻影步法"},
		{"stat": "move_speed", "base": 16.0, "title": "疾风迅步"},
		{"stat": "harvesting", "base": 8.0, "title": "血晶收割"},
	]
	pool.shuffle()
	var out: Array[Dictionary] = []
	for i in range(4):
		var pick: Dictionary = pool[i]
		var tier := _roll_tier(4, luck, false)
		var mult: float = [1.0, 1.5, 2.2, 3.2][tier - 1]
		var amount := roundf(float(pick["base"]) * mult)
		out.append({
			"stat": String(pick["stat"]),
			"amount": amount,
			"tier": tier,
			"title": String(pick["title"]),
			"desc": StatBlock.format_stat_delta(String(pick["stat"]), amount),
		})
	return out


static func generate_pact_choices(run: RunState) -> Array[Dictionary]:
	var avail: Array[Dictionary] = []
	for p in GameData.pacts:
		if not run.pacts.has(String(p["id"])):
			avail.append(p)
	avail.shuffle()
	var res: Array[Dictionary] = []
	for i in range(mini(3, avail.size())):
		res.append(avail[i])
	return res
