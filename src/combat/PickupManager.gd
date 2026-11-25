class_name PickupManager
extends Node2D
## Pooled pickup system for blood crystals, healing orbs, and elite treasure chests.
## Handles magnetic pull and wave-clear full-arena vacuum collection.

const MAX_PICKUPS := 180

var _sprites: Array[Sprite2D] = []
var _active: Array[Dictionary] = []
var _vacuum_all: bool = false

var _tex_crystal: Texture2D
var _tex_heal: Texture2D
var _tex_chest: Texture2D


func _ready() -> void:
	_tex_crystal = load("res://assets/art/sprites/pickups/pickup_crystal.png")
	_tex_heal = load("res://assets/art/sprites/pickups/pickup_heal.png")
	_tex_chest = load("res://assets/art/sprites/pickups/pickup_chest.png")

	for i in range(MAX_PICKUPS):
		var sp := Sprite2D.new()
		sp.visible = false
		sp.z_index = 18
		add_child(sp)
		_sprites.append(sp)
		_active.append({"alive": false, "kind": "crystal", "pos": Vector2.ZERO, "vel": Vector2.ZERO, "value": 1, "xp": 2.0, "sprite": sp})


func spawn_pickup(world_pos: Vector2, kind: String, crystal_val: int = 1, xp_val: float = 2.5) -> void:
	# Find free slot
	var slot_idx := -1
	for i in range(MAX_PICKUPS):
		if not bool(_active[i]["alive"]):
			slot_idx = i
			break

	if slot_idx == -1:
		# Merge into an existing crystal to avoid allocating more sprites on mobile
		if kind == "crystal":
			for i in range(MAX_PICKUPS):
				if bool(_active[i]["alive"]) and String(_active[i]["kind"]) == "crystal":
					_active[i]["value"] = int(_active[i]["value"]) + crystal_val
					_active[i]["xp"] = float(_active[i]["xp"]) + xp_val
					return
		return

	var d: Dictionary = _active[slot_idx]
	d["alive"] = true
	d["kind"] = kind
	d["pos"] = world_pos + Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0))
	d["vel"] = Vector2(randf_range(-90.0, 90.0), randf_range(-90.0, 90.0))
	d["value"] = crystal_val
	d["xp"] = xp_val

	var sp: Sprite2D = d["sprite"]
	sp.global_position = Vector2(d["pos"])
	match kind:
		"heal":
			sp.texture = _tex_heal
			sp.scale = Vector2(0.38, 0.38)
		"chest":
			sp.texture = _tex_chest
			sp.scale = Vector2(0.48, 0.48)
		_:
			sp.texture = _tex_crystal
			sp.scale = Vector2(0.38, 0.38)
	sp.visible = true


func trigger_wave_vacuum() -> void:
	_vacuum_all = true


func clear_all() -> void:
	_vacuum_all = false
	for d in _active:
		d["alive"] = false
		(d["sprite"] as Sprite2D).visible = false


func has_active_pickups() -> bool:
	for d in _active:
		if bool(d["alive"]):
			return true
	return false


func step(delta: float, player_pos: Vector2, pickup_radius: float, player: PlayerController, run: RunState) -> void:
	var rad_sq := pickup_radius * pickup_radius
	var t_sec := float(Time.get_ticks_msec()) * 0.005
	for i in range(_active.size()):
		var d: Dictionary = _active[i]
		if not bool(d["alive"]):
			continue
		var pos := Vector2(d["pos"])
		var vel := Vector2(d["vel"])
		vel = vel.lerp(Vector2.ZERO, minf(1.0, delta * 9.0))

		var to_player := player_pos - pos
		var dist_sq := to_player.length_squared()
		if _vacuum_all or dist_sq <= rad_sq:
			var speed := 1150.0 if _vacuum_all else 580.0
			var dir := to_player.normalized() if dist_sq > 0.01 else Vector2.UP
			vel = dir * speed

		pos += vel * delta
		d["pos"] = pos
		d["vel"] = vel
		var sp: Sprite2D = d["sprite"]
		sp.global_position = pos + Vector2(0.0, sin(t_sec + float(i)) * 3.2)

		if pos.distance_squared_to(player_pos) <= 32.0 * 32.0:
			_collect(d, player, run)


func _collect(d: Dictionary, player: PlayerController, run: RunState) -> void:
	var kind := String(d["kind"])
	d["alive"] = false
	(d["sprite"] as Sprite2D).visible = false

	match kind:
		"crystal":
			run.add_crystals(int(d["value"]))
			run.add_xp(float(d["xp"]))
			EventBus.sfx_requested.emit("sfx_pickup_crystal", 0.14)
		"heal":
			player.heal_or_convert(float(d["value"]))
			EventBus.sfx_requested.emit("sfx_pickup_heal", 0.06)
		"chest":
			run.pending_chests += 1
			run.add_crystals(22)
			EventBus.sfx_requested.emit("sfx_pickup_chest", 0.0)
			EventBus.floating_text_requested.emit(player.global_position, "宝箱 +1!", Color(1.0, 0.85, 0.25), 1.15)
