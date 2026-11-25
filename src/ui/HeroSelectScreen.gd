class_name HeroSelectScreen
extends Control
## Hero selection, starting weapon picker (default + mastered weapons),
## early Ember unlock for challenge heroes, and Heat 0..8 protocol toggles.

signal back_requested()
signal launch_run_requested(hero_id: String, weapon_id: String, heats: Array[String])

var _selected_hero: String = "hero_crimson_blade"
var _selected_weapon: String = ""
var _selected_heats: Array[String] = []
var _heat_open: bool = false

var _embers_lbl: Label
var _hero_list: VBoxContainer
var _weapon_box: HBoxContainer
var _heat_panel: PanelContainer
var _heat_grid: GridContainer
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
	back_btn.custom_minimum_size = Vector2(92, 46)
	UiStyles.style_button(back_btn, UiStyles.COL_BORDER, false, 46.0)
	back_btn.pressed.connect(func():
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
		visible = false
		back_requested.emit()
	)
	top_h.add_child(back_btn)

	var title := Label.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "出征备战"
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
	w_lbl.text = "初始武器与神系选择（同系 2/4/6 把激活羁绊；精通 Lv.2 可作通用开局武器）："
	w_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	w_lbl.add_theme_font_size_override("font_size", 15)
	w_lbl.add_theme_color_override("font_color", UiStyles.COL_TEXT_DIM)
	root_v.add_child(w_lbl)

	var w_scroll := TouchScrollContainer.new()
	w_scroll.custom_minimum_size.y = 84
	w_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_v.add_child(w_scroll)

	_weapon_box = HBoxContainer.new()
	_weapon_box.add_theme_constant_override("separation", 8)
	w_scroll.add_child(_weapon_box)

	# Heat Modifiers Drawer
	_heat_toggle_btn = Button.new()
	UiStyles.style_button(_heat_toggle_btn, UiStyles.COL_VOID, false, 46.0)
	_heat_toggle_btn.pressed.connect(func():
		_heat_open = not _heat_open
		_heat_panel.visible = _heat_open
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
	)
	root_v.add_child(_heat_toggle_btn)

	_heat_panel = PanelContainer.new()
	_heat_panel.visible = false
	_heat_panel.add_theme_stylebox_override("panel", UiStyles.make_panel_style(UiStyles.COL_CARD, UiStyles.COL_VOID, 12, 2))
	root_v.add_child(_heat_panel)

	_heat_grid = GridContainer.new()
	_heat_grid.columns = 2
	_heat_grid.add_theme_constant_override("h_separation", 8)
	_heat_grid.add_theme_constant_override("v_separation", 8)
	_heat_panel.add_child(_heat_grid)

	# Launch Button
	_start_btn = Button.new()
	_start_btn.text = "立即开始第 1 波"
	UiStyles.style_button(_start_btn, UiStyles.COL_CRIMSON, true, 60.0)
	_start_btn.pressed.connect(func():
		if not SaveManager.is_hero_unlocked(_selected_hero):
			return
		SaveManager.set_selected_heats(_selected_heats)
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
		visible = false
		launch_run_requested.emit(_selected_hero, _selected_weapon, _selected_heats)
	)
	root_v.add_child(_start_btn)


func open() -> void:
	_selected_heats = SaveManager.get_selected_heats()
	if _selected_weapon.is_empty():
		_selected_weapon = String(GameData.get_hero(_selected_hero).get("default_weapon", "wpn_chainsaw"))
	refresh_ui()
	visible = true
	UiStyles.animate_pop_in(self)


func refresh_ui() -> void:
	_embers_lbl.text = "余烬 %d" % SaveManager.get_embers()
	for c in _hero_list.get_children():
		c.queue_free()

	for h in GameData.heroes:
		var hid := String(h["id"])
		var unlocked := SaveManager.is_hero_unlocked(hid)
		var is_sel := (hid == _selected_hero)
		var hcol := Color(h.get("color", UiStyles.COL_CRIMSON))

		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UiStyles.make_panel_style(UiStyles.COL_CARD, UiStyles.COL_GOLD if is_sel else (hcol if unlocked else Color(0.28, 0.24, 0.34)), 14, 3 if is_sel else 2))
		_hero_list.add_child(card)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		card.add_child(hbox)

		var icon := TextureRect.new()
		icon.texture = load(String(h["sprite"]))
		icon.custom_minimum_size = Vector2(88, 88)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if not unlocked:
			icon.modulate = Color(0.35, 0.35, 0.4, 0.8)
		hbox.add_child(icon)

		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_theme_constant_override("separation", 4)
		hbox.add_child(tv)

		var nl := Label.new()
		nl.text = "%s · %s" % [String(h["name"]), String(h["title"])]
		nl.add_theme_font_size_override("font_size", 20)
		nl.add_theme_color_override("font_color", hcol if unlocked else Color(0.6, 0.6, 0.68))
		tv.add_child(nl)

		var dl := Label.new()
		dl.text = String(h["passive_desc"]) if unlocked else String(h["unlock_desc"])
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dl.add_theme_font_size_override("font_size", 14)
		dl.add_theme_color_override("font_color", Color.WHITE if unlocked else UiStyles.COL_GOLD)
		tv.add_child(dl)

		if unlocked:
			var sel_btn := Button.new()
			sel_btn.text = "已选择" if is_sel else "选用"
			sel_btn.custom_minimum_size = Vector2(88, 52)
			UiStyles.style_button(sel_btn, UiStyles.COL_GOLD if is_sel else hcol, is_sel, 52.0)
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
			unl_btn.text = "解禁\n%d" % cost
			unl_btn.custom_minimum_size = Vector2(88, 56)
			unl_btn.disabled = SaveManager.get_embers() < cost
			UiStyles.style_button(unl_btn, UiStyles.COL_GOLD, true, 56.0)
			unl_btn.pressed.connect(func():
				if SaveManager.unlock_hero(hid, true):
					_selected_hero = hid
					_selected_weapon = String(h["default_weapon"])
					EventBus.sfx_requested.emit("sfx_awakening", 0.0)
					refresh_ui()
			)
			hbox.add_child(unl_btn)

	_rebuild_weapon_bar()
	_rebuild_heats()
	_start_btn.disabled = not SaveManager.is_hero_unlocked(_selected_hero)


func _rebuild_weapon_bar() -> void:
	for c in _weapon_box.get_children():
		c.queue_free()
	var def_w := String(GameData.get_hero(_selected_hero).get("default_weapon", "wpn_chainsaw"))
	for w in GameData.weapons:
		var wid := String(w["id"])
		var m_lv := SaveManager.get_weapon_mastery_level(wid)
		if wid != def_w and m_lv < 2:
			continue
		var is_sel := (_selected_weapon == wid)
		var fac_n := UiStyles.faction_name(String(w["faction"]))
		var btn := Button.new()
		btn.text = "%s\n%s系%s" % [String(w["name"]), fac_n, "·专属" if wid == def_w else ""]
		btn.custom_minimum_size = Vector2(156, 62)
		UiStyles.style_button(btn, UiStyles.faction_color(String(w["faction"])), is_sel, 62.0)
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(func():
			_selected_weapon = wid
			EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
			_rebuild_weapon_bar()
		)
		_weapon_box.add_child(btn)


func _rebuild_heats() -> void:
	_heat_toggle_btn.text = "深渊热度词缀：已开启 %d / 8 (余烬 +%d%%)" % [_selected_heats.size(), _selected_heats.size() * 25]
	for c in _heat_grid.get_children():
		c.queue_free()
	for ht in GameData.heats:
		var htid := String(ht["id"])
		var chk := CheckButton.new()
		chk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chk.text = "%s\n(%s)" % [String(ht["name"]), String(ht["desc"])]
		chk.button_pressed = _selected_heats.has(htid)
		chk.add_theme_font_size_override("font_size", 13)
		chk.toggled.connect(func(on: bool):
			if on and not _selected_heats.has(htid):
				_selected_heats.append(htid)
			elif not on:
				_selected_heats.erase(htid)
			_heat_toggle_btn.text = "深渊热度词缀：已开启 %d / 8 (余烬 +%d%%)" % [_selected_heats.size(), _selected_heats.size() * 25]
		)
		_heat_grid.add_child(chk)
