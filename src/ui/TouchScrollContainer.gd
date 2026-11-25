class_name TouchScrollContainer
extends ScrollContainer
## Mobile-friendly ScrollContainer that allows touch & drag scrolling even when
## gestures start on child cards, icons, labels, or buttons (horizontal or vertical).

const DRAG_DEADZONE_PX := 14.0

var _mouse_pressed: bool = false
var _mouse_dragging: bool = false
var _drag_origin: Vector2 = Vector2.ZERO
var _last_mouse_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_force_pass_scroll_events = true
	scroll_deadzone = int(DRAG_DEADZONE_PX)

	# Keep existing and dynamically added descendants non-blocking so drags bubble up.
	_wire_subtree(self)


func _wire_subtree(node: Node) -> void:
	if node != self and (node == get_h_scroll_bar() or node == get_v_scroll_bar()):
		return
	if node != self and node is Control:
		var ctrl := node as Control
		# Upgrade default MOUSE_FILTER_STOP (PanelContainer, Button, CheckButton, ColorRect, etc.)
		# to PASS while preserving intentional MOUSE_FILTER_IGNORE on visual overlays.
		if ctrl.mouse_filter == Control.MOUSE_FILTER_STOP:
			ctrl.mouse_filter = Control.MOUSE_FILTER_PASS
	if not node.child_entered_tree.is_connected(_on_subtree_child_entered):
		node.child_entered_tree.connect(_on_subtree_child_entered)
	for child in node.get_children():
		_wire_subtree(child)


func _on_subtree_child_entered(child: Node) -> void:
	_wire_subtree(child)


func _gui_input(event: InputEvent) -> void:
	# Handle left-mouse drag on desktop (non-emulated pointer) without interfering
	# with native Android touchscreen ScrollContainer momentum scrolling.
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_mouse_pressed = true
			_mouse_dragging = false
			_drag_origin = mb.position
			_last_mouse_pos = mb.position
		else:
			var was_dragging := _mouse_dragging
			_mouse_pressed = false
			_mouse_dragging = false
			if was_dragging:
				accept_event()
	elif event is InputEventMouseMotion and _mouse_pressed:
		var mm := event as InputEventMouseMotion
		if (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			_mouse_pressed = false
			_mouse_dragging = false
			return
		var total_delta := mm.position - _drag_origin
		var h_on := horizontal_scroll_mode != SCROLL_MODE_DISABLED
		var v_on := vertical_scroll_mode != SCROLL_MODE_DISABLED
		if not _mouse_dragging:
			var crossed := (h_on and absf(total_delta.x) >= DRAG_DEADZONE_PX) or (v_on and absf(total_delta.y) >= DRAG_DEADZONE_PX)
			if not crossed:
				return
			_mouse_dragging = true
			_last_mouse_pos = mm.position
			propagate_notification(Control.NOTIFICATION_SCROLL_BEGIN)
			emit_signal("scroll_started")
		var step := mm.position - _last_mouse_pos
		_last_mouse_pos = mm.position
		if h_on:
			scroll_horizontal = maxi(0, scroll_horizontal - int(roundf(step.x)))
		if v_on:
			scroll_vertical = maxi(0, scroll_vertical - int(roundf(step.y)))
		accept_event()
