class_name PlayerController
extends Node2D
## Handles player movement, animated breathing/running/dash squash-and-stretch,
## 2-charge Blood Dash with real-time cooldown countdown, regen/toxic blood conversion,
## dodge mitigation, invulnerability frames, and revives.

signal player_died()

const BASE_SPRITE_SCALE := 0.48

var _run: RunState
var _enemy_mgr: EnemyManager
var _vfx: VfxManager
var _weapon_rig: WeaponRig

var _visual_root: Node2D
var _shadow: Sprite2D
var _sprite: Sprite2D
var _dash_ring: Sprite2D

var _input_dir: Vector2 = Vector2.ZERO
var _last_move_dir: Vector2 = Vector2.RIGHT
var _anim_time: float = 0.0
var _step_dust_timer: float = 0.0
var _hurt_punch: float = 0.0

var _dash_charges: int = 2
var _max_dash_charges: int = 2
var _dash_recharge_timer: float = 0.0
var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_dir: Vector2 = Vector2.RIGHT
var _dash_hit_uids: Dictionary = {}
var _ghost_timer: float = 0.0

var _invuln_timer: float = 0.0
var _regen_accum: float = 0.0
var _toxic_accum: float = 0.0


func _ready() -> void:
	_shadow = Sprite2D.new()
	_shadow.texture = load("res://assets/art/sprites/projectiles/glow_soft.png")
	_shadow.position = Vector2(0.0, 26.0)
	_shadow.scale = Vector2(0.55, 0.22)
	_shadow.modulate = Color(0.0, 0.0, 0.0, 0.55)
	_shadow.z_index = 19
	add_child(_shadow)

	_dash_ring = Sprite2D.new()
	_dash_ring.texture = load("res://assets/art/sprites/projectiles/glow_soft.png")
	_dash_ring.scale = Vector2(0.95, 0.95)
	_dash_ring.modulate = Color(0.96, 0.25, 0.37, 0.25)
	_dash_ring.z_index = 20
	add_child(_dash_ring)

	_visual_root = Node2D.new()
	_visual_root.z_index = 35
	add_child(_visual_root)

	_sprite = Sprite2D.new()
	_sprite.scale = Vector2(BASE_SPRITE_SCALE, BASE_SPRITE_SCALE)
	_visual_root.add_child(_sprite)


func setup(run: RunState, enemy_mgr: EnemyManager, vfx: VfxManager, weapon_rig: WeaponRig) -> void:
	_run = run
	_enemy_mgr = enemy_mgr
	_vfx = vfx
	_weapon_rig = weapon_rig
	var hdef := GameData.get_hero(_run.hero_id)
	_sprite.texture = load(String(hdef.get("sprite", "res://assets/art/sprites/heroes/hero_crimson_blade.png")))
	_dash_ring.modulate = Color(hdef.get("color", Color(0.96, 0.25, 0.37)))
	_dash_ring.modulate.a = 0.26
	reset_for_wave()


func reset_for_wave() -> void:
	global_position = Vector2.ZERO
	_dash_charges = _max_dash_charges
	_dash_recharge_timer = 0.0
	_is_dashing = false
	_invuln_timer = 0.5
	_regen_accum = 0.0
	_toxic_accum = 0.0
	_hurt_punch = 0.0
	_visual_root.position = Vector2.ZERO
	_visual_root.scale = Vector2.ONE
	_visual_root.rotation = 0.0
	_emit_hud_signals()


func set_touch_move_vector(vec: Vector2) -> void:
	_input_dir = vec


func _get_dash_total_cd() -> float:
	if _run == null:
		return 2.4
	return maxf(0.7, 2.4 * (1.0 - _run.stats.get_stat("dash_cd_pct") / 100.0))


func trigger_dash() -> void:
	if _run == null or _run.is_run_over or _is_dashing or _dash_charges <= 0:
		return
	_dash_charges -= 1
	_is_dashing = true
	_dash_timer = 0.16
	_dash_dir = _last_move_dir if _last_move_dir.length_squared() > 0.01 else Vector2.RIGHT
	_dash_hit_uids.clear()
	_ghost_timer = 0.0
	_invuln_timer = maxf(_invuln_timer, 0.24)
	EventBus.sfx_requested.emit("sfx_dash", 0.08)
	_vfx.spawn_burst(global_position, Color(0.96, 0.25, 0.37), 56.0, 0.2)

	if _run.pacts.has("pact_blood_clone"):
		var clone_dmg := 42.0 + _run.stats.get_stat("elemental_damage") * 1.4
		_vfx.spawn_blood_clone(global_position, _sprite.texture, clone_dmg)

	if _weapon_rig != null:
		_weapon_rig.reset_melee_cooldowns()

	_emit_dash_signal()


func step(delta: float) -> void:
	if _run == null:
		return

	_anim_time += delta
	var kb := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_vec := kb if kb.length_squared() > 0.02 else _input_dir
	var is_moving := move_vec.length_squared() > 0.02
	if is_moving:
		_last_move_dir = move_vec.normalized()
		_sprite.flip_h = _last_move_dir.x < -0.05

	if Input.is_action_just_pressed("dash"):
		trigger_dash()

	# Dash recharge with precise countdown updates
	if _dash_charges < _max_dash_charges:
		var cd := _get_dash_total_cd()
		_dash_recharge_timer += delta
		if _dash_recharge_timer >= cd:
			_dash_recharge_timer -= cd
			_dash_charges += 1
			if _dash_charges >= _max_dash_charges:
				_dash_recharge_timer = 0.0
			_emit_dash_signal()
		else:
			_emit_dash_signal()

	# Movement & Dash execution
	if _is_dashing:
		_dash_timer -= delta
		global_position += _dash_dir * 1440.0 * delta
		_ghost_timer -= delta
		if _ghost_timer <= 0.0:
			_ghost_timer = 0.028
			_vfx.spawn_dash_ghost(global_position, _sprite.texture, Color(0.98, 0.28, 0.42))
		_apply_dash_passthrough()
		if _dash_timer <= 0.0:
			_is_dashing = false
			_hurt_punch = 0.25 # Quick rebound squash on arrival
			_vfx.spawn_burst(global_position, Color(0.98, 0.35, 0.48), 44.0, 0.16)
	else:
		var spd := _run.stats.get_stat("move_speed")
		global_position += move_vec * spd * delta

	global_position.x = clampf(global_position.x, -575.0, 575.0)
	global_position.y = clampf(global_position.y, -675.0, 675.0)

	_update_hero_animation(delta, move_vec, is_moving)

	# Invulnerability blink
	if _invuln_timer > 0.0:
		_invuln_timer = maxf(0.0, _invuln_timer - delta)
		_sprite.modulate.a = 0.48 if int(_invuln_timer * 20.0) % 2 == 0 else 1.0
	else:
		_sprite.modulate.a = 1.0

	# HP Regen / Toxic Blood pulse
	var regen := _run.stats.get_stat("hp_regen")
	if regen > 0.0:
		_regen_accum += regen * delta
		if _regen_accum >= 1.0:
			var whole := floorf(_regen_accum)
			_regen_accum -= whole
			heal_or_convert(whole)
	elif regen < 0.0:
		_regen_accum += absf(regen) * delta
		if _regen_accum >= 1.0:
			_regen_accum -= 1.0
			_run.current_hp = maxf(1.0, _run.current_hp - 1.0)
			EventBus.player_hp_changed.emit(_run.current_hp, _run.stats.get_stat("max_hp"))


func _update_hero_animation(delta: float, move_vec: Vector2, is_moving: bool) -> void:
	_hurt_punch = maxf(0.0, _hurt_punch - delta * 2.8)
	_dash_ring.rotation += delta * 1.4

	if _is_dashing:
		_visual_root.scale = Vector2(1.26, 0.78)
		_visual_root.rotation = _dash_dir.x * 0.22
		_visual_root.position = Vector2(0.0, -4.0)
		_shadow.scale = Vector2(0.42, 0.16)
		return

	if is_moving:
		var hop := absf(sin(_anim_time * 13.5))
		var tilt := sin(_anim_time * 13.5) * 0.09 + move_vec.x * 0.11
		_visual_root.position = Vector2(0.0, -hop * 7.5)
		_visual_root.rotation = lerpf(_visual_root.rotation, tilt, minf(1.0, delta * 18.0))
		var sy := 1.0 + hop * 0.09 - _hurt_punch * 0.18
		var sx := 1.0 - hop * 0.06 + _hurt_punch * 0.22
		_visual_root.scale = Vector2(sx, sy)
		_shadow.scale = Vector2(0.55 - hop * 0.10, 0.22 - hop * 0.04)

		_step_dust_timer -= delta
		if _step_dust_timer <= 0.0:
			_step_dust_timer = 0.22
			_vfx.spawn_burst(global_position + Vector2(0.0, 22.0), Color(0.55, 0.45, 0.72), 16.0, 0.18)
	else:
		var breath := sin(_anim_time * 4.2)
		_visual_root.position = Vector2(0.0, breath * 2.2)
		_visual_root.rotation = lerpf(_visual_root.rotation, 0.0, minf(1.0, delta * 12.0))
		_visual_root.scale = Vector2(1.0 - breath * 0.035 + _hurt_punch * 0.22, 1.0 + breath * 0.045 - _hurt_punch * 0.18)
		_shadow.scale = Vector2(0.55, 0.22)


func _apply_dash_passthrough() -> void:
	if _enemy_mgr == null:
		return
	var hits := _enemy_mgr.query_radius(global_position, 74.0)
	for e in hits:
		var uid := int(e["uid"])
		if _dash_hit_uids.has(uid):
			continue
		if global_position.distance_squared_to(Vector2(e["pos"])) <= pow(float(e["radius"]) + 38.0, 2):
			_dash_hit_uids[uid] = true
			_enemy_mgr.apply_armor_break(e, 3.5)
			EventBus.sfx_requested.emit("sfx_armor_break", 0.06)
			EventBus.floating_text_requested.emit(Vector2(e["pos"]), "破甲!", Color(1.0, 0.4, 0.55), 1.05)
			if _run.hero_id == "hero_crimson_blade":
				var slash_dmg := 18.0 + _run.stats.get_stat("melee_damage") * 1.1
				e["bleed_timer"] = 3.0
				e["bleed_dps"] = maxf(float(e["bleed_dps"]), slash_dmg * 0.6)
				_enemy_mgr.apply_hit_to_enemy(e, slash_dmg, true, _dash_dir * 90.0, "crimson", "", false, false)


func heal_or_convert(amount: float) -> void:
	if _run == null or amount <= 0.0:
		return
	if _run.pacts.has("pact_toxic_blood"):
		_toxic_accum += amount * 2.2
		if _toxic_accum >= 4.0:
			var blast := _toxic_accum
			_toxic_accum = 0.0
			_vfx.spawn_burst(global_position, Color(0.32, 0.94, 0.48), 240.0, 0.25)
			EventBus.floating_text_requested.emit(global_position, "毒血+%d" % int(roundf(blast)), Color(0.35, 0.96, 0.55), 1.05)
			_enemy_mgr.damage_in_radius(global_position, 240.0, blast, false, false, false, false)
		return

	var max_hp := _run.stats.get_stat("max_hp")
	if _run.current_hp < max_hp:
		_run.current_hp = minf(max_hp, _run.current_hp + amount)
		EventBus.player_hp_changed.emit(_run.current_hp, max_hp)


func take_damage(raw_dmg: float) -> void:
	if _run == null or _run.is_run_over or _invuln_timer > 0.0 or _is_dashing:
		return

	if randf() * 100.0 < _run.stats.get_stat("dodge_pct"):
		EventBus.floating_text_requested.emit(global_position, "闪避", Color(0.55, 0.92, 1.0), 1.0)
		_invuln_timer = 0.22
		return

	var dmg := CombatFormulas.calc_player_damage_taken(raw_dmg, _run.stats)
	_run.current_hp -= dmg
	_hurt_punch = 0.65
	var iframe_bonus := 1.0 + SaveManager.get_talent_value("tal_iframes") / 100.0
	_invuln_timer = 0.55 * iframe_bonus
	EventBus.sfx_requested.emit("sfx_player_hurt", 0.08)
	EventBus.screen_shake_requested.emit(0.32)
	EventBus.floating_text_requested.emit(global_position, "-%d" % int(roundf(dmg)), Color(1.0, 0.24, 0.34), 1.2)

	if _run.current_hp <= 0.0:
		if _run.revives_left > 0:
			_run.revives_left -= 1
			_run.current_hp = maxf(1.0, _run.stats.get_stat("max_hp") * 0.5)
			_invuln_timer = 1.8
			_vfx.spawn_burst(global_position, Color(1.0, 0.72, 0.22), 280.0, 0.38)
			_enemy_mgr.damage_in_radius(global_position, 280.0, 120.0, true, false, true, false)
			EventBus.floating_text_requested.emit(global_position, "余烬复活!", Color(1.0, 0.85, 0.25), 1.45)
			EventBus.sfx_requested.emit("sfx_awakening", 0.0)
		else:
			_run.current_hp = 0.0
			_run.is_run_over = true
			EventBus.player_hp_changed.emit(0.0, _run.stats.get_stat("max_hp"))
			player_died.emit()
			return

	EventBus.player_hp_changed.emit(_run.current_hp, _run.stats.get_stat("max_hp"))


func _emit_dash_signal() -> void:
	var cd := _get_dash_total_cd()
	var left := 0.0 if _dash_charges >= _max_dash_charges else maxf(0.0, cd - _dash_recharge_timer)
	EventBus.player_dash_changed.emit(_dash_charges, _max_dash_charges, left, cd)


func _emit_hud_signals() -> void:
	if _run == null:
		return
	EventBus.player_hp_changed.emit(_run.current_hp, _run.stats.get_stat("max_hp"))
	EventBus.player_xp_changed.emit(_run.xp, _run.next_xp, _run.level)
	_emit_dash_signal()
	EventBus.crystals_changed.emit(_run.crystals)
