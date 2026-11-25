class_name PactAltarModal
extends Control
## Triggered on even waves: presents 3 high-stakes Blood Pact choices (or skip).

signal pact_resolved(chosen_id: String)

var _cards_box: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build_ui()


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.01, 0.06, 0.88)
	add_child(dim)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiStyles.apply_safe_area_padding(scroll, 26.0, 24.0)
	add_child(scroll)

	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation", 16)
	scroll.add_child(center)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	center.add_child(margin)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 14)
	margin.add_child(inner)

	var title := Label.new()
	title.text = "深渊血契祭坛"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", UiStyles.COL_CRIMSON)
	inner.add_child(title)

	var sub := Label.new()
	sub.text = "高风险高回报：签署一条禁忌血契，或拒绝诱惑保留稳健"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", UiStyles.COL_TEXT_DIM)
	inner.add_child(sub)

	_cards_box = VBoxContainer.new()
	_cards_box.add_theme_constant_override("separation", 14)
	inner.add_child(_cards_box)

	var skip_btn := Button.new()
	skip_btn.text = "拒绝所有血契 (直接进入商店)"
	UiStyles.style_button(skip_btn, UiStyles.COL_BORDER, false, 56.0)
	skip_btn.pressed.connect(func():
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
		visible = false
		pact_resolved.emit("")
	)
	inner.add_child(skip_btn)


func open_for_run(run: RunState) -> void:
	for c in _cards_box.get_children():
		c.queue_free()
	var choices := ShopGenerator.generate_pact_choices(run)
	if choices.is_empty():
		pact_resolved.emit("")
		return

	for p in choices:
		var pid := String(p["id"])
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UiStyles.make_panel_style(Color(0.14, 0.07, 0.16, 0.96), UiStyles.COL_CRIMSON, 16, 2))
		_cards_box.add_child(card)

		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 8)
		card.add_child(cv)

		var name_l := Label.new()
		name_l.text = "【%s】" % String(p["name"])
		name_l.add_theme_font_size_override("font_size", 24)
		name_l.add_theme_color_override("font_color", UiStyles.COL_GOLD)
		cv.add_child(name_l)

		var cost_l := Label.new()
		cost_l.text = "代价：" + String(p["cost_text"])
		cost_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cost_l.add_theme_font_size_override("font_size", 18)
		cost_l.add_theme_color_override("font_color", UiStyles.COL_CRIMSON)
		cv.add_child(cost_l)

		var gain_l := Label.new()
		gain_l.text = "赐福：" + String(p["gain_text"])
		gain_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		gain_l.add_theme_font_size_override("font_size", 18)
		gain_l.add_theme_color_override("font_color", UiStyles.COL_EMERALD)
		cv.add_child(gain_l)

		var sign_btn := Button.new()
		sign_btn.text = "立下血契"
		UiStyles.style_button(sign_btn, UiStyles.COL_CRIMSON, true, 52.0)
		sign_btn.pressed.connect(func():
			EventBus.sfx_requested.emit("sfx_pact_sign", 0.0)
			visible = false
			pact_resolved.emit(pid)
		)
		cv.add_child(sign_btn)

	visible = true
	UiStyles.animate_pop_in(self)
