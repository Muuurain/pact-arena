class_name TouchJoystick
extends Control
## Full-area floating virtual joystick supporting mobile multi-touch and mouse emulation.

signal move_vector_changed(vec: Vector2)

const MAX_RADIUS := 78.0
const DEADZONE := 10.0

var _touch_index: int = -1
var _origin: Vector2 = Vector2.ZERO
var _knob_pos: Vector2 = Vector2.ZERO
var _active: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed and _touch_index == -1:
			_touch_index = st.index
			_start_stick(st.position)
			accept_event()
		elif not st.pressed and st.index == _touch_index:
			_release_stick()
			accept_event()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if sd.index == _touch_index:
			_update_stick(sd.position)
			accept_event()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and _touch_index == -1:
				_touch_index = 99
				_start_stick(mb.position)
			elif not mb.pressed and _touch_index == 99:
				_release_stick()
	elif event is InputEventMouseMotion and _touch_index == 99:
		_update_stick((event as InputEventMouseMotion).position)


func _start_stick(pos: Vector2) -> void:
	_active = true
	_origin = pos
	_knob_pos = pos
	queue_redraw()
	move_vector_changed.emit(Vector2.ZERO)


func _update_stick(pos: Vector2) -> void:
	var delta := pos - _origin
	var dist := delta.length()
	if dist > MAX_RADIUS:
		delta = delta.normalized() * MAX_RADIUS
	_knob_pos = _origin + delta
	queue_redraw()
	if dist < DEADZONE:
		move_vector_changed.emit(Vector2.ZERO)
	else:
		var strength := clampf((dist - DEADZONE) / (MAX_RADIUS - DEADZONE), 0.0, 1.0)
		move_vector_changed.emit(delta.normalized() * strength)


func _release_stick() -> void:
	_touch_index = -1
	_active = false
	queue_redraw()
	move_vector_changed.emit(Vector2.ZERO)


func _draw() -> void:
	if not _active:
		return
	draw_circle(_origin, MAX_RADIUS, Color(0.14, 0.10, 0.22, 0.32))
	draw_arc(_origin, MAX_RADIUS, 0.0, TAU, 36, Color(0.96, 0.25, 0.37, 0.65), 3.0)
	draw_circle(_knob_pos, 28.0, Color(0.96, 0.25, 0.37, 0.72))
	draw_arc(_knob_pos, 28.0, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, 0.8), 2.5)
