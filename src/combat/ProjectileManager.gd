class_name ProjectileManager
extends Node2D
## Pooled projectile simulation supporting piercing, ricochet bouncing, homing missiles,
## boomerang scythes, mortar AoE lobbed shells, and enemy bullet patterns.

const MAX_PLAYER_PROJ := 220
const MAX_ENEMY_PROJ := 140

var _p_pool: Array[Dictionary] = []
var _e_pool: Array[Dictionary] = []

var _tex_crimson: Texture2D
var _tex_azure: Texture2D
var _tex_void: Texture2D
var _tex_scythe: Texture2D
var _tex_enemy: Texture2D


func _ready() -> void:
	_tex_crimson = load("res://assets/art/sprites/projectiles/proj_crimson.png")
	_tex_azure = load("res://assets/art/sprites/projectiles/proj_azure.png")
	_tex_void = load("res://assets/art/sprites/projectiles/proj_void.png")
	_tex_scythe = load("res://assets/art/sprites/weapons/wpn_blood_scythe.png")
	_tex_enemy = load("res://assets/art/sprites/projectiles/proj_enemy.png")

	for i in range(MAX_PLAYER_PROJ):
		var sp := Sprite2D.new()
		sp.visible = false
		sp.z_index = 40
		add_child(sp)
		_p_pool.append({"alive": false, "sprite": sp, "hit_ids": {}})

	for i in range(MAX_ENEMY_PROJ):
		var sp := Sprite2D.new()
		sp.texture = _tex_enemy
		sp.visible = false
		sp.z_index = 42
		sp.scale = Vector2(0.45, 0.45)
		add_child(sp)
		_e_pool.append({"alive": false, "sprite": sp})


func spawn_player_projectile(cfg: Dictionary) -> void:
	var slot: Dictionary = {}
	for d in _p_pool:
		if not bool(d["alive"]):
			slot = d
			break
	if slot.is_empty():
		return

	slot["alive"] = true
	slot["pos"] = Vector2(cfg.get("pos", Vector2.ZERO))
	slot["vel"] = Vector2(cfg.get("vel", Vector2.RIGHT * 500.0))
	slot["speed"] = float(cfg.get("speed", 600.0))
	slot["damage"] = float(cfg.get("damage", 10.0))
	slot["is_crit"] = bool(cfg.get("is_crit", false))
	slot["knockback"] = float(cfg.get("knockback", 40.0))
	slot["pierce"] = int(cfg.get("pierce", 1))
	slot["bounces"] = int(cfg.get("bounces", 0))
	slot["homing"] = float(cfg.get("homing", 0.0))
	slot["radius"] = float(cfg.get("radius", 16.0))
	slot["life"] = float(cfg.get("life", 1.2))
	slot["max_life"] = float(cfg.get("life", 1.2))
	slot["kind"] = String(cfg.get("kind", "bullet")) # bullet | boomerang | mortar
	slot["faction"] = String(cfg.get("faction", "crimson"))
	slot["weapon_id"] = String(cfg.get("weapon_id", ""))
	slot["awakening"] = String(cfg.get("awakening", ""))
	slot["target_pos"] = Vector2(cfg.get("target_pos", Vector2.ZERO))
	slot["aoe_radius"] = float(cfg.get("aoe_radius", 110.0))
	slot["chill"] = bool(cfg.get("chill", false))
	slot["spin"] = bool(cfg.get("spin", false))
	(slot["hit_ids"] as Dictionary).clear()

	var sp: Sprite2D = slot["sprite"]
	sp.global_position = Vector2(slot["pos"])
	if String(slot["kind"]) == "boomerang":
		sp.texture = _tex_scythe
		sp.scale = Vector2(0.46, 0.46)
	else:
		match String(slot["faction"]):
			"azure": sp.texture = _tex_azure
			"void": sp.texture = _tex_void
			_: sp.texture = _tex_crimson
		sp.scale = Vector2(0.50, 0.50) if String(slot["kind"]) == "mortar" else Vector2(0.42, 0.42)
	sp.rotation = Vector2(slot["vel"]).angle()
	sp.visible = true


func spawn_enemy_projectile(pos: Vector2, vel: Vector2, damage: float, life: float = 3.0, radius: float = 11.0) -> void:
	for slot in _e_pool:
		if not bool(slot["alive"]):
			slot["alive"] = true
			slot["pos"] = pos
			slot["vel"] = vel
			slot["damage"] = damage
			slot["life"] = life
			slot["radius"] = radius
			var sp: Sprite2D = slot["sprite"]
			sp.global_position = pos
			sp.scale = Vector2.ONE * (radius / 24.0)
			sp.visible = true
			return


func clear_all() -> void:
	for d in _p_pool:
		d["alive"] = false
		(d["sprite"] as Sprite2D).visible = false
	for d in _e_pool:
		d["alive"] = false
		(d["sprite"] as Sprite2D).visible = false


func step(delta: float, player: PlayerController, enemy_mgr: EnemyManager, vfx: VfxManager) -> void:
	# 1. Player projectiles
	for slot in _p_pool:
		if not bool(slot["alive"]):
			continue
		slot["life"] = float(slot["life"]) - delta
		var pos := Vector2(slot["pos"])
		var vel := Vector2(slot["vel"])
		var kind := String(slot["kind"])
		var sp: Sprite2D = slot["sprite"]

		if kind == "mortar":
			var tgt := Vector2(slot["target_pos"])
			var step_vec := (tgt - pos)
			if step_vec.length() <= float(slot["speed"]) * delta or float(slot["life"]) <= 0.0:
				_detonate_mortar(slot, tgt, enemy_mgr, vfx)
				continue
			vel = step_vec.normalized() * float(slot["speed"])
			pos += vel * delta
		elif kind == "boomerang":
			var ratio := float(slot["life"]) / maxf(0.01, float(slot["max_life"]))
			if ratio < 0.5:
				var back_dir := (player.global_position - pos).normalized()
				vel = vel.lerp(back_dir * float(slot["speed"]), minf(1.0, delta * 9.0))
			pos += vel * delta
			sp.rotation += delta * 16.0
		else:
			if float(slot["homing"]) > 0.0:
				var nearest := enemy_mgr.find_nearest_pos(pos, 340.0)
				if nearest.has("found"):
					var desired := (Vector2(nearest["pos"]) - pos).normalized() * float(slot["speed"])
					vel = vel.lerp(desired, minf(1.0, delta * float(slot["homing"])))
			pos += vel * delta
			sp.rotation = vel.angle()

		slot["pos"] = pos
		slot["vel"] = vel
		sp.global_position = pos

		if float(slot["life"]) <= 0.0 or absf(pos.x) > 650.0 or absf(pos.y) > 750.0:
			slot["alive"] = false
			sp.visible = false
			continue

		if kind != "mortar":
			_check_player_proj_hits(slot, enemy_mgr, vfx)

	# 2. Enemy projectiles
	var p_pos := player.global_position
	var p_rad := 16.0
	for slot in _e_pool:
		if not bool(slot["alive"]):
			continue
		slot["life"] = float(slot["life"]) - delta
		var pos := Vector2(slot["pos"]) + Vector2(slot["vel"]) * delta
		slot["pos"] = pos
		var sp: Sprite2D = slot["sprite"]
		sp.global_position = pos
		sp.rotation += delta * 6.0

		if float(slot["life"]) <= 0.0 or absf(pos.x) > 650.0 or absf(pos.y) > 750.0:
			slot["alive"] = false
			sp.visible = false
			continue

		var hit_r := p_rad + float(slot["radius"])
		if pos.distance_squared_to(p_pos) <= hit_r * hit_r:
			player.take_damage(float(slot["damage"]))
			slot["alive"] = false
			sp.visible = false


func _check_player_proj_hits(slot: Dictionary, enemy_mgr: EnemyManager, vfx: VfxManager) -> void:
	var pos := Vector2(slot["pos"])
	var rad := float(slot["radius"])
	var hit_ids: Dictionary = slot["hit_ids"]
	var hits := enemy_mgr.query_radius(pos, rad + 36.0)
	var sp: Sprite2D = slot["sprite"]

	for e in hits:
		var eid := int(e["uid"])
		if hit_ids.has(eid):
			continue
		var er := float(e["radius"])
		if pos.distance_squared_to(Vector2(e["pos"])) > (rad + er) * (rad + er):
			continue

		hit_ids[eid] = true
		var dmg := float(slot["damage"])
		var awk := String(slot["awakening"])
		if awk == "awk_scythe_reap" and float(e["hp"]) < float(e["max_hp"]) * 0.5:
			dmg *= 1.75

		enemy_mgr.apply_hit_to_enemy(
			e,
			dmg,
			bool(slot["is_crit"]),
			Vector2(slot["vel"]).normalized() * float(slot["knockback"]),
			String(slot["faction"]),
			String(slot["weapon_id"]),
			bool(slot["chill"]),
			true
		)

		if awk == "awk_bone_burst" or awk == "awk_grim_nova":
			vfx.spawn_burst(Vector2(e["pos"]), Color(0.76, 0.42, 0.99), 85.0, 0.2)
			enemy_mgr.damage_in_radius(Vector2(e["pos"]), 85.0, dmg * 0.55, false, false, false, false, String(slot["weapon_id"]))
		elif awk == "awk_ion_pulse":
			vfx.spawn_burst(Vector2(e["pos"]), Color(0.25, 0.78, 0.99), 75.0, 0.18)
			enemy_mgr.damage_in_radius(Vector2(e["pos"]), 75.0, dmg * 0.45, false, true, false, false, String(slot["weapon_id"]))
		elif awk == "awk_ice_shatter" and float(e["chill_timer"]) > 0.0:
			vfx.spawn_burst(Vector2(e["pos"]), Color(0.55, 0.92, 1.0), 80.0, 0.18)
			enemy_mgr.damage_in_radius(Vector2(e["pos"]), 80.0, dmg * 0.50, false, true, false, false, String(slot["weapon_id"]))

		if int(slot["bounces"]) > 0:
			slot["bounces"] = int(slot["bounces"]) - 1
			if awk == "awk_ion_storm":
				slot["damage"] = float(slot["damage"]) * 1.18
			var next := enemy_mgr.find_nearest_pos(pos, 320.0, hit_ids)
			if next.has("found"):
				slot["vel"] = (Vector2(next["pos"]) - pos).normalized() * float(slot["speed"])
				return

		slot["pierce"] = int(slot["pierce"]) - 1
		if int(slot["pierce"]) <= 0:
			slot["alive"] = false
			sp.visible = false
			return


func _detonate_mortar(slot: Dictionary, center: Vector2, enemy_mgr: EnemyManager, vfx: VfxManager) -> void:
	slot["alive"] = false
	(slot["sprite"] as Sprite2D).visible = false
	var aoe := float(slot["aoe_radius"])
	var dmg := float(slot["damage"])
	var awk := String(slot["awakening"])
	vfx.spawn_burst(center, Color(0.75, 0.35, 0.98), aoe, 0.30)
	EventBus.sfx_requested.emit("sfx_mortar_boom", 0.1)
	EventBus.screen_shake_requested.emit(0.18)
	enemy_mgr.damage_in_radius(center, aoe, dmg, bool(slot["is_crit"]), false, true, false, String(slot["weapon_id"]))
	if awk == "awk_mortar_hole":
		vfx.spawn_singularity(center, aoe * 1.25, 1.4)
