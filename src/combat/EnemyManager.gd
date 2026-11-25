class_name EnemyManager
extends Node2D
## Spatial-hash-accelerated enemy pool, status simulation, synergy procs,
## 8 distinct enemy behaviors, and Wave 5 / Wave 10 mechanism Bosses.

const MAX_ENEMIES := 190
const CELL_SIZE := 96.0

var _pool: Array[Dictionary] = []
var _grid: Dictionary = {}
var _uid_counter: int = 1
var _tex_cache: Dictionary = {}
var _flash_shader: Shader

var _run: RunState
var _player: PlayerController
var _proj_mgr: ProjectileManager
var _pickup_mgr: PickupManager
var _vfx: VfxManager
var _active_boss: Dictionary = {}


func _ready() -> void:
	_flash_shader = load("res://assets/shaders/hit_flash.gdshader")
	for i in range(MAX_ENEMIES):
		var root := Node2D.new()
		root.visible = false
		root.z_index = 28

		var shadow := Sprite2D.new()
		shadow.texture = load("res://assets/art/sprites/projectiles/glow_soft.png")
		shadow.position = Vector2(0.0, 22.0)
		shadow.scale = Vector2(0.45, 0.18)
		shadow.modulate = Color(0.0, 0.0, 0.0, 0.52)
		root.add_child(shadow)

		var aura := Sprite2D.new()
		aura.texture = load("res://assets/art/sprites/arena/altar_sigil.png")
		aura.scale = Vector2(0.42, 0.42)
		aura.modulate = Color(0.96, 0.25, 0.37, 0.55)
		aura.visible = false
		root.add_child(aura)

		var sp := Sprite2D.new()
		var mat := ShaderMaterial.new()
		mat.shader = _flash_shader
		sp.material = mat
		root.add_child(sp)

		var hp_bg := ColorRect.new()
		hp_bg.size = Vector2(44, 5)
		hp_bg.position = Vector2(-22, -46)
		hp_bg.color = Color(0.08, 0.06, 0.12, 0.85)
		hp_bg.visible = false
		root.add_child(hp_bg)

		var hp_fill := ColorRect.new()
		hp_fill.size = Vector2(44, 5)
		hp_fill.position = Vector2(-22, -46)
		hp_fill.color = Color(0.96, 0.25, 0.37, 0.95)
		hp_fill.visible = false
		root.add_child(hp_fill)

		add_child(root)
		_pool.append({
			"alive": false,
			"uid": 0,
			"node": root,
			"shadow": shadow,
			"aura": aura,
			"sprite": sp,
			"mat": mat,
			"hp_bg": hp_bg,
			"hp_fill": hp_fill,
		})


func setup(run: RunState, player: PlayerController, proj_mgr: ProjectileManager, pickup_mgr: PickupManager, vfx: VfxManager) -> void:
	_run = run
	_player = player
	_proj_mgr = proj_mgr
	_pickup_mgr = pickup_mgr
	_vfx = vfx


func _get_tex(path: String) -> Texture2D:
	if not _tex_cache.has(path):
		_tex_cache[path] = load(path)
	return _tex_cache[path]


func spawn_enemy(enemy_id: String, world_pos: Vector2, wave: int, is_mini: bool = false) -> Dictionary:
	var slot: Dictionary = {}
	for d in _pool:
		if not bool(d["alive"]):
			slot = d
			break
	if slot.is_empty():
		return {}

	var edef := GameData.get_enemy(enemy_id)
	if edef.is_empty():
		return {}

	var is_boss := enemy_id.begins_with("boss_")
	var wave_scale := CombatFormulas.calc_enemy_wave_scale(wave)

	var danger_lvl := _run.danger_level if _run != null else 0
	var diff := GameData.get_difficulty(danger_lvl)
	var hp_mult := float(diff.get("enemy_hp_mult", 1.0))
	var spd_mult := float(diff.get("enemy_speed_mult", 1.0)) * (1.0 + minf(0.28, float(maxi(0, wave - 1)) * 0.025))
	var dmg_mult := float(diff.get("enemy_dmg_mult", 1.0))
	if _run != null:
		if _run.active_heats.has("heat_hp"):
			hp_mult *= 1.22
		if _run.active_heats.has("heat_speed"):
			spd_mult *= 1.15
		if _run.active_heats.has("heat_bleed"):
			dmg_mult *= 1.20
		if _run.active_heats.has("heat_boss") and is_boss:
			hp_mult *= 1.35
		if _run.pacts.has("pact_bounty_hunt"):
			spd_mult *= 1.18
		if _run.pacts.has("pact_cursed_harvest"):
			hp_mult *= 1.25

	var max_hp := float(edef["hp"]) * wave_scale * hp_mult * (0.42 if is_mini else 1.0)
	if is_boss:
		max_hp = float(edef["hp"]) * CombatFormulas.calc_boss_wave_scale(wave, enemy_id) * hp_mult

	_uid_counter += 1
	slot["alive"] = true
	slot["uid"] = _uid_counter
	slot["id"] = enemy_id
	slot["ai"] = String(edef.get("ai", "chase"))
	slot["pos"] = world_pos
	slot["vel"] = Vector2.ZERO
	slot["hp"] = max_hp
	slot["max_hp"] = max_hp
	slot["speed"] = float(edef["speed"]) * spd_mult * (1.28 if is_mini else 1.0)
	slot["damage"] = float(edef["damage"]) * (1.0 + float(wave - 1) * 0.11) * dmg_mult * (0.65 if is_mini else 1.0)
	slot["radius"] = float(edef["radius"]) * (0.68 if is_mini else 1.0)
	slot["xp"] = float(edef["xp"]) * (0.45 if is_mini else 1.0)
	var base_crystals := int(edef["crystals"])
	if enemy_id == "swarmer" and wave >= 4:
		base_crystals = 1
	slot["crystals"] = maxi(1, int(roundf(float(base_crystals) * (0.5 if is_mini else 1.0))))
	slot["is_boss"] = is_boss
	slot["is_elite"] = enemy_id == "elite_warden"
	slot["is_mini"] = is_mini
	slot["resilience"] = CombatFormulas.calc_enemy_armor_resilience(danger_lvl, is_boss, enemy_id == "elite_warden")
	slot["spawn_shield_timer"] = 1.2 if is_boss else 0.0
	slot["facing"] = Vector2.LEFT

	# Status & AI timers
	slot["armor_break_timer"] = 0.0
	slot["bleed_timer"] = 0.0
	slot["bleed_dps"] = 0.0
	slot["bleed_tick"] = 0.0
	slot["chill_timer"] = 0.0
	slot["curse_timer"] = 0.0
	slot["flash_timer"] = 0.0
	slot["hit_squash"] = 0.0
	slot["anim_phase"] = randf() * TAU
	slot["ai_timer"] = randf_range(0.4, 1.4)
	slot["ai_state"] = 0
	slot["dash_dir"] = Vector2.ZERO
	slot["boss_phase_idx"] = 0

	var root: Node2D = slot["node"]
	root.global_position = world_pos
	root.visible = true
	root.z_index = 34 if is_boss else (31 if bool(slot["is_elite"]) else 28)

	var sp: Sprite2D = slot["sprite"]
	sp.texture = _get_tex(String(edef["sprite"]))
	sp.position = Vector2.ZERO
	sp.rotation = 0.0
	var visual_scale := 0.42
	if is_boss:
		visual_scale = 0.72
	elif bool(slot["is_elite"]):
		visual_scale = 0.54
	elif enemy_id == "brute" or enemy_id == "shielder":
		visual_scale = 0.48
	elif is_mini:
		visual_scale = 0.30
	slot["base_scale"] = visual_scale
	sp.scale = Vector2.ONE * visual_scale

	var shadow: Sprite2D = slot["shadow"]
	shadow.position = Vector2(0.0, 56.0 if is_boss else 24.0)
	shadow.scale = Vector2(1.05, 0.38) if is_boss else Vector2(0.45, 0.18)

	var aura: Sprite2D = slot["aura"]
	aura.visible = is_boss or bool(slot["is_elite"])
	aura.scale = Vector2(0.48, 0.48) if is_boss else Vector2(0.22, 0.22)
	aura.modulate = Color(0.75, 0.35, 0.98, 0.55) if enemy_id == "boss_sovereign" else (Color(0.96, 0.25, 0.37, 0.55) if is_boss else Color(0.98, 0.80, 0.12, 0.48))

	var mat: ShaderMaterial = slot["mat"]
	mat.set_shader_parameter("flash_amount", 0.0)
	mat.set_shader_parameter("armor_break_amount", 0.0)

	var show_bar := bool(slot["is_elite"]) or enemy_id == "shielder"
	(slot["hp_bg"] as ColorRect).visible = show_bar
	(slot["hp_fill"] as ColorRect).visible = show_bar
	(slot["hp_fill"] as ColorRect).size.x = 44.0

	if is_boss:
		_active_boss = slot
		EventBus.boss_spawned.emit(String(edef["name"]), max_hp)

	return slot


func clear_all() -> void:
	_active_boss = {}
	_grid.clear()
	for d in _pool:
		d["alive"] = false
		(d["node"] as Node2D).visible = false


func get_alive_count() -> int:
	var c := 0
	for d in _pool:
		if bool(d["alive"]):
			c += 1
	return c


func has_active_boss() -> bool:
	return not _active_boss.is_empty() and bool(_active_boss.get("alive", false))


func step(delta: float) -> void:
	_rebuild_grid()
	var p_pos := _player.global_position

	for e in _pool:
		if not bool(e["alive"]):
			continue

		# Timers & status ticks
		if float(e["flash_timer"]) > 0.0:
			e["flash_timer"] = maxf(0.0, float(e["flash_timer"]) - delta)
			(e["mat"] as ShaderMaterial).set_shader_parameter("flash_amount", float(e["flash_timer"]) / 0.11)
		if float(e.get("spawn_shield_timer", 0.0)) > 0.0:
			e["spawn_shield_timer"] = maxf(0.0, float(e["spawn_shield_timer"]) - delta)

		if float(e["armor_break_timer"]) > 0.0:
			e["armor_break_timer"] = maxf(0.0, float(e["armor_break_timer"]) - delta)
			(e["mat"] as ShaderMaterial).set_shader_parameter("armor_break_amount", 1.0 if float(e["armor_break_timer"]) > 0.0 else 0.0)

		if float(e["chill_timer"]) > 0.0:
			e["chill_timer"] = maxf(0.0, float(e["chill_timer"]) - delta)
		if float(e["curse_timer"]) > 0.0:
			e["curse_timer"] = maxf(0.0, float(e["curse_timer"]) - delta)

		if float(e["bleed_timer"]) > 0.0:
			e["bleed_timer"] = float(e["bleed_timer"]) - delta
			e["bleed_tick"] = float(e["bleed_tick"]) + delta
			if float(e["bleed_tick"]) >= 0.5:
				e["bleed_tick"] = 0.0
				apply_hit_to_enemy(e, float(e["bleed_dps"]) * 0.5, false, Vector2.ZERO, "crimson", "", false, false)
				if not bool(e["alive"]):
					continue

		_step_ai(e, delta, p_pos)
		if not bool(e["alive"]):
			continue

		# Soft separation against nearby enemies
		var pos := Vector2(e["pos"])
		var sep := _compute_separation(e, pos)
		pos += sep * delta
		pos.x = clampf(pos.x, -585.0, 585.0)
		pos.y = clampf(pos.y, -685.0, 685.0)
		e["pos"] = pos

		var root: Node2D = e["node"]
		root.global_position = pos
		var sp: Sprite2D = e["sprite"]
		sp.flip_h = Vector2(e["facing"]).x < -0.05

		# Procedural gait / hover / hit-squash animation
		e["anim_phase"] = float(e["anim_phase"]) + delta * (4.0 if bool(e["is_boss"]) else 9.5)
		e["hit_squash"] = maxf(0.0, float(e["hit_squash"]) - delta * 7.5)
		var bs := float(e.get("base_scale", 0.42))
		var sq := float(e["hit_squash"])
		var ph := float(e["anim_phase"])
		if bool(e["is_boss"]):
			var hover := sin(ph) * 6.0
			sp.position = Vector2(0.0, hover)
			sp.rotation = sin(ph * 0.5) * 0.04
			(e["aura"] as Sprite2D).rotation += delta * 1.4
		else:
			var hop := absf(sin(ph))
			sp.position = Vector2(0.0, -hop * 5.0)
			sp.rotation = sin(ph) * 0.08
			if (e["aura"] as Sprite2D).visible:
				(e["aura"] as Sprite2D).rotation += delta * 1.8
		sp.scale = Vector2(bs * (1.0 + sq * 0.24), bs * (1.0 - sq * 0.20))

		# Contact damage with player
		var hit_r := float(e["radius"]) + 18.0
		if pos.distance_squared_to(p_pos) <= hit_r * hit_r:
			_player.take_damage(float(e["damage"]))


func _step_ai(e: Dictionary, delta: float, p_pos: Vector2) -> void:
	var pos := Vector2(e["pos"])
	var to_p := p_pos - pos
	var dist := to_p.length()
	var dir := to_p / maxf(0.001, dist)
	e["facing"] = dir

	var chill_mult := 0.72 if float(e["chill_timer"]) > 0.0 else 1.0
	var spd := float(e["speed"]) * chill_mult
	var ai := String(e["ai"])

	match ai:
		"dasher":
			e["ai_timer"] = float(e["ai_timer"]) - delta
			if int(e["ai_state"]) == 0:
				pos += dir * spd * delta
				if dist < 270.0 and float(e["ai_timer"]) <= 0.0:
					e["ai_state"] = 1
					e["ai_timer"] = 0.42
					e["dash_dir"] = dir
					_vfx.spawn_telegraph_line(pos, pos + dir * 270.0, 14.0, 0.42, Color(1.0, 0.3, 0.45), Callable())
			elif int(e["ai_state"]) == 1:
				if float(e["ai_timer"]) <= 0.0:
					e["ai_state"] = 2
					e["ai_timer"] = 0.28
			else:
				pos += Vector2(e["dash_dir"]) * (spd * 3.6) * delta
				if float(e["ai_timer"]) <= 0.0:
					e["ai_state"] = 0
					e["ai_timer"] = 2.0
		"ranged":
			if dist > 300.0:
				pos += dir * spd * delta
			elif dist < 210.0:
				pos -= dir * spd * 0.7 * delta
			e["ai_timer"] = float(e["ai_timer"]) - delta
			if float(e["ai_timer"]) <= 0.0:
				e["ai_timer"] = 2.25
				_proj_mgr.spawn_enemy_projectile(pos, dir * 320.0, float(e["damage"]), 2.8, 11.0)
		"bomber":
			if int(e["ai_state"]) == 0:
				pos += dir * spd * delta
				if dist < 95.0:
					e["ai_state"] = 1
					e["ai_timer"] = 0.58
					var uid := int(e["uid"])
					_vfx.spawn_telegraph_circle(pos, 115.0, 0.58, Color(0.98, 0.45, 0.12, 0.3), Color(1.0, 0.65, 0.2, 0.9), func(): _detonate_bomber_by_uid(uid))
			else:
				# Waiting for fuse
				pass
		"elite":
			pos += dir * spd * delta
			e["ai_timer"] = float(e["ai_timer"]) - delta
			if float(e["ai_timer"]) <= 0.0:
				e["ai_timer"] = 2.6
				for k in range(6):
					var ang := dir.angle() + float(k) * (TAU / 6.0)
					_proj_mgr.spawn_enemy_projectile(pos, Vector2.from_angle(ang) * 290.0, float(e["damage"]) * 0.85, 3.0, 12.0)
		"boss_1":
			_step_boss_1(e, delta, pos, dir, spd)
			return
		"boss_2":
			_step_boss_2(e, delta, pos, dir, spd)
			return
		_:
			pos += dir * spd * delta

	var vel := Vector2(e["vel"])
	pos += vel * delta
	e["vel"] = vel.lerp(Vector2.ZERO, minf(1.0, delta * 10.0))
	e["pos"] = pos


func _step_boss_1(e: Dictionary, delta: float, pos: Vector2, dir: Vector2, spd: float) -> void:
	pos += dir * spd * delta + Vector2(e["vel"]) * delta
	e["vel"] = Vector2(e["vel"]).lerp(Vector2.ZERO, minf(1.0, delta * 9.0))
	e["pos"] = pos

	var hp_ratio := float(e["hp"]) / maxf(1.0, float(e["max_hp"]))
	var cadence := 2.4 if hp_ratio < 0.5 else 3.1
	e["ai_timer"] = float(e["ai_timer"]) - delta
	if float(e["ai_timer"]) > 0.0:
		return
	e["ai_timer"] = cadence
	var p_idx := int(e["boss_phase_idx"]) % 3
	e["boss_phase_idx"] = p_idx + 1
	var uid := int(e["uid"])

	if p_idx == 0:
		# Expanding Blood Nova
		_vfx.spawn_telegraph_circle(pos, 220.0, 0.85, Color(0.96, 0.16, 0.34, 0.3), Color(1.0, 0.45, 0.55, 0.95), func():
			var b := _find_by_uid(uid)
			if b.is_empty():
				return
			var bp := Vector2(b["pos"])
			_vfx.spawn_burst(bp, Color(0.98, 0.2, 0.38), 220.0, 0.3)
			EventBus.sfx_requested.emit("sfx_mortar_boom", 0.05)
			EventBus.screen_shake_requested.emit(0.28)
			if _player.global_position.distance_to(bp) <= 220.0:
				_player.take_damage(float(b["damage"]) * 1.25)
		)
	elif p_idx == 1:
		# 4-way cross laser warning -> sweep
		var base_ang := randf() * PI * 0.25
		for k in range(4):
			var ang := base_ang + float(k) * (PI * 0.5)
			var end_p := pos + Vector2.from_angle(ang) * 760.0
			_vfx.spawn_telegraph_line(pos, end_p, 22.0, 0.90, Color(1.0, 0.22, 0.42), func():
				var b := _find_by_uid(uid)
				if b.is_empty():
					return
				var bp := Vector2(b["pos"])
				var target_end := bp + Vector2.from_angle(ang) * 760.0
				_vfx.spawn_beam(bp, target_end, 26.0, Color(1.0, 0.28, 0.45), 0.24)
				EventBus.sfx_requested.emit("sfx_laser_zap", 0.04)
				if _dist_to_segment(_player.global_position, bp, target_end) <= 24.0:
					_player.take_damage(float(b["damage"]) * 1.15)
			)
	else:
		# Radial orbs + summon 2 sprinters
		var count := 12 if _run.active_heats.has("heat_boss") else 9
		for k in range(count):
			var ang := dir.angle() + float(k) * (TAU / float(count))
			_proj_mgr.spawn_enemy_projectile(pos, Vector2.from_angle(ang) * 310.0, float(e["damage"]) * 0.9, 3.2, 13.0)
		for _s in range(2):
			spawn_enemy("sprinter", pos + Vector2(randf_range(-90, 90), randf_range(-90, 90)), _run.wave, true)


func _step_boss_2(e: Dictionary, delta: float, pos: Vector2, dir: Vector2, spd: float) -> void:
	if int(e["ai_state"]) == 2:
		# Dashing charge
		pos += Vector2(e["dash_dir"]) * (spd * 4.2) * delta
		e["pos"] = pos
		e["ai_timer"] = float(e["ai_timer"]) - delta
		if float(e["ai_timer"]) <= 0.0:
			e["ai_state"] = 0
			e["ai_timer"] = 2.0
		return

	pos += dir * spd * delta + Vector2(e["vel"]) * delta
	e["vel"] = Vector2(e["vel"]).lerp(Vector2.ZERO, minf(1.0, delta * 9.0))
	e["pos"] = pos

	var hp_ratio := float(e["hp"]) / maxf(1.0, float(e["max_hp"]))
	var cadence := 2.0 if hp_ratio < 0.55 else 2.6
	e["ai_timer"] = float(e["ai_timer"]) - delta
	if float(e["ai_timer"]) > 0.0:
		return
	e["ai_timer"] = cadence
	var p_idx := int(e["boss_phase_idx"]) % 3
	e["boss_phase_idx"] = p_idx + 1
	var uid := int(e["uid"])

	if p_idx == 0:
		# Spiral blossom orbs
		var count := 14 if _run.active_heats.has("heat_boss") else 10
		var offset := float(e["boss_phase_idx"]) * 0.35
		for k in range(count):
			var ang := offset + float(k) * (TAU / float(count))
			_proj_mgr.spawn_enemy_projectile(pos, Vector2.from_angle(ang) * 330.0, float(e["damage"]) * 0.85, 3.5, 13.0)
	elif p_idx == 1:
		# Telegraphed dash slam
		var dash_d := dir
		e["dash_dir"] = dash_d
		_vfx.spawn_telegraph_line(pos, pos + dash_d * 480.0, 68.0, 0.72, Color(0.95, 0.25, 0.85), func():
			var b := _find_by_uid(uid)
			if b.is_empty():
				return
			b["ai_state"] = 2
			b["ai_timer"] = 0.34
			EventBus.sfx_requested.emit("sfx_dash", 0.05)
		)
	else:
		# 3 Void Rift Meteors around player
		for _m in range(3):
			var drop_p := _player.global_position + Vector2(randf_range(-135.0, 135.0), randf_range(-135.0, 135.0))
			drop_p.x = clampf(drop_p.x, -520.0, 520.0)
			drop_p.y = clampf(drop_p.y, -620.0, 620.0)
			_vfx.spawn_telegraph_circle(drop_p, 115.0, 0.95, Color(0.58, 0.22, 0.96, 0.35), Color(0.82, 0.52, 1.0, 0.95), func():
				_vfx.spawn_burst(drop_p, Color(0.75, 0.35, 0.98), 115.0, 0.28)
				EventBus.sfx_requested.emit("sfx_mortar_boom", 0.08)
				EventBus.screen_shake_requested.emit(0.24)
				if _player.global_position.distance_to(drop_p) <= 115.0:
					_player.take_damage(float(e["damage"]) * 1.15)
			)


func _detonate_bomber_by_uid(uid: int) -> void:
	var e := _find_by_uid(uid)
	if e.is_empty():
		return
	var pos := Vector2(e["pos"])
	var dmg := float(e["damage"])
	_vfx.spawn_burst(pos, Color(0.98, 0.45, 0.12), 115.0, 0.28)
	EventBus.sfx_requested.emit("sfx_mortar_boom", 0.1)
	if _player.global_position.distance_to(pos) <= 115.0:
		_player.take_damage(dmg)
	_kill_enemy(e, "", false)


func apply_armor_break(e: Dictionary, duration: float = 3.5) -> void:
	e["armor_break_timer"] = maxf(float(e["armor_break_timer"]), duration)


func apply_hit_to_enemy(
	e: Dictionary,
	raw_dmg: float,
	is_crit: bool,
	knockback_vec: Vector2,
	faction: String,
	weapon_id: String,
	chill: bool,
	allow_procs: bool
) -> void:
	if not bool(e["alive"]):
		return

	var flags: Dictionary = _run.synergy_info.get("flags", {}) if _run != null else {}
	var shield_factor := 1.0
	if String(e["id"]) == "shielder" and float(e["armor_break_timer"]) <= 0.0 and knockback_vec.length_squared() > 0.01:
		# Frontal block against projectiles/attacks facing shield
		var attack_from := (_player.global_position - Vector2(e["pos"])).normalized()
		if attack_from.dot(Vector2(e["facing"])) > 0.35:
			shield_factor = 0.45

	var vuln := 1.0
	if float(e["curse_timer"]) > 0.0:
		vuln += maxf(0.12, float(flags.get("curse_vuln", 0.12)))

	var res := float(e.get("resilience", 0.0))
	var final_dmg := CombatFormulas.calc_enemy_damage_after_vuln(raw_dmg, vuln, float(e["armor_break_timer"]) > 0.0, shield_factor, res)
	if float(e.get("spawn_shield_timer", 0.0)) > 0.0:
		final_dmg *= 0.45

	e["hp"] = float(e["hp"]) - final_dmg
	e["flash_timer"] = 0.11
	e["hit_squash"] = 1.0

	var kb_resist := 0.08 if bool(e["is_boss"]) else (0.35 if bool(e["is_elite"]) or String(e["id"]) == "brute" else 0.90)
	e["vel"] = Vector2(e["vel"]) + knockback_vec * kb_resist

	if chill or bool(flags.get("chill_on_hit", false)):
		e["chill_timer"] = maxf(float(e["chill_timer"]), 2.2)

	if faction == "void" or float(flags.get("curse_vuln", 0.0)) > 0.0:
		e["curse_timer"] = maxf(float(e["curse_timer"]), 3.5)

	# Bleed from Crimson 4 synergy or explicit bleed
	var bleed_p := float(flags.get("bleed_chance", 0.0))
	if allow_procs and faction == "crimson" and bleed_p > 0.0 and randf() < bleed_p:
		e["bleed_timer"] = 3.0
		e["bleed_dps"] = maxf(float(e["bleed_dps"]), final_dmg * 0.45)

	# Floating combat text
	var col := Color(1.0, 0.85, 0.22) if is_crit else (Color(0.98, 0.35, 0.48) if float(e["armor_break_timer"]) > 0.0 else Color(0.95, 0.95, 0.98))
	var sc := 1.28 if is_crit else 0.95
	EventBus.floating_text_requested.emit(Vector2(e["pos"]), str(int(roundf(final_dmg))), col, sc)

	if is_crit:
		EventBus.sfx_requested.emit("sfx_crit_hit", 0.12)
	elif allow_procs:
		EventBus.sfx_requested.emit("sfx_hit_enemy", 0.15)

	if bool(e["is_boss"]):
		EventBus.boss_hp_changed.emit(maxf(0.0, float(e["hp"])), float(e["max_hp"]))
	elif (e["hp_fill"] as ColorRect).visible:
		(e["hp_fill"] as ColorRect).size.x = 44.0 * clampf(float(e["hp"]) / maxf(1.0, float(e["max_hp"])), 0.0, 1.0)

	# Life steal chance on hit
	if allow_procs and _player != null:
		var ls := _run.stats.get_stat("life_steal")
		if ls > 0.0 and randf() * 100.0 < ls:
			_player.heal_or_convert(1.0)

	# Resonance: Blood Lightning (Crimson 2 + Azure 2)
	if allow_procs and is_crit and bool(flags.get("res_blood_lightning", false)):
		_trigger_blood_lightning(Vector2(e["pos"]), int(e["uid"]), 22.0 + _run.stats.get_stat("elemental_damage") * 0.6)

	# Resonance: Void Storm (Azure 2 + Void 2)
	if allow_procs and faction == "azure" and bool(flags.get("res_void_storm", false)) and randf() < 0.22:
		_vfx.spawn_singularity(Vector2(e["pos"]), 125.0, 1.4)

	# Void 6 Execute (<18% HP non-boss)
	var exec_pct := float(flags.get("void_execute_pct", 0.0))
	if exec_pct > 0.0 and not bool(e["is_boss"]) and float(e["hp"]) > 0.0 and float(e["hp"]) <= float(e["max_hp"]) * exec_pct:
		e["hp"] = 0.0
		EventBus.floating_text_requested.emit(Vector2(e["pos"]), "处决!", Color(0.82, 0.45, 1.0), 1.2)
		_pickup_mgr.spawn_pickup(Vector2(e["pos"]), "crystal", 1, 1.5)

	if float(e["hp"]) <= 0.0:
		_kill_enemy(e, weapon_id, true)


func _trigger_blood_lightning(origin: Vector2, exclude_uid: int, dmg: float) -> void:
	var pts := PackedVector2Array([origin])
	var hits := query_radius(origin, 230.0)
	var bounced := 0
	for target in hits:
		if int(target["uid"]) == exclude_uid:
			continue
		pts.append(Vector2(target["pos"]))
		apply_hit_to_enemy(target, dmg, false, Vector2.ZERO, "azure", "", false, false)
		_player.heal_or_convert(1.0)
		bounced += 1
		if bounced >= 2:
			break
	if pts.size() >= 2:
		_vfx.spawn_lightning_chain(pts, Color(1.0, 0.35, 0.65))


func _kill_enemy(e: Dictionary, weapon_id: String, drop_loot: bool) -> void:
	if not bool(e["alive"]):
		return
	e["alive"] = false
	(e["node"] as Node2D).visible = false
	var pos := Vector2(e["pos"])

	_vfx.spawn_burst(pos, Color(0.95, 0.25, 0.45), float(e["radius"]) * 1.9, 0.22)
	EventBus.sfx_requested.emit("sfx_enemy_die", 0.14)

	if _run != null:
		_run.total_kills += 1
		_run.wave_kills += 1
		if not weapon_id.is_empty():
			_run.weapon_kills_this_run[weapon_id] = int(_run.weapon_kills_this_run.get(weapon_id, 0)) + 1
		if bool(e["is_elite"]):
			_run.elites_killed += 1
		if bool(e["is_boss"]):
			_run.bosses_killed += 1
			_active_boss = {}
			EventBus.hit_stop_requested.emit(0.06)
			EventBus.screen_shake_requested.emit(0.45)
			EventBus.boss_defeated.emit(String(e["id"]))

	if drop_loot and _pickup_mgr != null:
		if bool(e["is_elite"]) or bool(e["is_boss"]):
			_pickup_mgr.spawn_pickup(pos, "chest", int(e["crystals"]), float(e["xp"]))
		else:
			var bonus_crystal := 1 if (_run != null and _run.pacts.has("pact_cursed_harvest") and randf() < 0.45) else 0
			_pickup_mgr.spawn_pickup(pos, "crystal", int(e["crystals"]) + bonus_crystal, float(e["xp"]))
			if randf() < 0.055:
				_pickup_mgr.spawn_pickup(pos, "heal", 6, 0.0)

	# Splitter spawns 2 minis
	if String(e["ai"]) == "splitter" and not bool(e["is_mini"]) and _run != null:
		spawn_enemy("splitter", pos + Vector2(-24, 0), _run.wave, true)
		spawn_enemy("splitter", pos + Vector2(24, 0), _run.wave, true)

	# Synergy procs on death
	if _run != null:
		var flags: Dictionary = _run.synergy_info.get("flags", {})
		if bool(flags.get("void_burst_on_kill", false)):
			_vfx.spawn_burst(pos, Color(0.72, 0.38, 0.98), 85.0, 0.2)
			damage_in_radius(pos, 85.0, 14.0 + _run.stats.get_stat("elemental_damage") * 0.7, false, false, false, false)
		if bool(flags.get("res_soul_curse", false)) and (float(e["bleed_timer"]) > 0.0 or float(e["curse_timer"]) > 0.0):
			_vfx.spawn_burst(pos, Color(0.98, 0.22, 0.44), 105.0, 0.22)
			damage_in_radius(pos, 105.0, 22.0 + _run.stats.get_stat("elemental_damage") * 0.9, false, false, false, false)


func damage_in_radius(
	center: Vector2,
	radius_px: float,
	dmg: float,
	is_crit: bool,
	chill: bool,
	armor_break: bool,
	allow_procs: bool = false,
	weapon_id: String = ""
) -> int:
	var hits := query_radius(center, radius_px + 34.0)
	var count := 0
	for e in hits:
		var r := radius_px + float(e["radius"])
		if center.distance_squared_to(Vector2(e["pos"])) <= r * r:
			if armor_break:
				apply_armor_break(e, 3.0)
			var dir := (Vector2(e["pos"]) - center).normalized()
			apply_hit_to_enemy(e, dmg, is_crit, dir * 80.0, "void", weapon_id, chill, allow_procs)
			count += 1
	return count


func pull_enemies_toward(center: Vector2, radius_px: float, pull_step: float) -> void:
	var hits := query_radius(center, radius_px)
	var r_sq := radius_px * radius_px
	for e in hits:
		if bool(e["is_boss"]):
			continue
		var pos := Vector2(e["pos"])
		var diff := center - pos
		var d_sq := diff.length_squared()
		if d_sq > 16.0 and d_sq <= r_sq:
			e["pos"] = pos + diff.normalized() * minf(pull_step, sqrt(d_sq) * 0.5)


func _rebuild_grid() -> void:
	_grid.clear()
	for e in _pool:
		if not bool(e["alive"]):
			continue
		var p := Vector2(e["pos"])
		var key := Vector2i(int(floorf(p.x / CELL_SIZE)), int(floorf(p.y / CELL_SIZE)))
		if not _grid.has(key):
			_grid[key] = []
		(_grid[key] as Array).append(e)


func query_radius(center: Vector2, radius_px: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var min_c := Vector2i(int(floorf((center.x - radius_px) / CELL_SIZE)), int(floorf((center.y - radius_px) / CELL_SIZE)))
	var max_c := Vector2i(int(floorf((center.x + radius_px) / CELL_SIZE)), int(floorf((center.y + radius_px) / CELL_SIZE)))
	for cx in range(min_c.x, max_c.x + 1):
		for cy in range(min_c.y, max_c.y + 1):
			var key := Vector2i(cx, cy)
			if _grid.has(key):
				for e in _grid[key]:
					if bool(e["alive"]):
						out.append(e)
	return out


func find_nearest_pos(origin: Vector2, max_range: float, exclude_uids: Dictionary = {}) -> Dictionary:
	var candidates := query_radius(origin, max_range)
	var best_sq := max_range * max_range
	var best_e: Dictionary = {}
	for e in candidates:
		if exclude_uids.has(int(e["uid"])):
			continue
		var d_sq := origin.distance_squared_to(Vector2(e["pos"]))
		if d_sq <= best_sq:
			best_sq = d_sq
			best_e = e
	if best_e.is_empty():
		return {}
	return {"found": true, "pos": Vector2(best_e["pos"]), "enemy": best_e}


func _compute_separation(self_e: Dictionary, pos: Vector2) -> Vector2:
	var key := Vector2i(int(floorf(pos.x / CELL_SIZE)), int(floorf(pos.y / CELL_SIZE)))
	var push := Vector2.ZERO
	var my_r := float(self_e["radius"])
	var my_uid := int(self_e["uid"])
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var cell_key := Vector2i(key.x + dx, key.y + dy)
			if not _grid.has(cell_key):
				continue
			for other in _grid[cell_key]:
				if int(other["uid"]) == my_uid:
					continue
				var diff := pos - Vector2(other["pos"])
				var min_d := my_r + float(other["radius"])
				var d_sq := diff.length_squared()
				if d_sq > 0.01 and d_sq < min_d * min_d:
					var d := sqrt(d_sq)
					push += (diff / d) * ((min_d - d) * 4.5)
	return push


func _find_by_uid(uid: int) -> Dictionary:
	for d in _pool:
		if bool(d["alive"]) and int(d["uid"]) == uid:
			return d
	return {}


static func _dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var len_sq := ab.length_squared()
	if len_sq <= 0.0001:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / len_sq, 0.0, 1.0)
	return p.distance_to(a + ab * t)
