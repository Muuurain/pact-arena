class_name CombatFormulas
extends RefCounted
## Deterministic mathematical formulas for damage, armor mitigation, healing/toxic conversion,
## wave durations, and shop economy.

const TIER_DAMAGE_MULT: Array[float] = [1.0, 1.45, 2.15, 3.30]
const TIER_COOLDOWN_MULT: Array[float] = [1.0, 0.90, 0.80, 0.68]
const TIER_PRICE_MULT: Array[float] = [1.0, 1.85, 3.30, 5.80]


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
		pct_mult *= 1.85
	if pacts.has("pact_lone_wolf"):
		pct_mult *= 1.55

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


static func calc_enemy_damage_after_vuln(base_dmg: float, vuln_mult: float, armor_broken: bool, shield_factor: float = 1.0) -> float:
	var m := vuln_mult
	if armor_broken:
		m *= 1.35
	return maxf(1.0, base_dmg * m * shield_factor)


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


static func calc_shop_price(base_price: int, tier: int, wave: int, discount_pct: float, heat_inflation: bool) -> int:
	var idx := clampi(tier - 1, 0, 3)
	var p := float(base_price) * TIER_PRICE_MULT[idx] * (1.0 + float(max(0, wave - 1)) * 0.07)
	if heat_inflation:
		p *= 1.18
	p *= maxf(0.35, 1.0 - discount_pct / 100.0)
	return maxi(4, int(roundf(p)))


static func calc_reroll_cost(wave: int, rerolls_this_shop: int, free_rerolls: int) -> int:
	if rerolls_this_shop < free_rerolls:
		return 0
	var paid := rerolls_this_shop - free_rerolls
	return maxi(2, 4 + wave + paid * 3)
