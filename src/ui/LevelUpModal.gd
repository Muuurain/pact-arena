class_name LevelUpModal
extends Control
## Handles pending level-up stat card picks and elite treasure chest rewards
## before opening the shop between waves.

signal all_rewards_resolved()

var _run: RunState
var _title_lbl: Label
var _sub_lbl: Label
var _cards_box: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build_ui()


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.02, 0.07, 0.88)
	add_child(dim)

	var scroll := TouchScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiStyles.apply_safe_area_padding(scroll, 28.0, 24.0)
	add_child(scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	scroll.add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	margin.add_child(v)

	_title_lbl = Label.new()
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 32)
	_title_lbl.add_theme_color_override("font_color", UiStyles.COL_AZURE)
	v.add_child(_title_lbl)

	_sub_lbl = Label.new()
	_sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_lbl.add_theme_font_size_override("font_size", 18)
	_sub_lbl.add_theme_color_override("font_color", UiStyles.COL_TEXT_DIM)
	v.add_child(_sub_lbl)

	_cards_box = VBoxContainer.new()
	_cards_box.add_theme_constant_override("separation", 12)
	v.add_child(_cards_box)


func process_next_for_run(run: RunState) -> void:
	_run = run
	if _run.pending_chests > 0:
		_show_chest()
	elif _run.pending_level_ups > 0:
		_show_levelup()
	else:
		visible = false
		all_rewards_resolved.emit()


func _show_chest() -> void:
	for c in _cards_box.get_children():
		c.queue_free()
	_title_lbl.text = "深渊战利宝箱！"
	_title_lbl.add_theme_color_override("font_color", UiStyles.COL_GOLD)
	_sub_lbl.text = "剩余待开启宝箱：%d" % _run.pending_chests

	var valid_items := GameData.items
	var it: Dictionary = valid_items[randi() % valid_items.size()]
	var bonus_crystals := 18 + _run.wave * 3

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiStyles.make_panel_style(UiStyles.COL_CARD, UiStyles.COL_GOLD, 16, 2))
	_cards_box.add_child(card)

	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 10)
	card.add_child(cv)

	var top_h := HBoxContainer.new()
	top_h.add_theme_constant_override("separation", 12)
	cv.add_child(top_h)

	var icon := TextureRect.new()
	icon.texture = load(String(it.get("sprite", "")))
	icon.custom_minimum_size = Vector2(78, 78)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top_h.add_child(icon)

	var info_v := VBoxContainer.new()
	info_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_h.add_child(info_v)

	var n := Label.new()
	n.text = "获得道具：【%s】" % String(it["name"])
	n.add_theme_font_size_override("font_size", 24)
	n.add_theme_color_override("font_color", UiStyles.COL_GOLD)
	info_v.add_child(n)

	var d := Label.new()
	d.text = String(it["desc"]) + "\n随箱附带 +%d 血晶" % bonus_crystals
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.add_theme_font_size_override("font_size", 18)
	info_v.add_child(d)

	var btn := Button.new()
	btn.text = "收下"
	UiStyles.style_button(btn, UiStyles.COL_GOLD, true, 56.0)
	btn.pressed.connect(func():
		_run.pending_chests = maxi(0, _run.pending_chests - 1)
		_run.items.append(String(it["id"]))
		_run.add_crystals(bonus_crystals)
		_run.recompute_effective_stats()
		EventBus.sfx_requested.emit("sfx_buy_merge", 0.0)
		process_next_for_run(_run)
	)
	cv.add_child(btn)
	visible = true
	UiStyles.animate_pop_in(self)


func _show_levelup() -> void:
	for c in _cards_box.get_children():
		c.queue_free()
	_title_lbl.text = "等级提升！(Lv.%d)" % _run.level
	_title_lbl.add_theme_color_override("font_color", UiStyles.COL_AZURE)
	_sub_lbl.text = "还能挑 %d 项属性强化" % _run.pending_level_ups

	var choices := ShopGenerator.generate_levelup_choices(_run.stats.get_stat("luck"))
	for ch in choices:
		var tier := int(ch["tier"])
		var tcol := UiStyles.tier_color(tier)
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UiStyles.make_panel_style(UiStyles.COL_CARD, tcol, 14, 2))
		_cards_box.add_child(card)

		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		card.add_child(h)

		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(tv)

		var nl := Label.new()
		nl.text = "[%s] %s" % [UiStyles.tier_name(tier), String(ch["title"])]
		nl.add_theme_font_size_override("font_size", 21)
		nl.add_theme_color_override("font_color", tcol)
		tv.add_child(nl)

		var dl := Label.new()
		dl.text = String(ch["desc"])
		dl.add_theme_font_size_override("font_size", 18)
		tv.add_child(dl)

		var pick_btn := Button.new()
		pick_btn.text = "选择"
		pick_btn.custom_minimum_size = Vector2(106, 54)
		UiStyles.style_button(pick_btn, tcol, true, 54.0)
		var stat_k := String(ch["stat"])
		var stat_v := float(ch["amount"])
		pick_btn.pressed.connect(func():
			_run.apply_levelup_choice(stat_k, stat_v)
			EventBus.sfx_requested.emit("sfx_ui_click", 0.05)
			process_next_for_run(_run)
		)
		h.add_child(pick_btn)

	visible = true
