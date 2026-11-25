class_name CombatFormulas
extends RefCounted
## Deterministic mathematical formulas for damage, armor mitigation, healing/toxic conversion,
## wave durations, and shop economy.

const TIER_DAMAGE_MULT: Array[float] = [1.0, 1.32, 1.75, 2.38]
const TIER_COOLDOWN_MULT: Array[float] = [1.0, 0.93, 0.85, 0.77]
const TIER_PRICE_MULT: Array[float] = [1.0, 1.90, 3.50, 6.20]


static func calc_weapon_damage(
	weapon_def: Dictionary,
	tier: int,
	stats: StatBlock,
	pacts: Array[String],
	extra_mult: float = 1.0
) -> Dictionary:
	var idx := clampi(tier - 1, 0, 3)
	var base_dmg := float(weapon_def.get("base_damage", 10.0)) * TIER_DAMAGE_MULT[idx]
	var scale_tag := String(weapon_def.get("scale_tag", "melee"))
	var bonus := 0.0
	match scale_tag:
		"melee":
			bonus = stats.get_stat("melee_damage")
		"ranged":
			bonus = stats.get_stat("ranged_damage")
		"elemental":
			bonus = stats.get_stat("elemental_damage")
		_:
			bonus = stats.get_stat("melee_damage") * 0.5 + stats.get_stat("elemental_damage") * 0.5

	var raw := maxf(1.0, base_dmg + bonus * float(weapon_def.get("scale_ratio", 1.0)))
	var pct_mult := maxf(0.25, 1.0 + stats.get_stat("damage_pct") / 100.0)

	if pacts.has("pact_glass_cannon"):
		pct_mult *= 1.55
	if pacts.has("pact_lone_wolf"):
		pct_mult *= 1.40

	var dmg := raw * pct_mult * extra_mult
	var crit_chance := clampf(stats.get_stat("crit_chance_pct") + float(weapon_def.get("crit_bonus", 0.0)), 0.0, 95.0)
	var is_crit := randf() * 100.0 < crit_chance
	if is_crit:
		var crit_mult := (stats.get_stat("crit_mult_pct") + float(weapon_def.get("crit_mult_bonus", 0.0))) / 100.0
		dmg *= maxf(1.2, crit_mult)

	return {
		"damage": maxf(1.0, dmg),
		"is_crit": is_crit,
	}


static func calc_weapon_cooldown(weapon_def: Dictionary, tier: int, stats: StatBlock, extra_speed_pct: float = 0.0) -> float:
	var idx := clampi(tier - 1, 0, 3)
	var base_cd := float(weapon_def.get("base_cooldown", 0.8)) * TIER_COOLDOWN_MULT[idx]
	var as_mult := maxf(0.25, 1.0 + (stats.get_stat("attack_speed_pct") + extra_speed_pct) / 100.0)
	return maxf(0.08, base_cd / as_mult)


static func calc_player_damage_taken(raw_damage: float, stats: StatBlock) -> float:
	var armor := stats.get_stat("armor")
	var mult := 1.0
	if armor >= 0.0:
		mult = 100.0 / (100.0 + armor * 8.0)
	else:
		mult = 1.0 + absf(armor) * 0.07
	return maxf(1.0, raw_damage * mult)


static func calc_enemy_damage_after_vuln(base_dmg: float, vuln_mult: float, armor_broken: bool, shield_factor: float = 1.0, resilience: float = 0.0) -> float:
	var m := vuln_mult
	if armor_broken:
		m *= 1.35
	else:
		m *= (1.0 - clampf(resilience, 0.0, 0.50))
	return maxf(1.0, base_dmg * m * shield_factor)


static func calc_enemy_wave_scale(wave: int) -> float:
	var w := float(maxi(0, wave - 1))
	var scale := 1.0 + w * 0.42 + pow(w, 1.68) * 0.14
	if wave > 10:
		scale *= pow(1.28, float(wave - 10))
	return scale


static func calc_boss_wave_scale(wave: int, boss_id: String) -> float:
	if boss_id == "boss_inquisitor":
		return 1.0 + float(maxi(0, wave - 5)) * 0.30
	var extra := maxi(0, wave - 10)
	return pow(1.26, float(extra))


static func calc_enemy_armor_resilience(danger_level: int, is_boss: bool, is_elite: bool) -> float:
	if is_boss:
		return clampf(0.08 + float(danger_level) * 0.052, 0.08, 0.40)
	if is_elite and danger_level >= 2:
		return clampf(0.04 + float(danger_level - 1) * 0.06, 0.0, 0.30)
	return 0.0


static func calc_wave_duration(wave: int, pacts: Array[String]) -> float:
	var dur := 26.0 + minf(22.0, float(wave - 1) * 2.5)
	if wave == 5 or wave == 10:
		dur = 52.0
	elif wave > 10:
		dur = 45.0
	if pacts.has("pact_time_rush"):
		dur *= 0.80
	return maxf(18.0, dur)


static func calc_xp_needed(level: int) -> float:
	return floorf(14.0 + float(level - 1) * 11.0 + pow(float(level - 1), 1.35) * 4.5)


static func calc_shop_price(
	base_price: int,
	tier: int,
	wave: int,
	discount_pct: float,
	heat_inflation: bool,
	danger_price_mult: float = 1.0
) -> int:
	var idx := clampi(tier - 1, 0, 3)
	var w := float(maxi(0, wave - 1))
	var wave_inflation := 1.0 + w * 0.13 + pow(w, 1.45) * 0.025
	var p := float(base_price) * TIER_PRICE_MULT[idx] * wave_inflation
	p *= maxf(1.0, danger_price_mult)
	if heat_inflation:
		p *= 1.18
	p *= maxf(0.35, 1.0 - discount_pct / 100.0)
	return maxi(4, int(roundf(p)))


static func calc_reroll_cost(wave: int, rerolls_this_shop: int, free_rerolls: int, danger_price_mult: float = 1.0) -> int:
	if rerolls_this_shop < free_rerolls:
		return 0
	var paid := rerolls_this_shop - free_rerolls
	var base := 5 + wave * 2
	var step := 4 + int(roundf(float(wave) * 0.75))
	var raw := float(base + paid * step + paid * paid * 2) * maxf(1.0, danger_price_mult)
	return maxi(4, int(roundf(raw)))


static func calc_shop_sink_cost(
	base_cost: int,
	step_cost: int,
	times_bought: int,
	wave: int,
	danger_price_mult: float = 1.0
) -> int:
	var inflation := 1.0 + float(maxi(0, wave - 1)) * 0.08
	var raw := (float(base_cost) + float(times_bought) * float(step_cost) + float(times_bought * times_bought) * 6.0) * inflation * maxf(1.0, danger_price_mult)
	return maxi(10, int(roundf(raw)))
