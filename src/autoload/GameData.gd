extends Node
## Central static game catalog for Heroes, 14 Weapons + 28 Red Awakenings,
## 18 Passive Items, 10 Blood Pacts, 12 Meta-Talents, 8 Heat Protocols, and Enemies/Waves.

var heroes: Array[Dictionary] = []
var weapons: Array[Dictionary] = []
var items: Array[Dictionary] = []
var pacts: Array[Dictionary] = []
var talents: Array[Dictionary] = []
var heats: Array[Dictionary] = []
var difficulties: Array[Dictionary] = []
var shop_sinks: Array[Dictionary] = []
var enemies: Dictionary = {}

var _hero_map: Dictionary = {}
var _weapon_map: Dictionary = {}
var _item_map: Dictionary = {}
var _pact_map: Dictionary = {}
var _talent_map: Dictionary = {}
var _heat_map: Dictionary = {}


func _ready() -> void:
	_build_heroes()
	_build_weapons()
	_build_items()
	_build_pacts()
	_build_talents()
	_build_heats()
	_build_difficulties()
	_build_shop_sinks()
	_build_enemies()
	_index_all()


func _index_all() -> void:
	for h in heroes:
		_hero_map[String(h["id"])] = h
	for w in weapons:
		_weapon_map[String(w["id"])] = w
	for it in items:
		_item_map[String(it["id"])] = it
	for p in pacts:
		_pact_map[String(p["id"])] = p
	for t in talents:
		_talent_map[String(t["id"])] = t
	for ht in heats:
		_heat_map[String(ht["id"])] = ht


func get_hero(id: String) -> Dictionary:
	return _hero_map.get(id, {})


func get_weapon(id: String) -> Dictionary:
	return _weapon_map.get(id, {})


func get_item(id: String) -> Dictionary:
	return _item_map.get(id, {})


func get_pact(id: String) -> Dictionary:
	return _pact_map.get(id, {})


func get_talent(id: String) -> Dictionary:
	return _talent_map.get(id, {})


func get_heat(id: String) -> Dictionary:
	return _heat_map.get(id, {})


func get_difficulty(level: int) -> Dictionary:
	var idx := clampi(level, 0, difficulties.size() - 1)
	if idx >= 0 and idx < difficulties.size():
		return difficulties[idx]
	return {}


func get_shop_sink(id: String) -> Dictionary:
	for s in shop_sinks:
		if String(s["id"]) == id:
			return s
	return {}


func get_enemy(id: String) -> Dictionary:
	return enemies.get(id, {})


func _build_heroes() -> void:
	heroes = [
		{
			"id": "hero_crimson_blade",
			"name": "血刃游侠",
			"title": "血步刺客",
			"sprite": "res://assets/art/sprites/heroes/hero_crimson_blade.png",
			"color": Color(0.96, 0.25, 0.37),
			"default_weapon": "wpn_chainsaw",
			"max_weapons": 6,
			"stat_mods": {"move_speed": 28.0, "dash_cd_pct": 25.0, "crit_chance_pct": 6.0},
			"short_desc": "血步极速充能 · 穿敌流血破甲",
			"passive_desc": "血步冷却缩短 25%，穿敌时顺势斩出流血与破甲剑气，适合高速游走贴脸爆发。",
			"unlock_type": "starter",
			"unlock_desc": "初始可用",
			"unlock_cost": 0,
		},
		{
			"id": "hero_azure_arcanist",
			"name": "苍蓝魔导",
			"title": "超导魔导",
			"sprite": "res://assets/art/sprites/heroes/hero_azure_arcanist.png",
			"color": Color(0.22, 0.74, 0.97),
			"default_weapon": "wpn_arc_staff",
			"max_weapons": 6,
			"stat_mods": {"max_hp": -7.0, "elemental_damage": 8.0, "attack_speed_pct": 12.0, "range_bonus": 30.0},
			"short_desc": "苍蓝羁绊 -1 人成型 · 高频控场",
			"passive_desc": "苍蓝神系只需 1/3/5 把即可凑齐共鸣，出手更快射程更远，代价是初始生命 -7。",
			"unlock_type": "starter",
			"unlock_desc": "初始可用",
			"unlock_cost": 0,
		},
		{
			"id": "hero_frenzied_butcher",
			"name": "狂战屠夫",
			"title": "狂血战狂",
			"sprite": "res://assets/art/sprites/heroes/hero_frenzied_butcher.png",
			"color": Color(0.98, 0.45, 0.09),
			"default_weapon": "wpn_battleaxe",
			"max_weapons": 6,
			"stat_mods": {"max_hp": 14.0, "armor": -3.0, "melee_damage": 6.0, "life_steal": 4.0},
			"short_desc": "天生负甲吸血 · 越残暴伤越高",
			"passive_desc": "初始护甲 -3；每损失 1% 生命值全伤害 +1.2%，越在刀尖舔血火力越狂暴。",
			"unlock_type": "challenge",
			"unlock_desc": "只带近战武器闯过第 3 波（或花 180 余烬解锁）",
			"unlock_cost": 180,
		},
		{
			"id": "hero_one_arm_asura",
			"name": "独臂修罗",
			"title": "极简单武",
			"sprite": "res://assets/art/sprites/heroes/hero_one_arm_asura.png",
			"color": Color(0.98, 0.75, 0.14),
			"default_weapon": "wpn_vibroblade",
			"max_weapons": 1,
			"stat_mods": {"attack_speed_pct": 155.0, "damage_pct": 85.0, "range_bonus": 55.0, "crit_chance_pct": 12.0},
			"short_desc": "独孤一剑流 · 商店高阶直接替换",
			"passive_desc": "只能持 1 把武器，但获得 +155% 攻速、+85% 伤害与 +55 攻击范围，商店刷出更高阶同款可直接替换升级！",
			"unlock_type": "challenge",
			"unlock_desc": "单局签下 2 份血契并获胜（或花 260 余烬解锁）",
			"unlock_cost": 260,
		},
		{
			"id": "hero_gilded_pactkeeper",
			"name": "契约守财奴",
			"title": "复利行者",
			"sprite": "res://assets/art/sprites/heroes/hero_gilded_pactkeeper.png",
			"color": Color(0.98, 0.80, 0.08),
			"default_weapon": "wpn_twin_pistols",
			"max_weapons": 6,
			"stat_mods": {"harvesting": 14.0, "luck": 20.0, "max_hp": -4.0},
			"short_desc": "囤血晶变强 · 过关额外生息",
			"passive_desc": "身上每攒 60 血晶全伤害 +10%（上限 +120%），过关额外拿 8% 存钱利息。",
			"unlock_type": "challenge",
			"unlock_desc": "单局身上同时持有 300 血晶（或花 220 余烬解锁）",
			"unlock_cost": 220,
		},
		{
			"id": "hero_void_weaver",
			"name": "虚空织命者",
			"title": "深渊先知",
			"sprite": "res://assets/art/sprites/heroes/hero_void_weaver.png",
			"color": Color(0.66, 0.33, 0.97),
			"default_weapon": "wpn_void_grimoire",
			"max_weapons": 6,
			"stat_mods": {"elemental_damage": 12.0, "dodge_pct": 8.0, "pickup_radius": 45.0},
			"short_desc": "召唤与元素 +55% · 每波进场赐福",
			"passive_desc": "召唤体与法术天然威能提升 55%，每波开局额外领一道随机深渊祝福。",
			"unlock_type": "challenge",
			"unlock_desc": "击败第 10 波深渊双生主宰（或花 320 余烬解锁）",
			"unlock_cost": 320,
		},
	]


func _build_weapons() -> void:
	weapons = [
		# --- CRIMSON (5) ---
		{
			"id": "wpn_chainsaw",
			"name": "裂血链锯",
			"faction": "crimson",
			"weapon_class": "melee",
			"scale_tag": "melee",
			"scale_ratio": 1.0,
			"pattern": "arc_sweep",
			"base_damage": 18.0,
			"base_cooldown": 0.72,
			"base_range": 155.0,
			"crit_bonus": 8.0,
			"crit_mult_bonus": 25.0,
			"knockback": 110.0,
			"pierce": 99,
			"bounces": 0,
			"proj_speed": 0.0,
			"price": 18,
			"sprite": "res://assets/art/sprites/weapons/wpn_chainsaw.png",
			"proj_sprite": "res://assets/art/sprites/projectiles/slash_arc.png",
			"sfx": "sfx_slash",
			"desc": "高速齿轮撕裂近敌，高暴击并带猛烈击退。",
			"awakenings": [
				{"id": "awk_chainsaw_spin", "name": "狂风绞肉锯", "desc": "化作 360° 无死角旋风切割，挥砍范围 +45%。"},
				{"id": "awk_chainsaw_drill", "name": "断骨破甲钻", "desc": "命中必挂 4 秒流血与破甲，全伤再 +45%。"},
			],
		},
		{
			"id": "wpn_battleaxe",
			"name": "猩红战斧",
			"faction": "crimson",
			"weapon_class": "melee",
			"scale_tag": "melee",
			"scale_ratio": 1.35,
			"pattern": "heavy_cleave",
			"base_damage": 30.0,
			"base_cooldown": 1.15,
			"base_range": 175.0,
			"crit_bonus": 12.0,
			"crit_mult_bonus": 50.0,
			"knockback": 220.0,
			"pierce": 99,
			"bounces": 0,
			"proj_speed": 0.0,
			"price": 22,
			"sprite": "res://assets/art/sprites/weapons/wpn_battleaxe.png",
			"proj_sprite": "res://assets/art/sprites/projectiles/slash_arc.png",
			"sfx": "sfx_heavy_cleave",
			"desc": "重劈一斧清扫前排，吃满近战加成与震退。",
			"awakenings": [
				{"id": "awk_axe_quake", "name": "处刑震地斧", "desc": "重劈落地瞬间在前方震出大片猩红冲击波。"},
				{"id": "awk_axe_vamp", "name": "嗜血狂斧", "desc": "暴击与击杀吸血翻倍，攻速 +35%。"},
			],
		},
		{
			"id": "wpn_twin_pistols",
			"name": "猎魔双铳",
			"faction": "crimson",
			"weapon_class": "ranged",
			"scale_tag": "ranged",
			"scale_ratio": 0.9,
			"pattern": "twin_shot",
			"base_damage": 13.0,
			"base_cooldown": 0.48,
			"base_range": 430.0,
			"crit_bonus": 10.0,
			"crit_mult_bonus": 25.0,
			"knockback": 55.0,
			"pierce": 1,
			"bounces": 0,
			"proj_speed": 760.0,
			"price": 20,
			"sprite": "res://assets/art/sprites/weapons/wpn_twin_pistols.png",
			"proj_sprite": "res://assets/art/sprites/projectiles/proj_crimson.png",
			"sfx": "sfx_gun_shot",
			"desc": "双铳急促连射，弹道轻快暴击率高。",
			"awakenings": [
				{"id": "awk_pistol_fan", "name": "血弹暴雨", "desc": "一次射出 4 发扇形高速弹幕。"},
				{"id": "awk_pistol_snipe", "name": "狙心穿刺枪", "desc": "穿透 +3 且暴击率额外 +35%。"},
			],
		},
		{
			"id": "wpn_blood_scythe",
			"name": "鲜血飞镰",
			"faction": "crimson",
			"weapon_class": "melee",
			"scale_tag": "melee",
			"scale_ratio": 1.0,
			"pattern": "orbit_scythe",
			"base_damage": 19.0,
			"base_cooldown": 0.95,
			"base_range": 330.0,
			"crit_bonus": 6.0,
			"crit_mult_bonus": 20.0,
			"knockback": 75.0,
			"pierce": 99,
			"bounces": 0,
			"proj_speed": 580.0,
			"price": 21,
			"sprite": "res://assets/art/sprites/weapons/wpn_blood_scythe.png",
			"proj_sprite": "res://assets/art/sprites/weapons/wpn_blood_scythe.png",
			"sfx": "sfx_slash",
			"desc": "甩出回旋死镰切开沿途怪堆，随后飞回手中。",
			"awakenings": [
				{"id": "awk_scythe_twin", "name": "血月双旋", "desc": "一次掷出 2 把交叉回旋血镰。"},
				{"id": "awk_scythe_reap", "name": "收割死镰", "desc": "对半血以下敌人伤害提升 75%。"},
			],
		},
		{
			"id": "wpn_blood_spear",
			"name": "献祭长矛",
			"faction": "crimson",
			"weapon_class": "melee",
			"scale_tag": "melee",
			"scale_ratio": 1.15,
			"pattern": "thrust",
			"base_damage": 24.0,
			"base_cooldown": 0.78,
			"base_range": 250.0,
			"crit_bonus": 10.0,
			"crit_mult_bonus": 35.0,
			"knockback": 120.0,
			"pierce": 99,
			"bounces": 0,
			"proj_speed": 0.0,
			"price": 19,
			"sprite": "res://assets/art/sprites/weapons/wpn_blood_spear.png",
			"proj_sprite": "res://assets/art/sprites/projectiles/proj_crimson.png",
			"sfx": "sfx_slash",
			"desc": "超长距离直线穿刺，精准打击成排冲锋怪物。",
			"awakenings": [
				{"id": "awk_spear_lance", "name": "贯穿魔枪", "desc": "突刺距离翻倍且尾端触发血爆。"},
				{"id": "awk_spear_triple", "name": "血矛齐射", "desc": "每次突刺呈三叉戟方向同时射出 3 道枪影。"},
			],
		},
		# --- AZURE (5) ---
		{
			"id": "wpn_arc_staff",
			"name": "磁暴电弧杖",
			"faction": "azure",
			"weapon_class": "arcane",
			"scale_tag": "elemental",
			"scale_ratio": 1.1,
			"pattern": "chain_lightning",
			"base_damage": 17.0,
			"base_cooldown": 0.78,
			"base_range": 420.0,
			"crit_bonus": 5.0,
			"crit_mult_bonus": 15.0,
			"knockback": 25.0,
			"pierce": 1,
			"bounces": 4,
			"proj_speed": 0.0,
			"price": 21,
			"sprite": "res://assets/art/sprites/weapons/wpn_arc_staff.png",
			"proj_sprite": "res://assets/art/sprites/projectiles/proj_azure.png",
			"sfx": "sfx_chain_lightning",
			"desc": "瞬发跳跃连锁电弧，轻松清理密集小怪群。",
			"awakenings": [
				{"id": "awk_arc_matrix", "name": "雷神矩阵", "desc": "电弧跳跃次数提升至 9 次，伤害衰减归零。"},
				{"id": "awk_arc_pillar", "name": "天罚雷柱", "desc": "主目标位置落下雷爆范围伤害并强力减速。"},
			],
		},
		{
			"id": "wpn_ice_prism",
			"name": "寒冰棱镜",
			"faction": "azure",
			"weapon_class": "arcane",
			"scale_tag": "elemental",
			"scale_ratio": 1.0,
			"pattern": "ice_cone",
			"base_damage": 14.0,
			"base_cooldown": 0.85,
			"base_range": 410.0,
			"crit_bonus": 4.0,
			"crit_mult_bonus": 15.0,
			"knockback": 60.0,
			"pierce": 2,
			"bounces": 0,
			"proj_speed": 640.0,
			"price": 19,
			"sprite": "res://assets/art/sprites/weapons/wpn_ice_prism.png",
			"proj_sprite": "res://assets/art/sprites/projectiles/proj_azure.png",
			"sfx": "sfx_ice_cast",
			"desc": "扇形齐射 3 枚冰晶碎片，穿透并大幅减速敌人。",
			"awakenings": [
				{"id": "awk_ice_nova", "name": "极寒新星", "desc": "每次发射数量增至 5 枚并环绕扩散。"},
				{"id": "awk_ice_shatter", "name": "绝对零度", "desc": "冰缓敌人被击中时额外炸开冰霜溅射。"},
			],
		},
		{
			"id": "wpn_laser_wing",
			"name": "脉冲激光翼",
			"faction": "azure",
			"weapon_class": "ranged",
			"scale_tag": "elemental",
			"scale_ratio": 1.15,
			"pattern": "laser_beam",
			"base_damage": 23.0,
			"base_cooldown": 0.92,
			"base_range": 500.0,
			"crit_bonus": 8.0,
			"crit_mult_bonus": 25.0,
			"knockback": 35.0,
			"pierce": 99,
			"bounces": 0,
			"proj_speed": 0.0,
			"price": 23,
			"sprite": "res://assets/art/sprites/weapons/wpn_laser_wing.png",
			"proj_sprite": "res://assets/art/sprites/projectiles/proj_azure.png",
			"sfx": "sfx_laser_zap",
			"desc": "穿透直线光束瞬间洞穿整排敌人。",
			"awakenings": [
				{"id": "awk_laser_twin", "name": "折射双星炮", "desc": "额外朝次近敌人发射第二道激光。"},
				{"id": "awk_laser_over", "name": "超频灼烧光束", "desc": "激光加粗且附加 45% 破甲伤害。"},
			],
		},
		{
			"id": "wpn_ion_gun",
			"name": "回弹离子枪",
			"faction": "azure",
			"weapon_class": "ranged",
			"scale_tag": "ranged",
			"scale_ratio": 1.0,
			"pattern": "ricochet_orb",
			"base_damage": 16.0,
			"base_cooldown": 0.62,
			"base_range": 450.0,
			"crit_bonus": 6.0,
			"crit_mult_bonus": 20.0,
			"knockback": 45.0,
			"pierce": 1,
			"bounces": 3,
			"proj_speed": 690.0,
			"price": 20,
			"sprite": "res://assets/art/sprites/weapons/wpn_ion_gun.png",
			"proj_sprite": "res://assets/art/sprites/projectiles/proj_azure.png",
			"sfx": "sfx_gun_shot",
			"desc": "高能离子弹会在敌人之间自动弹射 3 次。",
			"awakenings": [
				{"id": "awk_ion_storm", "name": "弹幕风暴", "desc": "弹射次数提升至 7 次且每次弹射伤害 +18%。"},
				{"id": "awk_ion_pulse", "name": "聚能磁球", "desc": "每次弹射爆出小型苍蓝冲击波。"},
			],
		},
		{
			"id": "wpn_vibroblade",
			"name": "高频震荡刃",
			"faction": "azure",
			"weapon_class": "melee",
			"scale_tag": "melee",
			"scale_ratio": 0.85,
			"pattern": "rapid_stab",
			"base_damage": 12.0,
			"base_cooldown": 0.34,
			"base_range": 145.0,
			"crit_bonus": 12.0,
			"crit_mult_bonus": 30.0,
			"knockback": 40.0,
			"pierce": 99,
			"bounces": 0,
			"proj_speed": 0.0,
			"price": 19,
			"sprite": "res://assets/art/sprites/weapons/wpn_vibroblade.png",
			"proj_sprite": "res://assets/art/sprites/projectiles/slash_arc.png",
			"sfx": "sfx_slash",
			"desc": "攻速快到起残影的轻刃，贴脸收割利器。",
			"awakenings": [
				{"id": "awk_vibro_sonic", "name": "音速残影", "desc": "攻击间隔大幅缩短 35%，挥砍同时劈出电弧。"},
				{"id": "awk_vibro_wave", "name": "震荡波纹", "desc": "每砍 3 刀就向四周震开一圈苍蓝冲击波。"},
			],
		},
		# --- VOID (4) ---
		{
			"id": "wpn_bone_spear",
			"name": "蚀骨骨矛",
			"faction": "void",
			"weapon_class": "ranged",
			"scale_tag": "elemental",
			"scale_ratio": 1.05,
			"pattern": "homing_bone",
			"base_damage": 20.0,
			"base_cooldown": 0.68,
			"base_range": 470.0,
			"crit_bonus": 7.0,
			"crit_mult_bonus": 25.0,
			"knockback": 70.0,
			"pierce": 2,
			"bounces": 0,
			"proj_speed": 620.0,
			"price": 20,
			"sprite": "res://assets/art/sprites/weapons/wpn_bone_spear.png",
			"proj_sprite": "res://assets/art/sprites/projectiles/proj_void.png",
			"sfx": "sfx_laser_zap",
			"desc": "自动追踪敌人的虚空骨矛，命中附加易伤诅咒。",
			"awakenings": [
				{"id": "awk_bone_swarm", "name": "千骨齐飞", "desc": "一次射出 3 发追踪骨矛。"},
				{"id": "awk_bone_burst", "name": "诅咒爆裂", "desc": "命中直接引发小型虚空爆炸。"},
			],
		},
		{
			"id": "wpn_void_grimoire",
			"name": "虚空魔典",
			"faction": "void",
			"weapon_class": "summon",
			"scale_tag": "elemental",
			"scale_ratio": 1.1,
			"pattern": "summon_drone",
			"base_damage": 15.0,
			"base_cooldown": 0.60,
			"base_range": 420.0,
			"crit_bonus": 5.0,
			"crit_mult_bonus": 15.0,
			"knockback": 35.0,
			"pierce": 1,
			"bounces": 0,
			"proj_speed": 650.0,
			"price": 22,
			"sprite": "res://assets/art/sprites/weapons/wpn_void_grimoire.png",
			"proj_sprite": "res://assets/art/sprites/projectiles/proj_void.png",
			"sfx": "sfx_ice_cast",
			"desc": "生成环绕浮游虚空灵体，自动齐射追踪法球。",
			"awakenings": [
				{"id": "awk_grim_fleet", "name": "噬魂舰队", "desc": "召唤体发射双倍弹幕且射速 +30%。"},
				{"id": "awk_grim_nova", "name": "虚空核爆灵", "desc": "每发法球落点爆炸溅射周围敌人。"},
			],
		},
		{
			"id": "wpn_abyss_mortar",
			"name": "深渊迫击炮",
			"faction": "void",
			"weapon_class": "ranged",
			"scale_tag": "elemental",
			"scale_ratio": 1.25,
			"pattern": "mortar_aoe",
			"base_damage": 32.0,
			"base_cooldown": 1.28,
			"base_range": 480.0,
			"crit_bonus": 6.0,
			"crit_mult_bonus": 30.0,
			"knockback": 180.0,
			"pierce": 99,
			"bounces": 0,
			"proj_speed": 430.0,
			"price": 23,
			"sprite": "res://assets/art/sprites/weapons/wpn_abyss_mortar.png",
			"proj_sprite": "res://assets/art/sprites/projectiles/proj_void.png",
			"sfx": "sfx_mortar_boom",
			"desc": "向密集敌群抛射虚空炮弹，落地大范围轰炸。",
			"awakenings": [
				{"id": "awk_mortar_hole", "name": "湮灭黑洞炮", "desc": "落点生成引力奇点把敌人吸到中心再炸裂。"},
				{"id": "awk_mortar_tri", "name": "三联地毯轰炸", "desc": "每次发射连续轰出 3 发迫击炮弹。"},
			],
		},
		{
			"id": "wpn_calamity_totem",
			"name": "灾厄图腾",
			"faction": "void",
			"weapon_class": "summon",
			"scale_tag": "elemental",
			"scale_ratio": 1.15,
			"pattern": "turret_deploy",
			"base_damage": 16.0,
			"base_cooldown": 0.55,
			"base_range": 430.0,
			"crit_bonus": 6.0,
			"crit_mult_bonus": 20.0,
			"knockback": 45.0,
			"pierce": 2,
			"bounces": 0,
			"proj_speed": 680.0,
			"price": 22,
			"sprite": "res://assets/art/sprites/weapons/wpn_calamity_totem.png",
			"proj_sprite": "res://assets/art/sprites/projectiles/proj_void.png",
			"sfx": "sfx_laser_zap",
			"desc": "场上部署自动哨戒炮台，全自动追着怪群开火。",
			"awakenings": [
				{"id": "awk_totem_dual", "name": "双联毁灭塔", "desc": "额外多部署 1 座炮台且射程 +40%。"},
				{"id": "awk_totem_field", "name": "脉冲力场塔", "desc": "炮台每次开火附带减速冰环与高额爆炸。"},
			],
		},
	]


func _build_items() -> void:
	items = [
		{"id": "itm_glass_ring", "name": "碎玻璃指环", "tier": 1, "price": 16, "mods": {"damage_pct": 18.0, "max_hp": -6.0}, "sprite": "res://assets/art/sprites/items/itm_glass_ring.png", "desc": "全伤害 +18%，最大生命 -6"},
		{"id": "itm_blood_chalice", "name": "血族圣杯", "tier": 2, "price": 24, "mods": {"life_steal": 6.0, "hp_regen": -1.5}, "sprite": "res://assets/art/sprites/items/itm_blood_chalice.png", "desc": "生命偷取 +6%，自然再生 -1.5"},
		{"id": "itm_frenzy_gear", "name": "狂热齿轮", "tier": 1, "price": 18, "mods": {"attack_speed_pct": 22.0, "armor": -2.0}, "sprite": "res://assets/art/sprites/items/itm_frenzy_gear.png", "desc": "攻击速度 +22%，护甲 -2"},
		{"id": "itm_heavy_plate", "name": "厚重黑铁甲", "tier": 1, "price": 18, "mods": {"armor": 4.0, "max_hp": 10.0, "move_speed": -18.0}, "sprite": "res://assets/art/sprites/items/itm_heavy_plate.png", "desc": "护甲 +4、生命 +10，移速 -18"},
		{"id": "itm_greed_hourglass", "name": "贪婪沙漏", "tier": 2, "price": 22, "mods": {"harvesting": 16.0, "luck": 14.0, "dodge_pct": -5.0}, "sprite": "res://assets/art/sprites/items/itm_greed_hourglass.png", "desc": "收获 +16、幸运 +14，闪避 -5%"},
		{"id": "itm_magnet_core", "name": "磁力核心", "tier": 1, "price": 14, "mods": {"pickup_radius": 85.0, "harvesting": 5.0}, "sprite": "res://assets/art/sprites/items/itm_magnet_core.png", "desc": "吸附范围 +85，收获 +5"},
		{"id": "itm_dash_thruster", "name": "血步推进器", "tier": 2, "price": 24, "mods": {"dash_cd_pct": 22.0, "move_speed": 22.0, "melee_damage": 4.0}, "sprite": "res://assets/art/sprites/items/itm_dash_thruster.png", "desc": "血步冷却 -22%，移速 +22，近战 +4"},
		{"id": "itm_crimson_fang", "name": "猩红利齿", "tier": 1, "price": 17, "mods": {"crit_chance_pct": 9.0, "melee_damage": 5.0, "range_bonus": -15.0}, "sprite": "res://assets/art/sprites/items/itm_crimson_fang.png", "desc": "暴击率 +9%、近战 +5，射程 -15"},
		{"id": "itm_eagle_eye", "name": "鹰眼瞄准镜", "tier": 2, "price": 24, "mods": {"ranged_damage": 7.0, "range_bonus": 65.0, "crit_mult_pct": 25.0, "move_speed": -10.0}, "sprite": "res://assets/art/sprites/items/itm_eagle_eye.png", "desc": "远程 +7、射程 +65、暴伤 +25%，移速 -10"},
		{"id": "itm_arcane_capacitor", "name": "奥术电容", "tier": 2, "price": 25, "mods": {"elemental_damage": 9.0, "attack_speed_pct": 12.0, "max_hp": -5.0}, "sprite": "res://assets/art/sprites/items/itm_arcane_capacitor.png", "desc": "元素/召唤 +9、攻速 +12%，最大生命 -5"},
		{"id": "itm_phantom_cloak", "name": "幻影披风", "tier": 2, "price": 24, "mods": {"dodge_pct": 12.0, "move_speed": 26.0, "armor": -1.0}, "sprite": "res://assets/art/sprites/items/itm_phantom_cloak.png", "desc": "闪避 +12%、移速 +26，护甲 -1"},
		{"id": "itm_vital_heart", "name": "不朽龙心", "tier": 3, "price": 34, "mods": {"max_hp": 22.0, "hp_regen": 3.5}, "sprite": "res://assets/art/sprites/items/itm_vital_heart.png", "desc": "最大生命 +22，生命再生 +3.5/s"},
		{"id": "itm_executioner_seal", "name": "处刑者印玺", "tier": 3, "price": 38, "mods": {"crit_chance_pct": 14.0, "crit_mult_pct": 45.0, "damage_pct": 12.0, "armor": -3.0}, "sprite": "res://assets/art/sprites/items/itm_executioner_seal.png", "desc": "暴击 +14%、暴伤 +45%、伤害 +12%，护甲 -3"},
		{"id": "itm_void_prism", "name": "虚空棱晶", "tier": 3, "price": 36, "mods": {"elemental_damage": 14.0, "range_bonus": 45.0, "luck": 15.0}, "sprite": "res://assets/art/sprites/items/itm_void_prism.png", "desc": "元素/召唤 +14、射程 +45、幸运 +15"},
		{"id": "itm_lucky_dice", "name": "命运双骰", "tier": 2, "price": 22, "mods": {"luck": 30.0, "crit_chance_pct": 5.0}, "sprite": "res://assets/art/sprites/items/itm_lucky_dice.png", "desc": "幸运 +30，暴击 +5%，更易刷出高阶好货"},
		{"id": "itm_blood_battery", "name": "超频血电池", "tier": 3, "price": 36, "mods": {"attack_speed_pct": 30.0, "damage_pct": 15.0, "hp_regen": -2.5}, "sprite": "res://assets/art/sprites/items/itm_blood_battery.png", "desc": "攻速 +30%、全伤害 +15%，再生 -2.5"},
		{"id": "itm_mirror_buckle", "name": "镜像折光扣", "tier": 2, "price": 23, "mods": {"armor": 3.0, "dodge_pct": 8.0, "melee_damage": -2.0}, "sprite": "res://assets/art/sprites/items/itm_mirror_buckle.png", "desc": "护甲 +3、闪避 +8%，近战 -2"},
		{"id": "itm_titans_belt", "name": "泰坦腰带", "tier": 3, "price": 35, "mods": {"max_hp": 18.0, "melee_damage": 10.0, "ranged_damage": 8.0, "dodge_pct": -8.0}, "sprite": "res://assets/art/sprites/items/itm_titans_belt.png", "desc": "生命 +18、近战 +10、远程 +8，闪避 -8%"},
	]


func _build_pacts() -> void:
	pacts = [
		{
			"id": "pact_glass_cannon",
			"name": "玻璃大炮之誓",
			"cost_text": "生命上限永远锁死为 20 点",
			"gain_text": "全伤害 ×1.55 倍、暴击 +20%，过关额外享 +12% 利息",
			"mods": {"crit_chance_pct": 20.0},
		},
		{
			"id": "pact_toxic_blood",
			"name": "毒血炼金契",
			"cost_text": "吸血与生命再生完全失效",
			"gain_text": "每次本应回血时，把 220% 治疗量引爆成周围剧毒伤害",
			"mods": {"life_steal": 10.0, "hp_regen": 3.0},
		},
		{
			"id": "pact_bounty_hunt",
			"name": "猎杀赏金令",
			"cost_text": "精英怪翻倍刷出，敌速 +18%",
			"gain_text": "商店全场 65 折，幸运直加 +45",
			"mods": {"luck": 45.0},
		},
		{
			"id": "pact_crazy_overdrive",
			"name": "疯狂过载契",
			"cost_text": "护甲永久锁定在 -6",
			"gain_text": "每掉 1% 血，全武器攻速狂飙 +2.2%",
			"mods": {},
		},
		{
			"id": "pact_lone_wolf",
			"name": "独狼禁戒",
			"cost_text": "献祭 1 个武器槽位",
			"gain_text": "其余全部武器伤害 ×1.40 倍，射程 +70",
			"mods": {"range_bonus": 70.0},
		},
		{
			"id": "pact_time_rush",
			"name": "时空加速契",
			"cost_text": "怪潮更密（+45%），每波战斗缩短 20%",
			"gain_text": "过关额外享 +15% 存钱利息，收获 +25",
			"mods": {"harvesting": 25.0},
		},
		{
			"id": "pact_burn_boats",
			"name": "破釜沉舟",
			"cost_text": "当场扣除当前一半生命（至少留 1 血）",
			"gain_text": "直接获赠 1 把随机 3 阶紫武与 85 血晶",
			"mods": {},
		},
		{
			"id": "pact_blood_clone",
			"name": "血影双生",
			"cost_text": "移速永久 -35",
			"gain_text": "血步原地留下嘲讽分身吸引火力，2 秒后自爆清场",
			"mods": {"move_speed": -35.0, "dash_cd_pct": 20.0},
		},
		{
			"id": "pact_cursed_harvest",
			"name": "诅咒丰收",
			"cost_text": "后续所有敌人血量 +25%",
			"gain_text": "全场掉落物全屏自动吸附，双倍掉晶率大增",
			"mods": {"pickup_radius": 900.0, "harvesting": 18.0},
		},
		{
			"id": "pact_undying_sacrifice",
			"name": "不灭献祭",
			"cost_text": "全伤暂时 -15%，生命上限 -10%",
			"gain_text": "获得 1 次原地重生保命机会，且每过一波全伤永久 +8%",
			"mods": {"damage_pct": -15.0},
		},
	]


func _build_talents() -> void:
	talents = [
		# 战备分支
		{"id": "tal_start_gold", "branch": "战备", "name": "随身军饷", "max_rank": 5, "base_cost": 35, "cost_step": 25, "desc": "开局多带 {val} 血晶进场", "per_rank": 18.0},
		{"id": "tal_free_reroll", "branch": "战备", "name": "黑市熟客", "max_rank": 3, "base_cost": 55, "cost_step": 45, "desc": "每轮商店前 {val} 次刷新免费", "per_rank": 1.0},
		{"id": "tal_shop_discount", "branch": "战备", "name": "砍价大师", "max_rank": 4, "base_cost": 45, "cost_step": 35, "desc": "商店全品常驻 {val}% 折扣", "per_rank": 5.0},
		{"id": "tal_ban_slots", "branch": "战备", "name": "货架禁选位", "max_rank": 2, "base_cost": 90, "cost_step": 90, "desc": "可在图鉴屏蔽 {val} 件不想要的装备", "per_rank": 1.0},
		# 生存分支
		{"id": "tal_max_hp", "branch": "生存", "name": "血脉锻体", "max_rank": 5, "base_cost": 30, "cost_step": 22, "desc": "初始生命上限 +{val}", "per_rank": 6.0},
		{"id": "tal_revive", "branch": "生存", "name": "不灭余烬", "max_rank": 1, "base_cost": 180, "cost_step": 0, "desc": "每局 1 次濒死原地 50% 血震开敌群复活", "per_rank": 1.0},
		{"id": "tal_iframes", "branch": "生存", "name": "受击护盾", "max_rank": 4, "base_cost": 40, "cost_step": 30, "desc": "受伤后无敌保命时间 +{val}%", "per_rank": 15.0},
		{"id": "tal_magnet", "branch": "生存", "name": "血晶磁石", "max_rank": 4, "base_cost": 30, "cost_step": 25, "desc": "开局掉落物吸附范围 +{val}", "per_rank": 28.0},
		# 贪婪分支
		{"id": "tal_interest", "branch": "贪婪", "name": "血晶钱庄", "max_rank": 4, "base_cost": 50, "cost_step": 40, "desc": "过关保留血晶享 +{val}% 存钱利息", "per_rank": 3.0},
		{"id": "tal_pact_boost", "branch": "贪婪", "name": "嗜契狂徒", "max_rank": 3, "base_cost": 65, "cost_step": 50, "desc": "每签 1 份血契额外加 {val}% 全伤害", "per_rank": 8.0},
		{"id": "tal_ember_gain", "branch": "贪婪", "name": "余烬淬炼", "max_rank": 5, "base_cost": 40, "cost_step": 35, "desc": "每局结算多拿 {val}% 深渊余烬", "per_rank": 12.0},
		{"id": "tal_tier_luck", "branch": "贪婪", "name": "寻宝直觉", "max_rank": 4, "base_cost": 45, "cost_step": 35, "desc": "开局幸运 +{val}", "per_rank": 10.0},
	]


func _build_heats() -> void:
	heats = [
		{"id": "heat_speed", "name": "狂热敌潮", "desc": "敌方移速 +15%", "ember_bonus_pct": 25},
		{"id": "heat_hp", "name": "血肉硬化", "desc": "敌方血量 +22%", "ember_bonus_pct": 25},
		{"id": "heat_density", "name": "虫潮暴走", "desc": "怪潮密度 +20%", "ember_bonus_pct": 25},
		{"id": "heat_elites", "name": "双子裁决", "desc": "精英怪更常现身", "ember_bonus_pct": 25},
		{"id": "heat_inflation", "name": "黑市涨价", "desc": "商店物价 +18%", "ember_bonus_pct": 25},
		{"id": "heat_boss", "name": "魔王觉醒", "desc": "Boss 更肉且弹幕更猛", "ember_bonus_pct": 25},
		{"id": "heat_fragile", "name": "碎甲诅咒", "desc": "开局护甲 -2", "ember_bonus_pct": 25},
		{"id": "heat_bleed", "name": "血月压迫", "desc": "敌方伤害 +20%", "ember_bonus_pct": 25},
	]


func _build_enemies() -> void:
	enemies = {
		"swarmer": {"name": "渊虫幼体", "hp": 20.0, "speed": 158.0, "damage": 6.0, "radius": 18.0, "xp": 3.0, "crystals": 1, "sprite": "res://assets/art/sprites/enemies/enemy_swarmer.png", "ai": "chase"},
		"brute": {"name": "铁甲兽人", "hp": 72.0, "speed": 98.0, "damage": 11.0, "radius": 26.0, "xp": 7.0, "crystals": 3, "sprite": "res://assets/art/sprites/enemies/enemy_brute.png", "ai": "chase"},
		"sprinter": {"name": "血翼刺客", "hp": 28.0, "speed": 135.0, "damage": 9.0, "radius": 19.0, "xp": 5.0, "crystals": 2, "sprite": "res://assets/art/sprites/enemies/enemy_sprinter.png", "ai": "dasher"},
		"spitter": {"name": "腐蚀喷吐者", "hp": 34.0, "speed": 105.0, "damage": 8.0, "radius": 21.0, "xp": 6.0, "crystals": 2, "sprite": "res://assets/art/sprites/enemies/enemy_spitter.png", "ai": "ranged"},
		"splitter": {"name": "裂变畸变体", "hp": 48.0, "speed": 115.0, "damage": 8.0, "radius": 23.0, "xp": 6.0, "crystals": 3, "sprite": "res://assets/art/sprites/enemies/enemy_splitter.png", "ai": "splitter"},
		"bomber": {"name": "自爆魔核", "hp": 30.0, "speed": 148.0, "damage": 16.0, "radius": 21.0, "xp": 5.0, "crystals": 2, "sprite": "res://assets/art/sprites/enemies/enemy_bomber.png", "ai": "bomber"},
		"shielder": {"name": "虚空护盾兵", "hp": 66.0, "speed": 108.0, "damage": 10.0, "radius": 24.0, "xp": 7.0, "crystals": 3, "sprite": "res://assets/art/sprites/enemies/enemy_shielder.png", "ai": "shielder"},
		"elite_warden": {"name": "精英裁决者", "hp": 310.0, "speed": 122.0, "damage": 14.0, "radius": 32.0, "xp": 24.0, "crystals": 14, "sprite": "res://assets/art/sprites/enemies/enemy_elite_warden.png", "ai": "elite"},
		"boss_inquisitor": {"name": "赤潮审判官", "hp": 6200.0, "speed": 126.0, "damage": 18.0, "radius": 52.0, "xp": 60.0, "crystals": 40, "sprite": "res://assets/art/sprites/enemies/boss_inquisitor.png", "ai": "boss_1"},
		"boss_sovereign": {"name": "深渊双生主宰", "hp": 28000.0, "speed": 136.0, "damage": 22.0, "radius": 58.0, "xp": 120.0, "crystals": 75, "sprite": "res://assets/art/sprites/enemies/boss_sovereign.png", "ai": "boss_2"},
	}


func _build_difficulties() -> void:
	difficulties = [
		{
			"level": 0,
			"name": "试炼 (D0)",
			"short_name": "D0 试炼",
			"desc": "标准竞技场规则；适合熟悉流派与武器机制。",
			"enemy_hp_mult": 1.00,
			"enemy_dmg_mult": 1.00,
			"enemy_speed_mult": 1.00,
			"density_mult": 1.00,
			"pack_bonus": 0,
			"elite_bonus": 0,
			"shop_price_mult": 1.00,
			"wave_heal_ratio": 1.00,
			"ember_bonus_pct": 0,
			"color": Color(0.55, 0.85, 0.65),
		},
		{
			"level": 1,
			"name": "血月 (D1)",
			"short_name": "D1 血月",
			"desc": "敌人生命 +25%、伤害 +15%、移速 +6%、密度 +12%；余烬 +25%。",
			"enemy_hp_mult": 1.25,
			"enemy_dmg_mult": 1.15,
			"enemy_speed_mult": 1.06,
			"density_mult": 1.12,
			"pack_bonus": 0,
			"elite_bonus": 0,
			"shop_price_mult": 1.00,
			"wave_heal_ratio": 1.00,
			"ember_bonus_pct": 25,
			"color": Color(0.45, 0.80, 1.00),
		},
		{
			"level": 2,
			"name": "狂潮 (D2)",
			"short_name": "D2 狂潮",
			"desc": "敌人生命 +55%、伤害 +30%、移速 +10%；精英减伤与刷新提升，物价 +10%；余烬 +55%。",
			"enemy_hp_mult": 1.55,
			"enemy_dmg_mult": 1.30,
			"enemy_speed_mult": 1.10,
			"density_mult": 1.25,
			"pack_bonus": 1,
			"elite_bonus": 1,
			"shop_price_mult": 1.10,
			"wave_heal_ratio": 1.00,
			"ember_bonus_pct": 55,
			"color": Color(0.65, 0.55, 1.00),
		},
		{
			"level": 3,
			"name": "蚀骨 (D3)",
			"short_name": "D3 蚀骨",
			"desc": "敌人生命 ×1.95、伤害 ×1.50、密度 +38%；波间自动回血降至 90%，物价 +18%；余烬 +90%。",
			"enemy_hp_mult": 1.95,
			"enemy_dmg_mult": 1.50,
			"enemy_speed_mult": 1.14,
			"density_mult": 1.38,
			"pack_bonus": 1,
			"elite_bonus": 1,
			"shop_price_mult": 1.18,
			"wave_heal_ratio": 0.90,
			"ember_bonus_pct": 90,
			"color": Color(1.00, 0.72, 0.25),
		},
		{
			"level": 4,
			"name": "炼狱 (D4)",
			"short_name": "D4 炼狱",
			"desc": "敌人生命 ×2.45、伤害 ×1.75；Boss 将召唤精英侍卫，波间回血 85%，物价 +25%；余烬 +135%。",
			"enemy_hp_mult": 2.45,
			"enemy_dmg_mult": 1.75,
			"enemy_speed_mult": 1.18,
			"density_mult": 1.50,
			"pack_bonus": 2,
			"elite_bonus": 2,
			"shop_price_mult": 1.25,
			"wave_heal_ratio": 0.85,
			"ember_bonus_pct": 135,
			"color": Color(1.00, 0.42, 0.25),
		},
		{
			"level": 5,
			"name": "深渊终焉 (D5)",
			"short_name": "D5 终焉",
			"desc": "敌人生命 ×3.10、伤害 ×2.05、双倍精英侍卫；波间回血 75%，物价 +30%；余烬 +190%！",
			"enemy_hp_mult": 3.10,
			"enemy_dmg_mult": 2.05,
			"enemy_speed_mult": 1.22,
			"density_mult": 1.65,
			"pack_bonus": 2,
			"elite_bonus": 2,
			"shop_price_mult": 1.30,
			"wave_heal_ratio": 0.75,
			"ember_bonus_pct": 190,
			"color": Color(1.00, 0.22, 0.42),
		},
	]


func _build_shop_sinks() -> void:
	shop_sinks = [
		{
			"id": "sink_temper_power",
			"name": "深渊武器淬炼",
			"base_cost": 48,
			"step_cost": 34,
			"sprite": "res://assets/art/sprites/items/sink_temper_power.png",
			"effect_text": "全伤害 +12%，暴击率 +4%",
			"mods": {"damage_pct": 12.0, "crit_chance_pct": 4.0},
		},
		{
			"id": "sink_temper_vital",
			"name": "鲜血铸体仪式",
			"base_cost": 44,
			"step_cost": 30,
			"sprite": "res://assets/art/sprites/items/sink_temper_vital.png",
			"effect_text": "最大生命 +14，护甲 +2，移速 +8",
			"mods": {"max_hp": 14.0, "armor": 2.0, "move_speed": 8.0},
		},
		{
			"id": "sink_mystery_relic",
			"name": "黑市遗物盲盒",
			"base_cost": 78,
			"step_cost": 46,
			"sprite": "res://assets/art/sprites/items/sink_mystery_relic.png",
			"effect_text": "随机立即获得 1 件未禁用道具",
			"mods": {},
		},
	]


static func get_wave_pool(wave: int) -> Array[String]:
	if wave <= 1:
		return ["swarmer", "swarmer", "swarmer", "brute"]
	if wave == 2:
		return ["swarmer", "swarmer", "brute", "spitter"]
	if wave == 3:
		return ["swarmer", "brute", "spitter", "sprinter"]
	if wave == 4:
		return ["swarmer", "brute", "spitter", "sprinter", "splitter"]
	if wave <= 6:
		return ["swarmer", "brute", "spitter", "sprinter", "splitter", "bomber"]
	return ["swarmer", "brute", "spitter", "sprinter", "splitter", "bomber", "shielder"]
