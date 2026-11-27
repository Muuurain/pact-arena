class_name VfxManager
extends Node2D
## Pooled visual effects manager: floating combat numbers, hit flashes, lightning bolts,
## laser beams, singularities, blood clones, and shader-backed Boss telegraph indicators.

const TEXT_POOL_SIZE := 44
const BURST_POOL_SIZE := 56

var _text_pool: Array[Label] = []
var _text_cursor: int = 0
var _burst_pool: Array[Sprite2D] = []
var _burst_cursor: int = 0

var _glow_tex: Texture2D
var _slash_tex: Texture2D
var _slash_frames: Array[Texture2D] = []
var _add_mat: CanvasItemMaterial
var _transient_root: Node2D
var _ring_shader: Shader
var _active_singularities: Array[Dictionary] = []
var _active_clones: Array[Dictionary] = []


func _ready() -> void:
	_glow_tex = load("res://assets/art/sprites/projectiles/glow_soft.png")
	_slash_tex = load("res://assets/art/sprites/projectiles/slash_arc.png")
	_ring_shader = load("res://assets/shaders/telegraph_ring.gdshader")

	_transient_root = Node2D.new()
	add_child(_transient_root)

	_add_mat = CanvasItemMaterial.new()
	_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	for idx in range(6):
		var fpath := "res://assets/art/sprites/projectiles/slash_frames/slash_f%d.png" % idx
		if ResourceLoader.exists(fpath):
			var tex := load(fpath) as Texture2D
			if tex != null:
				_slash_frames.append(tex)
	if _slash_frames.is_empty() and _slash_tex != null:
		_slash_frames.append(_slash_tex)

	for i in range(TEXT_POOL_SIZE):
		var lbl := Label.new()
		lbl.visible = false
		lbl.z_index = 90
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 22)
		lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.08, 0.95))
		lbl.add_theme_constant_override("outline_size", 5)
		add_child(lbl)
		_text_pool.append(lbl)

	for i in range(BURST_POOL_SIZE):
		var sp := Sprite2D.new()
		sp.texture = _glow_tex
		sp.visible = false
		sp.z_index = 45
		add_child(sp)
		_burst_pool.append(sp)

	EventBus.floating_text_requested.connect(spawn_floating_text)


func _kill_node_tween(node: Node) -> void:
	if node.has_meta("fx_tween"):
		var old_tw: Variant = node.get_meta("fx_tween")
		if old_tw is Tween and (old_tw as Tween).is_valid():
			(old_tw as Tween).kill()
		node.remove_meta("fx_tween")


func _get_vfx_alpha() -> float:
	return clampf(float(SaveManager.get_setting("vfx_opacity", 0.90)), 0.25, 1.0)


func spawn_floating_text(world_pos: Vector2, text: String, color: Color, scale_mult: float = 1.0) -> void:
	var lbl := _text_pool[_text_cursor]
	_text_cursor = (_text_cursor + 1) % TEXT_POOL_SIZE
	_kill_node_tween(lbl)
	lbl.text = text
	lbl.position = world_pos + Vector2(randf_range(-14.0, 14.0), -26.0)
	lbl.modulate = color
	lbl.scale = Vector2.ONE * scale_mult
	lbl.visible = true

	var tw := lbl.create_tween()
	lbl.set_meta("fx_tween", tw)
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 36.0 * scale_mult, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.45).set_delay(0.12)
	tw.chain().tween_callback(func(): lbl.visible = false)


func spawn_burst(world_pos: Vector2, color: Color, radius_px: float = 48.0, duration: float = 0.22) -> void:
	var sp := _burst_pool[_burst_cursor]
	_burst_cursor = (_burst_cursor + 1) % BURST_POOL_SIZE
	_kill_node_tween(sp)
	sp.global_position = world_pos
	sp.modulate = Color(color.r, color.g, color.b, _get_vfx_alpha() * 0.9)
	var target_scale := (radius_px * 2.0) / 128.0
	sp.scale = Vector2.ONE * (target_scale * 0.35)
	sp.visible = true

	var tw := sp.create_tween()
	sp.set_meta("fx_tween", tw)
	tw.set_parallel(true)
	tw.tween_property(sp, "scale", Vector2.ONE * target_scale, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(sp, "modulate:a", 0.0, duration)
	tw.chain().tween_callback(func(): sp.visible = false)


func spawn_slash_arc(
	world_pos: Vector2,
	angle_rad: float,
	radius_px: float,
	color: Color,
	full_circle: bool = false,
	flip_y: bool = false,
	is_heavy: bool = false
) -> void:
	if _slash_frames.is_empty():
		return
	var alpha_base := _get_vfx_alpha()
	var dur := 0.24 if full_circle else (0.21 if is_heavy else 0.17)
	var pass_count := 2 if full_circle else 1
	var s := (radius_px * 2.0) / 210.0
	if is_heavy:
		s *= 1.12
	var frame_count := _slash_frames.size()

	for p_idx in range(pass_count):
		var pivot := Node2D.new()
		pivot.global_position = world_pos
		var base_ang := angle_rad + float(p_idx) * PI
		var sweep_dir := -1.0 if flip_y else 1.0
		pivot.rotation = base_ang - (0.0 if full_circle else 0.22 * sweep_dir)
		pivot.z_index = 48
		_transient_root.add_child(pivot)

		var sy := -s if flip_y else s
		var aura_sp := Sprite2D.new()
		aura_sp.texture = _slash_frames[0]
		aura_sp.scale = Vector2(s * 0.84, sy * 0.84)
		aura_sp.modulate = Color(color.r, color.g, color.b, alpha_base)
		pivot.add_child(aura_sp)

		var core_sp := Sprite2D.new()
		core_sp.texture = _slash_frames[0]
		core_sp.material = _add_mat
		core_sp.scale = Vector2(s * 0.78, sy * 0.78)
		core_sp.modulate = Color(lerpf(color.r, 1.0, 0.72), lerpf(color.g, 1.0, 0.72), lerpf(color.b, 1.0, 0.72), alpha_base * 0.92)
		pivot.add_child(core_sp)

		var frames := _slash_frames
		var tw := pivot.create_tween()
		tw.tween_method(func(t: float):
			var idx := mini(frame_count - 1, int(floorf(t * float(frame_count))))
			var tex := frames[idx]
			aura_sp.texture = tex
			core_sp.texture = tex
			var pop := 0.84 + 0.26 * sin(minf(1.0, t * 1.35) * PI * 0.5)
			aura_sp.scale = Vector2(s * pop, sy * pop)
			core_sp.scale = Vector2(s * pop * 0.92, sy * pop * 0.92)
			if full_circle:
				pivot.rotation = base_ang + TAU * t * sweep_dir
			else:
				pivot.rotation = base_ang + (-0.22 + 0.52 * t) * sweep_dir
			var fade := 1.0 if t <= 0.65 else clampf((1.0 - t) / 0.35, 0.0, 1.0)
			aura_sp.modulate.a = alpha_base * fade
			core_sp.modulate.a = alpha_base * 0.92 * fade
		, 0.0, 1.0, dur)
		tw.tween_callback(pivot.queue_free)


func spawn_lightning_chain(points: PackedVector2Array, color: Color = Color(0.35, 0.85, 1.0)) -> void:
	if points.size() < 2:
		return
	var line := Line2D.new()
	line.width = 5.0
	line.default_color = Color(color.r, color.g, color.b, _get_vfx_alpha())
	line.z_index = 50
	var jagged := PackedVector2Array()
	for i in range(points.size() - 1):
		var a := points[i]
		var b := points[i + 1]
		jagged.append(a)
		var mid := (a + b) * 0.5 + Vector2(randf_range(-16.0, 16.0), randf_range(-16.0, 16.0))
		jagged.append(mid)
	jagged.append(points[points.size() - 1])
	line.points = jagged
	_transient_root.add_child(line)

	var tw := line.create_tween()
	tw.tween_property(line, "modulate:a", 0.0, 0.16)
	tw.tween_callback(line.queue_free)


func spawn_beam(from_pos: Vector2, to_pos: Vector2, width_px: float, color: Color, duration: float = 0.18) -> void:
	var line := Line2D.new()
	line.width = width_px
	line.default_color = Color(color.r, color.g, color.b, _get_vfx_alpha())
	line.z_index = 49
	line.points = PackedVector2Array([from_pos, to_pos])
	_transient_root.add_child(line)

	var tw := line.create_tween()
	tw.set_parallel(true)
	tw.tween_property(line, "width", 1.0, duration)
	tw.tween_property(line, "modulate:a", 0.0, duration)
	tw.chain().tween_callback(line.queue_free)


func spawn_dash_ghost(world_pos: Vector2, tex: Texture2D, tint: Color) -> void:
	var sp := Sprite2D.new()
	sp.texture = tex
	sp.global_position = world_pos
	sp.scale = Vector2(0.48, 0.44)
	sp.modulate = Color(tint.r, tint.g, tint.b, 0.65 * _get_vfx_alpha())
	sp.z_index = 25
	_transient_root.add_child(sp)

	var tw := sp.create_tween()
	tw.set_parallel(true)
	tw.tween_property(sp, "modulate:a", 0.0, 0.26)
	tw.tween_property(sp, "scale", Vector2(0.36, 0.34), 0.26)
	tw.chain().tween_callback(sp.queue_free)


func spawn_telegraph_circle(world_pos: Vector2, radius_px: float, duration: float, fill_col: Color, rim_col: Color, on_complete: Callable) -> void:
	var rect := ColorRect.new()
	rect.size = Vector2(radius_px * 2.0, radius_px * 2.0)
	rect.position = world_pos - Vector2(radius_px, radius_px)
	rect.z_index = 12
	var mat := ShaderMaterial.new()
	mat.shader = _ring_shader
	mat.set_shader_parameter("progress", 0.0)
	mat.set_shader_parameter("fill_color", fill_col)
	mat.set_shader_parameter("rim_color", rim_col)
	rect.material = mat
	_transient_root.add_child(rect)

	var tw := rect.create_tween()
	tw.tween_method(func(v: float): mat.set_shader_parameter("progress", v), 0.0, 1.0, duration)
	tw.tween_callback(func():
		rect.queue_free()
		if on_complete.is_valid():
			on_complete.call()
	)


func spawn_telegraph_line(from_pos: Vector2, to_pos: Vector2, width_px: float, duration: float, color: Color, on_complete: Callable) -> void:
	var line := Line2D.new()
	line.width = width_px
	line.default_color = Color(color.r, color.g, color.b, 0.32)
	line.z_index = 12
	line.points = PackedVector2Array([from_pos, to_pos])
	_transient_root.add_child(line)

	var tw := line.create_tween()
	tw.tween_property(line, "default_color:a", 0.88, duration)
	tw.tween_callback(func():
		line.queue_free()
		if on_complete.is_valid():
			on_complete.call()
	)


func spawn_singularity(world_pos: Vector2, radius_px: float, duration: float) -> void:
	var sp := Sprite2D.new()
	sp.texture = _glow_tex
	sp.global_position = world_pos
	sp.scale = Vector2.ONE * (radius_px * 2.0 / 128.0)
	sp.modulate = Color(0.62, 0.25, 0.98, 0.65 * _get_vfx_alpha())
	sp.z_index = 15
	add_child(sp)
	_active_singularities.append({
		"pos": world_pos,
		"radius": radius_px,
		"timer": duration,
		"node": sp,
	})


func spawn_blood_clone(world_pos: Vector2, tex: Texture2D, damage: float) -> void:
	var sp := Sprite2D.new()
	sp.texture = tex
	sp.global_position = world_pos
	sp.scale = Vector2(0.55, 0.55)
	sp.modulate = Color(1.0, 0.22, 0.42, 0.85)
	sp.z_index = 26
	add_child(sp)
	_active_clones.append({
		"pos": world_pos,
		"timer": 2.0,
		"damage": damage,
		"node": sp,
	})


func step_active_fields(delta: float, enemy_mgr: EnemyManager) -> void:
	for i in range(_active_singularities.size() - 1, -1, -1):
		var sg: Dictionary = _active_singularities[i]
		sg["timer"] = float(sg["timer"]) - delta
		var sp: Sprite2D = sg["node"]
		sp.rotation += delta * 5.0
		enemy_mgr.pull_enemies_toward(Vector2(sg["pos"]), float(sg["radius"]), 210.0 * delta)
		if float(sg["timer"]) <= 0.0:
			sp.queue_free()
			_active_singularities.remove_at(i)

	for i in range(_active_clones.size() - 1, -1, -1):
		var cl: Dictionary = _active_clones[i]
		cl["timer"] = float(cl["timer"]) - delta
		var sp: Sprite2D = cl["node"]
		sp.modulate.a = 0.45 + 0.4 * absf(sin(float(cl["timer"]) * 8.0))
		if float(cl["timer"]) <= 0.0:
			var pos := Vector2(cl["pos"])
			var dmg := float(cl["damage"])
			sp.queue_free()
			_active_clones.remove_at(i)
			spawn_burst(pos, Color(0.98, 0.22, 0.38), 165.0, 0.30)
			EventBus.sfx_requested.emit("sfx_mortar_boom", 0.08)
			EventBus.screen_shake_requested.emit(0.30)
			enemy_mgr.damage_in_radius(pos, 165.0, dmg, true, false, false, false)


func clear_all() -> void:
	if _transient_root != null:
		for c in _transient_root.get_children():
			c.queue_free()
	for lbl in _text_pool:
		_kill_node_tween(lbl)
		lbl.visible = false
	for sp in _burst_pool:
		_kill_node_tween(sp)
		sp.visible = false
	for sg in _active_singularities:
		if is_instance_valid(sg["node"]):
			(sg["node"] as Node).queue_free()
	_active_singularities.clear()
	for cl in _active_clones:
		if is_instance_valid(cl["node"]):
			(cl["node"] as Node).queue_free()
	_active_clones.clear()
