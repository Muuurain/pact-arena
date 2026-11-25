class_name ArenaController
extends Node2D
## Orchestrates wave timer, dynamic Wave Director spawns, Boss spawning,
## screen shake, Hit-stop, danger vignette, and wave-clear cleanup.

signal wave_completed(economy_report: Dictionary)
signal game_over_triggered()

@onready var floor_tex: TextureRect = $ArenaFloor
@onready var altar_sigil: Sprite2D = $AltarSigil
@onready var cam: Camera2D = $Camera2D
@onready var vfx_mgr: VfxManager = $VfxManager
@onready var pickup_mgr: PickupManager = $PickupManager
@onready var proj_mgr: ProjectileManager = $ProjectileManager
@onready var enemy_mgr: EnemyManager = $EnemyManager
@onready var player: PlayerController = $PlayerController
@onready var weapon_rig: WeaponRig = $WeaponRig

var _run: RunState
var _wave_active: bool = false
var _vacuuming: bool = false
var _vacuum_timer: float = 0.0
var _wave_time_left: float = 0.0
var _wave_total_time: float = 28.0
var _spawn_timer: float = 0.0
var _elite_spawned_count: int = 0
var _shake_trauma: float = 0.0
var _hit_stop_timer: float = 0.0


func _ready() -> void:
	EventBus.screen_shake_requested.connect(_on_shake_requested)
	EventBus.hit_stop_requested.connect(_on_hit_stop_requested)
	player.player_died.connect(_on_player_died)


func bind_run(run: RunState) -> void:
	_run = run
	enemy_mgr.setup(_run, player, proj_mgr, pickup_mgr, vfx_mgr)
	player.setup(_run, enemy_mgr, vfx_mgr, weapon_rig)
	weapon_rig.setup(_run, player, enemy_mgr, proj_mgr, vfx_mgr)


func start_wave() -> void:
	if _run == null:
		return
	_run.phase = "combat"
	_run.wave_kills = 0
	_run.recompute_effective_stats()
	enemy_mgr.clear_all()
	proj_mgr.clear_all()
	pickup_mgr.clear_all()
	vfx_mgr.clear_all()

	player.reset_for_wave()
	weapon_rig.rebuild_weapons()

	_wave_total_time = CombatFormulas.calc_wave_duration(_run.wave, _run.pacts)
	_wave_time_left = _wave_total_time
	_spawn_timer = 0.45
	_elite_spawned_count = 0
	_vacuuming = false
	_wave_active = true

	# Hero Void Weaver bonus blessing at wave start
	if _run.hero_id == "hero_void_weaver":
		EventBus.floating_text_requested.emit(player.global_position, "虚空祝福!", Color(0.82, 0.55, 1.0), 1.15)

	# Boss Wave 5 & Wave 10+
	if _run.wave == 5 or _run.wave == 10 or (_run.wave > 10 and _run.wave % 5 == 0):
		var boss_id := "boss_inquisitor" if _run.wave == 5 else "boss_sovereign"
		enemy_mgr.spawn_enemy(boss_id, Vector2(0.0, -280.0), _run.wave)
		EventBus.sfx_requested.emit("sfx_boss_warn", 0.0)
		EventBus.bgm_requested.emit("bgm_boss")
	else:
		EventBus.sfx_requested.emit("sfx_wave_start", 0.0)
		EventBus.bgm_requested.emit("bgm_combat")

	EventBus.wave_progress_changed.emit(_run.wave, _wave_time_left, _wave_total_time, _run.total_kills)


func _process(delta: float) -> void:
	# Hit-stop handling without stalling camera recovery
	if _hit_stop_timer > 0.0:
		_hit_stop_timer -= delta
		return

	_update_camera(delta)
	altar_sigil.rotation += delta * 0.14

	if not _wave_active and not _vacuuming:
		return

	if _vacuuming:
		_vacuum_timer -= delta
		pickup_mgr.step(delta, player.global_position, 9999.0, player, _run)
		if _vacuum_timer <= 0.0 or not pickup_mgr.has_active_pickups():
			_finish_wave_cleanup()
		return

	# Active Combat Step
	_wave_time_left = maxf(0.0, _wave_time_left - delta)
	player.step(delta)
	if _run.is_run_over:
		return
	weapon_rig.step(delta)
	proj_mgr.step(delta, player, enemy_mgr, vfx_mgr)
	vfx_mgr.step_active_fields(delta, enemy_mgr)
	enemy_mgr.step(delta)
	pickup_mgr.step(delta, player.global_position, _run.stats.get_stat("pickup_radius"), player, _run)

	_step_wave_director(delta)

	EventBus.wave_progress_changed.emit(_run.wave, _wave_time_left, _wave_total_time, _run.total_kills)

	# Wave complete when timer hits 0 (if boss wave, boss must also be slain!)
	if _wave_time_left <= 0.0 and not enemy_mgr.has_active_boss():
		_begin_wave_clear()


func _step_wave_director(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return

	var density := 1.0 + float(_run.wave - 1) * 0.14
	if _run.pacts.has("pact_time_rush"):
		density *= 1.45
	if _run.active_heats.has("heat_density"):
		density *= 1.20

	var interval := maxf(0.32, 1.35 / density)
	_spawn_timer = interval

	if enemy_mgr.get_alive_count() >= 145:
		return

	var pool := GameData.get_wave_pool(_run.wave)
	var pack := clampi(2 + int(_run.wave / 2) + (1 if _run.pacts.has("pact_time_rush") else 0), 2, 7)
	for _i in range(pack):
		var eid: String = pool[randi() % pool.size()]
		var pos := _pick_spawn_pos()
		enemy_mgr.spawn_enemy(eid, pos, _run.wave)

	# Elite spawns from Wave 3+
	var max_elites := 1 if _run.wave >= 3 and _run.wave < 7 else (2 if _run.wave >= 7 else 0)
	if _run.pacts.has("pact_bounty_hunt") or _run.active_heats.has("heat_elites"):
		max_elites += 1
	if _elite_spawned_count < max_elites and _wave_time_left < _wave_total_time * 0.68:
		_elite_spawned_count += 1
		enemy_mgr.spawn_enemy("elite_warden", _pick_spawn_pos(), _run.wave)


func _pick_spawn_pos() -> Vector2:
	for _try in range(6):
		var p := Vector2(randf_range(-540.0, 540.0), randf_range(-640.0, 640.0))
		if p.distance_to(player.global_position) >= 270.0:
			return p
	return Vector2(-460.0 if player.global_position.x > 0 else 460.0, randf_range(-420.0, 420.0))


func _begin_wave_clear() -> void:
	_wave_active = false
	_vacuuming = true
	_vacuum_timer = 1.15
	enemy_mgr.clear_all()
	proj_mgr.clear_all()
	vfx_mgr.clear_all()
	weapon_rig.clear_turrets()
	pickup_mgr.trigger_wave_vacuum()
	EventBus.sfx_requested.emit("sfx_wave_clear", 0.0)


func _finish_wave_cleanup() -> void:
	_vacuuming = false
	var eco := _run.complete_wave_economy()
	if _run.wave >= 10 and not _run.victory_reached:
		_run.victory_reached = true
	wave_completed.emit(eco)


func _on_player_died() -> void:
	_wave_active = false
	_vacuuming = false
	EventBus.sfx_requested.emit("sfx_defeat", 0.0)
	game_over_triggered.emit()


func _update_camera(delta: float) -> void:
	if player == null:
		return
	var target := player.global_position * 0.65
	target.x = clampf(target.x, -260.0, 260.0)
	target.y = clampf(target.y, -240.0, 240.0)
	cam.global_position = cam.global_position.lerp(target, minf(1.0, delta * 8.0))

	if _shake_trauma > 0.0:
		_shake_trauma = maxf(0.0, _shake_trauma - delta * 2.2)
		var mag := _shake_trauma * _shake_trauma * 24.0
		cam.offset = Vector2(randf_range(-mag, mag), randf_range(-mag, mag))
	else:
		cam.offset = Vector2.ZERO


func _on_shake_requested(trauma: float) -> void:
	if bool(SaveManager.get_setting("screen_shake", true)):
		_shake_trauma = minf(1.0, _shake_trauma + trauma)


func _on_hit_stop_requested(dur: float) -> void:
	_hit_stop_timer = maxf(_hit_stop_timer, dur)
