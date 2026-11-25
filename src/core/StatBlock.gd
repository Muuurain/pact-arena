class_name StatBlock
extends RefCounted
## Immutable-friendly stat container supporting positive/negative tradeoffs,
## percentage multipliers, and Blood Pact hard caps.

const STAT_KEYS: Array[String] = [
	"max_hp",
	"hp_regen",
	"life_steal",
	"damage_pct",
	"melee_damage",
	"ranged_damage",
	"elemental_damage",
	"attack_speed_pct",
	"crit_chance_pct",
	"crit_mult_pct",
	"armor",
	"dodge_pct",
	"move_speed",
	"range_bonus",
	"pickup_radius",
	"luck",
	"harvesting",
	"dash_cd_pct",
]

const STAT_LABELS: Dictionary = {
	"max_hp": "最大生命",
	"hp_regen": "生命再生",
	"life_steal": "生命偷取%",
	"damage_pct": "全伤害%",
	"melee_damage": "近战伤害",
	"ranged_damage": "远程伤害",
	"elemental_damage": "元素/召唤",
	"attack_speed_pct": "攻击速度%",
	"crit_chance_pct": "暴击率%",
	"crit_mult_pct": "暴击伤害%",
	"armor": "护甲",
	"dodge_pct": "闪避率%",
	"move_speed": "移动速度",
	"range_bonus": "攻击范围",
	"pickup_radius": "拾取范围",
	"luck": "幸运",
	"harvesting": "收获加成",
	"dash_cd_pct": "血步冷却%",
}

var values: Dictionary = {}


func _init(initial: Dictionary = {}) -> void:
	reset_to_base()
	apply_dict(initial)


func reset_to_base() -> void:
	values = {
		"max_hp": 45.0,
		"hp_regen": 0.6,
		"life_steal": 0.0,
		"damage_pct": 0.0,
		"melee_damage": 0.0,
		"ranged_damage": 0.0,
		"elemental_damage": 0.0,
		"attack_speed_pct": 0.0,
		"crit_chance_pct": 8.0,
		"crit_mult_pct": 175.0,
		"armor": 0.0,
		"dodge_pct": 0.0,
		"move_speed": 275.0,
		"range_bonus": 0.0,
		"pickup_radius": 135.0,
		"luck": 0.0,
		"harvesting": 0.0,
		"dash_cd_pct": 0.0,
	}


func apply_dict(mods: Dictionary, scale: float = 1.0) -> void:
	for k in mods:
		if values.has(k):
			values[k] = float(values[k]) + float(mods[k]) * scale


func get_stat(key: String) -> float:
	return float(values.get(key, 0.0))


func set_stat(key: String, val: float) -> void:
	values[key] = val


func clamp_combat_bounds(pacts: Array[String]) -> void:
	values["max_hp"] = maxf(1.0, float(values["max_hp"]))
	if pacts.has("pact_glass_cannon"):
		values["max_hp"] = minf(20.0, float(values["max_hp"]))
	if pacts.has("pact_crazy_overdrive"):
		values["armor"] = -6.0
	if pacts.has("pact_toxic_blood"):
		# Healing is converted during combat; negative regen does not convert into damage.
		pass
	values["crit_chance_pct"] = clampf(float(values["crit_chance_pct"]), 0.0, 95.0)
	values["crit_mult_pct"] = maxf(120.0, float(values["crit_mult_pct"]))
	values["dodge_pct"] = clampf(float(values["dodge_pct"]), 0.0, 60.0)
	values["move_speed"] = clampf(float(values["move_speed"]), 145.0, 520.0)
	values["pickup_radius"] = clampf(float(values["pickup_radius"]), 60.0, 1800.0)
	values["dash_cd_pct"] = clampf(float(values["dash_cd_pct"]), -50.0, 65.0)
	values["attack_speed_pct"] = maxf(-55.0, float(values["attack_speed_pct"]))
	values["range_bonus"] = maxf(-120.0, float(values["range_bonus"]))


static func format_stat_delta(key: String, amount: float) -> String:
	var label: String = String(STAT_LABELS.get(key, key))
	var sign_str := "+" if amount >= 0.0 else ""
	if is_equal_approx(amount, roundf(amount)):
		return "%s %s%d" % [label, sign_str, int(roundf(amount))]
	return "%s %s%.1f" % [label, sign_str, amount]
