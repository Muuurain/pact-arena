class_name HeroSelectScreen
extends Control
## Hero selection, starting weapon picker (default + mastered weapons),
## early Ember unlock for challenge heroes, and Heat 0..8 protocol toggles.

signal back_requested()
signal launch_run_requested(hero_id: String, weapon_id: String, heats: Array[String], danger_level: int)

var _selected_hero: String = "hero_crimson_blade"
var _selected_weapon: String = ""
var _selected_heats: Array[String] = []
var _selected_danger: int = 0

var _embers_lbl: Label
var _hero_list: VBoxContainer
var _weapon_box: HBoxContainer
var _danger_box: HBoxContainer
var _danger_desc_lbl: Label
var _heat_modal: Control
var _heat_panel: PanelContainer
var _heat_modal_sub_lbl: Label
var _heat_list_box: VBoxContainer
var _heat_done_btn: Button
var _heat_toggle_btn: Button
var _start_btn: Button


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

	var root_v := VBoxContainer.new()
	root_v.add_theme_constant_override("separation", 10)
	safe.add_child(root_v)

	# Header
	var top_h := HBoxContainer.new()
	root_v.add_child(top_h)
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
	title.text = "整装出征"
	title.add_theme_font_size_override("font_size", 26)
	top_h.add_child(title)

	_embers_lbl = Label.new()
	_embers_lbl.add_theme_font_size_override("font_size", 18)
	_embers_lbl.add_theme_color_override("font_color", UiStyles.COL_GOLD)
	top_h.add_child(_embers_lbl)

	# Scrollable Hero List
	var scroll := TouchScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_v.add_child(scroll)

	_hero_list = VBoxContainer.new()
	_hero_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hero_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_hero_list)

	# Starting Weapon Picker
	var w_lbl := Label.new()
	w_lbl.text = "初始武器（精通 Lv.2 起全职业通用 · 点卡可看英雄详情）："
	w_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	w_lbl.add_theme_font_size_override("font_size", 15)
	w_lbl.add_theme_color_override("font_color", UiStyles.COL_TEXT_DIM)
	root_v.add_child(w_lbl)

	var w_scroll := TouchScrollContainer.new()
	w_scroll.custom_minimum_size.y = 92
	w_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_v.add_child(w_scroll)

	_weapon_box = HBoxContainer.new()
	_weapon_box.add_theme_constant_override("separation", 10)
	w_scroll.add_child(_weapon_box)

	# Difficulty / Danger Selector (D0 ~ D5)
	var d_lbl := Label.new()
	d_lbl.text = "选择危险度（D0 ~ D5，难度越高余烬越丰厚）："
	d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d_lbl.add_theme_font_size_override("font_size", 15)
	d_lbl.add_theme_color_override("font_color", UiStyles.COL_TEXT_DIM)
	root_v.add_child(d_lbl)

	var d_scroll := TouchScrollContainer.new()
	d_scroll.custom_minimum_size.y = 74
	d_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_v.add_child(d_scroll)

	_danger_box = HBoxContainer.new()
	_danger_box.add_theme_constant_override("separation", 8)
	d_scroll.add_child(_danger_box)

	_danger_desc_lbl = Label.new()
	_danger_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_danger_desc_lbl.add_theme_font_size_override("font_size", 14)
	root_v.add_child(_danger_desc_lbl)

	# Heat Modifiers Modal Trigger
	_heat_toggle_btn = Button.new()
	UiStyles.style_button(_heat_toggle_btn, UiStyles.COL_VOID, false, 56.0)
	_heat_toggle_btn.pressed.connect(func():
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
		_rebuild_heats()
		_heat_modal.visible = true
		UiStyles.animate_pop_in(_heat_panel)
	)
	root_v.add_child(_heat_toggle_btn)

	# Centered Spacious Heat Selector Modal
	var hm := UiStyles.make_centered_modal_shell(self, 640.0, UiStyles.COL_VOID, 95)
	_heat_modal = hm["overlay"]
	_heat_panel = hm["panel"]
	var h_body: VBoxContainer = hm["body"]

	var h_title := Label.new()
	h_title.text = "深渊热度加码"
	h_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h_title.add_theme_font_size_override("font_size", 26)
	h_title.add_theme_color_override("font_color", UiStyles.COL_VOID)
	h_body.add_child(h_title)

	_heat_modal_sub_lbl = Label.new()
	_heat_modal_sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_heat_modal_sub_lbl.add_theme_font_size_override("font_size", 16)
	_heat_modal_sub_lbl.add_theme_color_override("font_color", UiStyles.COL_GOLD)
	h_body.add_child(_heat_modal_sub_lbl)

	var h_scroll := TouchScrollContainer.new()
	h_scroll.custom_minimum_size = Vector2(0, 480)
	h_body.add_child(h_scroll)

	_heat_list_box = VBoxContainer.new()
	_heat_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_heat_list_box.add_theme_constant_override("separation", 10)
	h_scroll.add_child(_heat_list_box)

	var h_actions := HBoxContainer.new()
	h_actions.add_theme_constant_override("separation", 10)
	h_body.add_child(h_actions)

	var all_btn := Button.new()
	all_btn.text = "全选"
	all_btn.custom_minimum_size.x = 120
	UiStyles.style_button(all_btn, UiStyles.COL_CRIMSON, false, 54.0)
	all_btn.pressed.connect(func():
		_selected_heats.clear()
		for ht in GameData.heats:
			_selected_heats.append(String(ht["id"]))
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
		_rebuild_heats()
	)
	h_actions.add_child(all_btn)

	var clr_btn := Button.new()
	clr_btn.text = "清空"
	clr_btn.custom_minimum_size.x = 120
	UiStyles.style_button(clr_btn, UiStyles.COL_BORDER, false, 54.0)
	clr_btn.pressed.connect(func():
		_selected_heats.clear()
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
		_rebuild_heats()
	)
	h_actions.add_child(clr_btn)

	_heat_done_btn = Button.new()
	_heat_done_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_heat_done_btn.text = "确认"
	UiStyles.style_button(_heat_done_btn, UiStyles.COL_VOID, true, 54.0)
	_heat_done_btn.pressed.connect(func():
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
		_heat_modal.visible = false
	)
	h_actions.add_child(_heat_done_btn)

	# Launch Button
	_start_btn = Button.new()
	_start_btn.text = "开始第 1 波"
	UiStyles.style_button(_start_btn, UiStyles.COL_CRIMSON, true, 62.0)
	_start_btn.pressed.connect(func():
		if not SaveManager.is_hero_unlocked(_selected_hero):
			return
		SaveManager.set_selected_heats(_selected_heats)
		SaveManager.set_selected_danger(_selected_danger)
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
		visible = false
		launch_run_requested.emit(_selected_hero, _selected_weapon, _selected_heats, _selected_danger)
	)
	root_v.add_child(_start_btn)


func open() -> void:
	_heat_modal.visible = false
	_selected_heats = SaveManager.get_selected_heats()
	_selected_danger = SaveManager.get_selected_danger()
	if _selected_weapon.is_empty():
		_selected_weapon = String(GameData.get_hero(_selected_hero).get("default_weapon", "wpn_chainsaw"))
	refresh_ui()
	visible = true
	UiStyles.animate_pop_in(self)


func refresh_ui() -> void:
	_embers_lbl.text = "余烬 %d" % SaveManager.get_embers()
	for c in _hero_list.get_children():
		_hero_list.remove_child(c)
		c.queue_free()

	for h in GameData.heroes:
		var hid := String(h["id"])
		var unlocked := SaveManager.is_hero_unlocked(hid)
		var is_sel := (hid == _selected_hero)
		var hcol := Color(h.get("color", UiStyles.COL_CRIMSON))

		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UiStyles.make_panel_style(UiStyles.COL_CARD, UiStyles.COL_GOLD if is_sel else (hcol if unlocked else Color(0.28, 0.24, 0.34)), 16, 3 if is_sel else 2))
		_hero_list.add_child(card)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		card.add_child(hbox)

		var info_btn := Button.new()
		info_btn.flat = true
		info_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_btn.custom_minimum_size.y = 100
		hbox.add_child(info_btn)

		var row := HBoxContainer.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.add_theme_constant_override("separation", 12)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info_btn.add_child(row)

		var icon := TextureRect.new()
		icon.texture = load(String(h["sprite"]))
		icon.custom_minimum_size = Vector2(96, 96)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not unlocked:
			icon.modulate = Color(0.35, 0.35, 0.4, 0.8)
		row.add_child(icon)

		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.alignment = BoxContainer.ALIGNMENT_CENTER
		tv.add_theme_constant_override("separation", 5)
		tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(tv)

		var nl := Label.new()
		nl.text = "%s · %s" % [String(h["name"]), String(h["title"])]
		nl.add_theme_font_size_override("font_size", 21)
		nl.add_theme_color_override("font_color", hcol if unlocked else Color(0.65, 0.65, 0.72))
		tv.add_child(nl)

		var dl := Label.new()
		dl.text = (String(h.get("short_desc", h["passive_desc"])) + "  · 详情 ›") if unlocked else ("未解锁（点看条件）›")
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dl.add_theme_font_size_override("font_size", 14)
		dl.add_theme_color_override("font_color", UiStyles.COL_TEXT_DIM if unlocked else UiStyles.COL_GOLD)
		tv.add_child(dl)

		var h_copy := (h as Dictionary).duplicate(true)
		var is_unl := unlocked
		info_btn.pressed.connect(func():
			EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
			var def_wdef := GameData.get_weapon(String(h_copy.get("default_weapon", "")))
			var stat_parts: Array[String] = []
			var mods: Dictionary = h_copy.get("stat_mods", {})
			for sk in mods:
				stat_parts.append(StatBlock.format_stat_delta(String(sk), float(mods[sk])))
			var mod_line := "、".join(stat_parts) if not stat_parts.is_empty() else "标准面板"
			var body := "职业特性：\n%s\n\n初始武器：%s\n初始修正：%s\n武器槽上限：%d 格%s" % [
				String(h_copy["passive_desc"]),
				String(def_wdef.get("name", "")),
				mod_line,
				int(h_copy.get("max_weapons", 6)),
				("" if is_unl else ("\n\n解锁方式：" + String(h_copy.get("unlock_desc", ""))))
			]
			UiStyles.show_detail_modal(self, {
				"title": "%s · %s" % [String(h_copy["name"]), String(h_copy["title"])],
				"subtitle": "已解锁角色" if is_unl else "待解锁角色",
				"body": body,
				"accent": hcol,
				"icon_path": String(h_copy["sprite"]),
				"icon_modulate": Color.WHITE if is_unl else Color(0.55, 0.55, 0.65),
			})
		)

		if unlocked:
			var sel_btn := Button.new()
			sel_btn.text = "已选" if is_sel else "选用"
			sel_btn.custom_minimum_size = Vector2(92, 56)
			UiStyles.style_button(sel_btn, UiStyles.COL_GOLD if is_sel else hcol, is_sel, 56.0)
			sel_btn.pressed.connect(func():
				_selected_hero = hid
				_selected_weapon = String(h["default_weapon"])
				EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
				refresh_ui()
			)
			hbox.add_child(sel_btn)
		else:
			var cost := int(h["unlock_cost"])
			var unl_btn := Button.new()
			unl_btn.text = "解锁\n%d" % cost
			unl_btn.custom_minimum_size = Vector2(92, 60)
			unl_btn.disabled = SaveManager.get_embers() < cost
			UiStyles.style_button(unl_btn, UiStyles.COL_GOLD, true, 60.0)
			unl_btn.pressed.connect(func():
				if SaveManager.unlock_hero(hid, true):
					_selected_hero = hid
					_selected_weapon = String(h["default_weapon"])
					EventBus.sfx_requested.emit("sfx_awakening", 0.0)
					refresh_ui()
			)
			hbox.add_child(unl_btn)

	_rebuild_weapon_bar()
	_rebuild_danger_bar()
	_rebuild_heats()
	_start_btn.disabled = not SaveManager.is_hero_unlocked(_selected_hero)


func _rebuild_weapon_bar() -> void:
	for c in _weapon_box.get_children():
		_weapon_box.remove_child(c)
		c.queue_free()
	var def_w := String(GameData.get_hero(_selected_hero).get("default_weapon", "wpn_chainsaw"))
	for w in GameData.weapons:
		var wid := String(w["id"])
		var m_lv := SaveManager.get_weapon_mastery_level(wid)
		if wid != def_w and m_lv < 2:
			continue
		var is_sel := (_selected_weapon == wid)
		var fcol := UiStyles.faction_color(String(w["faction"]))
		var fac_n := UiStyles.faction_name(String(w["faction"]))
		var btn := Button.new()
		btn.text = ""
		btn.custom_minimum_size = Vector2(194, 80)
		UiStyles.style_button(btn, fcol, is_sel, 80.0)

		var row := HBoxContainer.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 8)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(row)

		var wic := TextureRect.new()
		wic.texture = load(String(w["sprite"]))
		wic.custom_minimum_size = Vector2(54, 54)
		wic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		wic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		wic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(wic)

		var txt_v := VBoxContainer.new()
		txt_v.alignment = BoxContainer.ALIGNMENT_CENTER
		txt_v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(txt_v)

		var n_l := Label.new()
		n_l.text = String(w["name"])
		n_l.add_theme_font_size_override("font_size", 16)
		n_l.add_theme_color_override("font_color", Color.WHITE)
		txt_v.add_child(n_l)

		var t_l := Label.new()
		t_l.text = "%s%s" % [fac_n, " · 专属" if wid == def_w else " · 精通"]
		t_l.add_theme_font_size_override("font_size", 12)
		t_l.add_theme_color_override("font_color", fcol.lightened(0.25))
		txt_v.add_child(t_l)

		btn.pressed.connect(func():
			_selected_weapon = wid
			EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
			_rebuild_weapon_bar()
		)
		_weapon_box.add_child(btn)


func _rebuild_danger_bar() -> void:
	for c in _danger_box.get_children():
		_danger_box.remove_child(c)
		c.queue_free()
	var best_cleared := SaveManager.get_best_danger_cleared()
	for d in GameData.difficulties:
		var lvl := int(d.get("level", 0))
		var is_sel := (lvl == _selected_danger)
		var dcol := Color(d.get("color", UiStyles.COL_CRIMSON))
		var btn := Button.new()
		var cleared_tag := "★已通关" if lvl <= best_cleared else ("余烬+%d%%" % int(d.get("ember_bonus_pct", 0)))
		btn.text = "%s\n%s" % [String(d.get("short_name", "D%d" % lvl)), cleared_tag]
		btn.custom_minimum_size = Vector2(128, 66)
		UiStyles.style_button(btn, dcol, is_sel, 66.0)
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(func():
			_selected_danger = lvl
			EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
			_rebuild_danger_bar()
		)
		_danger_box.add_child(btn)
	var cur := GameData.get_difficulty(_selected_danger)
	var ccol := Color(cur.get("color", UiStyles.COL_TEXT_DIM))
	_danger_desc_lbl.add_theme_color_override("font_color", ccol)
	_danger_desc_lbl.text = "%s：%s" % [String(cur.get("name", "D0")), String(cur.get("desc", ""))]


func _rebuild_heats() -> void:
	var n_heats := _selected_heats.size()
	var bonus := n_heats * 25
	_heat_toggle_btn.text = "热度加码：已选 %d / 8（余烬 +%d%% · 点击调整）" % [n_heats, bonus]
	if _heat_modal_sub_lbl != null:
		_heat_modal_sub_lbl.text = "当前开启 %d / 8 项挑战词缀 · 结算余烬 +%d%%" % [n_heats, bonus]
	if _heat_done_btn != null:
		_heat_done_btn.text = "确认生效 (%d/8)" % n_heats
	if _heat_list_box == null:
		return
	for c in _heat_list_box.get_children():
		_heat_list_box.remove_child(c)
		c.queue_free()
	for ht in GameData.heats:
		var htid := String(ht["id"])
		var active := _selected_heats.has(htid)
		var accent := UiStyles.COL_CRIMSON if active else UiStyles.COL_BORDER

		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UiStyles.make_panel_style(Color(0.18, 0.08, 0.18, 0.96) if active else UiStyles.COL_CARD, accent, 14, 3 if active else 2))
		_heat_list_box.add_child(card)

		var tap_btn := Button.new()
		tap_btn.flat = true
		tap_btn.custom_minimum_size.y = 74
		card.add_child(tap_btn)

		var row := HBoxContainer.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.add_theme_constant_override("separation", 12)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tap_btn.add_child(row)

		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.alignment = BoxContainer.ALIGNMENT_CENTER
		tv.add_theme_constant_override("separation", 3)
		tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(tv)

		var nl := Label.new()
		nl.text = String(ht["name"])
		nl.add_theme_font_size_override("font_size", 20)
		nl.add_theme_color_override("font_color", UiStyles.COL_GOLD if active else Color.WHITE)
		tv.add_child(nl)

		var dl := Label.new()
		dl.text = "%s · 余烬 +%d%%" % [String(ht["desc"]), int(ht.get("ember_bonus_pct", 25))]
		dl.add_theme_font_size_override("font_size", 15)
		dl.add_theme_color_override("font_color", Color(1.0, 0.78, 0.82) if active else UiStyles.COL_TEXT_DIM)
		tv.add_child(dl)

		var state_lbl := Label.new()
		state_lbl.text = "✓ 已开启" if active else "未开启"
		state_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		state_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		state_lbl.custom_minimum_size = Vector2(96, 44)
		state_lbl.add_theme_font_size_override("font_size", 16)
		state_lbl.add_theme_color_override("font_color", UiStyles.COL_CRIMSON if active else UiStyles.COL_TEXT_DIM)
		row.add_child(state_lbl)

		tap_btn.pressed.connect(func():
			if _selected_heats.has(htid):
				_selected_heats.erase(htid)
			else:
				_selected_heats.append(htid)
			EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
			_rebuild_heats()
		)
