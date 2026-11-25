class_name AwakeningModal
extends Control
## Triggered when a weapon upgrades to Tier 4 Mythic: lets player choose 1 of 2
## transformative Red Awakening paths.

signal awakening_chosen(slot_idx: int, awakening_id: String)

var _slot_idx: int = -1
var _title_lbl: Label
var _choices_box: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build_ui()


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.04, 0.01, 0.08, 0.90)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -310
	panel.offset_right = 310
	panel.offset_top = -310
	panel.offset_bottom = 310
	panel.add_theme_stylebox_override("panel", UiStyles.make_panel_style(Color(0.14, 0.06, 0.16, 0.98), UiStyles.COL_GOLD, 20, 3))
	add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	panel.add_child(v)

	_title_lbl = Label.new()
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.text = "四阶红武觉醒！"
	_title_lbl.add_theme_font_size_override("font_size", 28)
	_title_lbl.add_theme_color_override("font_color", UiStyles.COL_GOLD)
	v.add_child(_title_lbl)

	var sub := Label.new()
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.text = "请选择该武器本局的终极质变形态："
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", UiStyles.COL_TEXT_DIM)
	v.add_child(sub)

	_choices_box = VBoxContainer.new()
	_choices_box.add_theme_constant_override("separation", 14)
	v.add_child(_choices_box)


func open_for_weapon(slot_idx: int, weapon_id: String) -> void:
	_slot_idx = slot_idx
	var wdef := GameData.get_weapon(weapon_id)
	_title_lbl.text = "【%s】四阶红武觉醒！" % String(wdef.get("name", ""))
	for c in _choices_box.get_children():
		c.queue_free()

	var awks: Array = wdef.get("awakenings", [])
	for a in awks:
		var aid := String(a["id"])
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UiStyles.make_panel_style(UiStyles.COL_CARD, UiStyles.COL_CRIMSON, 14, 2))
		_choices_box.add_child(card)

		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 8)
		card.add_child(cv)

		var n := Label.new()
		n.text = String(a["name"])
		n.add_theme_font_size_override("font_size", 22)
		n.add_theme_color_override("font_color", UiStyles.COL_GOLD)
		cv.add_child(n)

		var d := Label.new()
		d.text = String(a["desc"])
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.add_theme_font_size_override("font_size", 18)
		cv.add_child(d)

		var btn := Button.new()
		btn.text = "觉醒此形态"
		UiStyles.style_button(btn, UiStyles.COL_CRIMSON, true, 52.0)
		btn.pressed.connect(func():
			EventBus.sfx_requested.emit("sfx_awakening", 0.0)
			visible = false
			awakening_chosen.emit(_slot_idx, aid)
		)
		cv.add_child(btn)

	visible = true
