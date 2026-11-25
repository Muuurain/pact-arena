class_name SanctuaryScreen
extends Control
## Permanent Meta-Progression Talent Tree across 3 branches (战备/生存/贪婪)
## with 100% free full respec.

signal back_requested()

var _embers_lbl: Label
var _list_box: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = UiStyles.COL_BG
	add_child(bg)

	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 16)
	safe.add_theme_constant_override("margin_right", 16)
	UiStyles.apply_safe_area_padding(safe, 16.0, 18.0)
	add_child(safe)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	safe.add_child(v)

	var top_h := HBoxContainer.new()
	v.add_child(top_h)

	var back_btn := Button.new()
	back_btn.text = "返回"
	back_btn.custom_minimum_size = Vector2(98, 52)
	UiStyles.style_button(back_btn, UiStyles.COL_BORDER, false, 52.0)
	back_btn.pressed.connect(func():
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
		visible = false
		back_requested.emit()
	)
	top_h.add_child(back_btn)

	var title := Label.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "深渊圣所"
	title.add_theme_font_size_override("font_size", 28)
	top_h.add_child(title)

	_embers_lbl = Label.new()
	_embers_lbl.add_theme_font_size_override("font_size", 20)
	_embers_lbl.add_theme_color_override("font_color", UiStyles.COL_GOLD)
	top_h.add_child(_embers_lbl)

	var scroll := TouchScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(scroll)

	_list_box = VBoxContainer.new()
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_box.add_theme_constant_override("separation", 12)
	scroll.add_child(_list_box)

	var respec_btn := Button.new()
	respec_btn.text = "免费洗点（100% 返还已投余烬）"
	UiStyles.style_button(respec_btn, UiStyles.COL_AZURE, false, 56.0)
	respec_btn.pressed.connect(func():
		var ref := SaveManager.respec_all_talents()
		EventBus.sfx_requested.emit("sfx_reroll", 0.0)
		refresh_ui()
		if ref > 0:
			EventBus.floating_text_requested.emit(Vector2.ZERO, "返还 %d" % ref, UiStyles.COL_GOLD, 1.0)
	)
	v.add_child(respec_btn)


func open() -> void:
	refresh_ui()
	visible = true
	UiStyles.animate_pop_in(self)


func refresh_ui() -> void:
	_embers_lbl.text = "余烬: %d" % SaveManager.get_embers()
	for c in _list_box.get_children():
		c.queue_free()

	var branches := {"战备": UiStyles.COL_CRIMSON, "生存": UiStyles.COL_EMERALD, "贪婪": UiStyles.COL_GOLD}
	for b_name in ["战备", "生存", "贪婪"]:
		var b_col: Color = branches[b_name]
		var hdr := Label.new()
		hdr.text = "【%s分支】" % b_name
		hdr.add_theme_font_size_override("font_size", 22)
		hdr.add_theme_color_override("font_color", b_col)
		_list_box.add_child(hdr)

		for t in GameData.talents:
			if String(t["branch"]) != b_name:
				continue
			var tid := String(t["id"])
			var rank := SaveManager.get_talent_rank(tid)
			var max_r := int(t["max_rank"])
			var next_cost := SaveManager.get_talent_next_cost(tid)
			var cur_val := int(roundf(SaveManager.get_talent_value(tid)))
			var next_val := int(roundf(float(rank + 1) * float(t["per_rank"])))

			var card := PanelContainer.new()
			card.add_theme_stylebox_override("panel", UiStyles.make_panel_style(UiStyles.COL_CARD, b_col if rank > 0 else UiStyles.COL_BORDER, 14, 2))
			_list_box.add_child(card)

			var h := HBoxContainer.new()
			h.add_theme_constant_override("separation", 10)
			card.add_child(h)

			var tv := VBoxContainer.new()
			tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.add_child(tv)

			var nl := Label.new()
			nl.text = "%s  (%d / %d)" % [String(t["name"]), rank, max_r]
			nl.add_theme_font_size_override("font_size", 19)
			nl.add_theme_color_override("font_color", b_col)
			tv.add_child(nl)

			var show_v := cur_val if rank >= max_r else next_val
			var dl := Label.new()
			dl.text = String(t["desc"]).replace("{val}", str(show_v))
			dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			dl.add_theme_font_size_override("font_size", 15)
			tv.add_child(dl)

			var up_btn := Button.new()
			up_btn.custom_minimum_size = Vector2(122, 56)
			if next_cost < 0:
				up_btn.text = "已满级"
				up_btn.disabled = true
			else:
				up_btn.text = "强化 $%d" % next_cost
				up_btn.disabled = SaveManager.get_embers() < next_cost
			UiStyles.style_button(up_btn, b_col, next_cost >= 0, 56.0)
			up_btn.pressed.connect(func():
				if SaveManager.upgrade_talent(tid):
					EventBus.sfx_requested.emit("sfx_buy_merge", 0.0)
					refresh_ui()
			)
			h.add_child(up_btn)
