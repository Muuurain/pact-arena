class_name SynergyEngine
extends RefCounted
## Evaluates Crimson / Azure / Void faction tiers (2/4/6) and dual-faction resonances.

const FACTIONS: Array[String] = ["crimson", "azure", "void"]

const FACTION_META: Dictionary = {
	"crimson": {
		"name": "猩红",
		"color": Color(0.96, 0.25, 0.37),
		"desc_2": "暴击率+10%，暴击伤害+25%",
		"desc_4": "生命偷取+6%，35%概率触发流血",
		"desc_6": "【血狂形态】每击杀本波攻速+2%(上限60%)，近战范围+30%",
	},
	"azure": {
		"name": "苍蓝",
		"color": Color(0.22, 0.74, 0.97),
		"desc_2": "攻速+14%，攻击范围+35",
		"desc_4": "弹幕穿透/弹射+1，命中冰缓减速25%",
		"desc_6": "【高频超导】每第3次攻击额外劈出追踪苍蓝电弧",
	},
	"void": {
		"name": "虚空",
		"color": Color(0.75, 0.52, 0.99),
		"desc_2": "元素/召唤+18%，攻击挂诅咒(+12%易伤)",
		"desc_4": "召唤/图腾频率+35%，击杀引发虚空爆裂",
		"desc_6": "【深渊吞噬】低于18%血非Boss敌人直接斩杀并掉血晶",
	},
}

const RESONANCE_META: Array[Dictionary] = [
	{
		"id": "res_blood_lightning",
		"name": "血雷风暴",
		"req_text": "猩红2 + 苍蓝2",
		"desc": "猩红2+苍蓝2：暴击劈出2道吸血血雷",
	},
	{
		"id": "res_soul_curse",
		"name": "嗜魂诅咒",
		"req_text": "猩红2 + 虚空2",
		"desc": "猩红2+虚空2：流血或诅咒怪死亡触发血爆",
	},
	{
		"id": "res_void_storm",
		"name": "虚空磁暴",
		"req_text": "苍蓝2 + 虚空2",
		"desc": "苍蓝2+虚空2：电弧/冰霜22%概率生成引力奇点",
	},
]


static func evaluate(weapons: Array, hero_id: String) -> Dictionary:
	var counts := {"crimson": 0, "azure": 0, "void": 0}
	for w in weapons:
		var wid := String(w.get("id", ""))
		var wdef := GameData.get_weapon(wid)
		var f := String(wdef.get("faction", ""))
		if counts.has(f):
			counts[f] = int(counts[f]) + 1

	var eff := counts.duplicate()
	if hero_id == "hero_azure_arcanist":
		# Azure Arcanist reduces Azure synergy requirement by 1 (acts as +1 virtual count when >=1)
		if int(eff["azure"]) >= 1:
			eff["azure"] = int(eff["azure"]) + 1

	var stat_mods: Dictionary = {}
	var flags := {
		"bleed_chance": 0.0,
		"blood_frenzy": false,
		"melee_range_mult": 1.0,
		"extra_pierce": 0,
		"chill_on_hit": false,
		"superconduct": false,
		"curse_vuln": 0.0,
		"summon_speed_pct": 0.0,
		"void_burst_on_kill": false,
		"void_execute_pct": 0.0,
		"res_blood_lightning": false,
		"res_soul_curse": false,
		"res_void_storm": false,
	}

	var c := int(eff["crimson"])
	if c >= 2:
		_add_mod(stat_mods, "crit_chance_pct", 10.0)
		_add_mod(stat_mods, "crit_mult_pct", 25.0)
	if c >= 4:
		_add_mod(stat_mods, "life_steal", 6.0)
		flags["bleed_chance"] = 0.35
	if c >= 6:
		flags["blood_frenzy"] = true
		flags["melee_range_mult"] = 1.30

	var a := int(eff["azure"])
	if a >= 2:
		_add_mod(stat_mods, "attack_speed_pct", 14.0)
		_add_mod(stat_mods, "range_bonus", 35.0)
	if a >= 4:
		flags["extra_pierce"] = 1
		flags["chill_on_hit"] = true
	if a >= 6:
		flags["superconduct"] = true

	var v := int(eff["void"])
	if v >= 2:
		_add_mod(stat_mods, "elemental_damage", 18.0)
		flags["curse_vuln"] = 0.12
	if v >= 4:
		flags["summon_speed_pct"] = 35.0
		flags["void_burst_on_kill"] = true
	if v >= 6:
		flags["void_execute_pct"] = 0.18

	# Dual-Faction Resonance Combos
	if c >= 2 and a >= 2:
		flags["res_blood_lightning"] = true
	if c >= 2 and v >= 2:
		flags["res_soul_curse"] = true
	if a >= 2 and v >= 2:
		flags["res_void_storm"] = true

	return {
		"raw_counts": counts,
		"effective_counts": eff,
		"stat_mods": stat_mods,
		"flags": flags,
	}


static func _add_mod(d: Dictionary, k: String, v: float) -> void:
	d[k] = float(d.get(k, 0.0)) + v


static func get_all_resonances() -> Array[Dictionary]:
	return RESONANCE_META


static func get_active_resonances(flags: Dictionary) -> Array[Dictionary]:
	var res: Array[Dictionary] = []
	for meta in RESONANCE_META:
		if bool(flags.get(String(meta["id"]), false)):
			res.append(meta)
	return res


static func format_active_effects(synergy_info: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var counts: Dictionary = synergy_info.get("effective_counts", {})
	var flags: Dictionary = synergy_info.get("flags", {})
	for f in FACTIONS:
		var cnt := int(counts.get(f, 0))
		if cnt < 2:
			continue
		var meta: Dictionary = FACTION_META[f]
		var fname := String(meta["name"])
		for tier in [2, 4, 6]:
			if cnt >= tier:
				lines.append("[%s%d] %s" % [fname, tier, String(meta["desc_%d" % tier])])
	for r in get_active_resonances(flags):
		lines.append("【%s】 %s" % [String(r["name"]), String(r["desc"])])
	return lines


static func format_shop_summary(synergy_info: Dictionary) -> String:
	var counts: Dictionary = synergy_info.get("effective_counts", {})
	var syn_parts: Array[String] = []
	for f in FACTIONS:
		var cnt := int(counts.get(f, 0))
		syn_parts.append("%s%d" % [String(FACTION_META[f]["name"]), cnt])
	var res_names: Array[String] = []
	for r in get_active_resonances(synergy_info.get("flags", {})):
		res_names.append("【%s】" % String(r["name"]))
	var header := "羁绊：%s" % "  ".join(syn_parts)
	if not res_names.is_empty():
		header += "  " + "".join(res_names)

	var active := format_active_effects(synergy_info)
	if active.is_empty():
		return header + "\n收集 2/4/6 把同系武器激活神系加护，或双系各 2 把触发共鸣（点右上【羁绊】查看）"
	return header + "\n生效：" + "；".join(active)
