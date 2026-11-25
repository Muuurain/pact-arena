class_name AwakeningModal
extends Control
## Triggered when a weapon upgrades to Tier 4 Mythic: lets player choose 1 of 2
## transformative Red Awakening paths.

signal awakening_chosen(slot_idx: int, awakening_id: String)

var _slot_idx: int = -1
var _weapon_icon: TextureRect
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

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 0)
	panel.add_theme_stylebox_override("panel", UiStyles.make_panel_style(Color(0.14, 0.06, 0.16, 0.98), UiStyles.COL_GOLD, 20, 3))
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)

	_weapon_icon = TextureRect.new()
	_weapon_icon.custom_minimum_size = Vector2(88, 88)
	_weapon_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_weapon_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_weapon_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	v.add_child(_weapon_icon)

	_title_lbl = Label.new()
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.text = "四阶神兵觉醒"
	_title_lbl.add_theme_font_size_override("font_size", 28)
	_title_lbl.add_theme_color_override("font_color", UiStyles.COL_GOLD)
	v.add_child(_title_lbl)

	var sub := Label.new()
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.text = "武器已至四阶红武，择一化作本局最终觉醒形态："
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override("font_size", 17)
	sub.add_theme_color_override("font_color", UiStyles.COL_TEXT_DIM)
	v.add_child(sub)

	_choices_box = VBoxContainer.new()
	_choices_box.add_theme_constant_override("separation", 14)
	v.add_child(_choices_box)


func open_for_weapon(slot_idx: int, weapon_id: String) -> void:
	_slot_idx = slot_idx
	var wdef := GameData.get_weapon(weapon_id)
	_weapon_icon.texture = load(String(wdef.get("sprite", "")))
	_title_lbl.text = "【%s】四阶觉醒" % String(wdef.get("name", ""))
	for c in _choices_box.get_children():
		c.queue_free()

	var awks: Array = wdef.get("awakenings", [])
	for a in awks:
		var aid := String(a["id"])
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UiStyles.make_panel_style(UiStyles.COL_CARD, UiStyles.COL_CRIMSON, 16, 2))
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
		btn.text = "选定此形态"
		UiStyles.style_button(btn, UiStyles.COL_CRIMSON, true, 54.0)
		btn.pressed.connect(func():
			EventBus.sfx_requested.emit("sfx_awakening", 0.0)
			visible = false
			awakening_chosen.emit(_slot_idx, aid)
		)
		cv.add_child(btn)

	visible = true
	UiStyles.animate_pop_in(self)
