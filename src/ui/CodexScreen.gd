class_name CodexScreen
extends Control
## Weapon Mastery catalog (14 weapons, Lv.1-5 kills, Red Awakenings) and
## Shop Ban Slot configuration (powered by Sanctuary's 流派净化槽 talent).

signal back_requested()

var _ban_info_lbl: Label
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
	v.add_theme_constant_override("separation", 10)
	safe.add_child(v)

	var top_h := HBoxContainer.new()
	v.add_child(top_h)

	var back_btn := Button.new()
	back_btn.text = "返回"
	back_btn.custom_minimum_size = Vector2(90, 48)
	UiStyles.style_button(back_btn, UiStyles.COL_BORDER, false, 48.0)
	back_btn.pressed.connect(func():
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
		visible = false
		back_requested.emit()
	)
	top_h.add_child(back_btn)

	var title := Label.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "武器图鉴 & 禁用"
	title.add_theme_font_size_override("font_size", 26)
	top_h.add_child(title)

	_ban_info_lbl = Label.new()
	_ban_info_lbl.add_theme_font_size_override("font_size", 17)
	_ban_info_lbl.add_theme_color_override("font_color", UiStyles.COL_GOLD)
	top_h.add_child(_ban_info_lbl)

	var scroll := TouchScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(scroll)

	_list_box = VBoxContainer.new()
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_box.add_theme_constant_override("separation", 10)
	scroll.add_child(_list_box)


func open() -> void:
	refresh_ui()
	visible = true
	UiStyles.animate_pop_in(self)


func refresh_ui() -> void:
	var max_bans := SaveManager.get_max_ban_slots()
	var bans := SaveManager.get_ban_list()
	_ban_info_lbl.text = "禁用槽: %d/%d" % [bans.size(), max_bans]

	for c in _list_box.get_children():
		c.queue_free()

	var syn_box := VBoxContainer.new()
	syn_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	syn_box.add_theme_constant_override("separation", 8)
	_list_box.add_child(syn_box)
	UiStyles.populate_synergy_details(syn_box, {}, false)

	var wh := Label.new()
	wh.text = "【14把武装精通与四阶双路线觉醒】(Lv.2 可作为任意英雄开局武器)"
	wh.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wh.add_theme_font_size_override("font_size", 16)
	wh.add_theme_color_override("font_color", UiStyles.COL_AZURE)
	_list_box.add_child(wh)

	for w in GameData.weapons:
		var wid := String(w["id"])
		var fcol := UiStyles.faction_color(String(w["faction"]))
		var kills := SaveManager.get_weapon_kills(wid)
		var lv := SaveManager.get_weapon_mastery_level(wid)
		var next_req := SaveManager.get_weapon_next_threshold(lv)
		var is_banned := bans.has(wid)

		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UiStyles.make_panel_style(UiStyles.COL_CARD, Color(0.45, 0.25, 0.25) if is_banned else fcol, 12, 2))
		_list_box.add_child(card)

		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		card.add_child(h)

		var icon := TextureRect.new()
		icon.texture = load(String(w["sprite"]))
		icon.custom_minimum_size = Vector2(72, 72)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.add_child(icon)

		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(tv)

		var nl := Label.new()
		nl.text = "%s [%s] · 精通 Lv.%d (%d/%d杀)" % [String(w["name"]), UiStyles.faction_name(String(w["faction"])), lv, kills, next_req]
		nl.add_theme_font_size_override("font_size", 17)
		nl.add_theme_color_override("font_color", fcol)
		tv.add_child(nl)

		var awks: Array = w.get("awakenings", [])
		var awk_txt := ""
		if awks.size() >= 2:
			awk_txt = "觉醒A:%s | 觉醒B:%s" % [String(awks[0]["name"]), String(awks[1]["name"])]
		var dl := Label.new()
		dl.text = String(w["desc"]) + "\n" + awk_txt
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dl.add_theme_font_size_override("font_size", 13)
		dl.add_theme_color_override("font_color", UiStyles.COL_TEXT_DIM)
		tv.add_child(dl)

		if max_bans > 0:
			var bbtn := Button.new()
			bbtn.text = "已禁用" if is_banned else "禁用"
			bbtn.custom_minimum_size = Vector2(78, 46)
			bbtn.disabled = (not is_banned and bans.size() >= max_bans)
			UiStyles.style_button(bbtn, UiStyles.COL_CRIMSON if is_banned else UiStyles.COL_BORDER, is_banned, 46.0)
			bbtn.pressed.connect(func():
				SaveManager.toggle_ban_entry(wid)
				EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
				refresh_ui()
			)
			h.add_child(bbtn)

	var ih := Label.new()
	ih.text = "【18种商店道具图鉴】"
	ih.add_theme_font_size_override("font_size", 16)
	ih.add_theme_color_override("font_color", UiStyles.COL_GOLD)
	_list_box.add_child(ih)

	for it in GameData.items:
		var iid := String(it["id"])
		var is_banned := bans.has(iid)
		var itcol := UiStyles.tier_color(int(it["tier"]))
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UiStyles.make_panel_style(UiStyles.COL_CARD, Color(0.45, 0.25, 0.25) if is_banned else itcol, 12, 1))
		_list_box.add_child(card)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		card.add_child(h)

		var icon := TextureRect.new()
		icon.texture = load(String(it.get("sprite", "")))
		icon.custom_minimum_size = Vector2(58, 58)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.add_child(icon)

		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(tv)

		var nl := Label.new()
		nl.text = "%s [%s阶]" % [String(it["name"]), UiStyles.tier_name(int(it["tier"]))]
		nl.add_theme_font_size_override("font_size", 16)
		nl.add_theme_color_override("font_color", itcol)
		tv.add_child(nl)

		var l := Label.new()
		l.text = String(it["desc"])
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", 13)
		l.add_theme_color_override("font_color", UiStyles.COL_TEXT_DIM)
		tv.add_child(l)

		if max_bans > 0:
			var bbtn := Button.new()
			bbtn.text = "已禁用" if is_banned else "禁用"
			bbtn.custom_minimum_size = Vector2(74, 40)
			bbtn.disabled = (not is_banned and bans.size() >= max_bans)
			UiStyles.style_button(bbtn, UiStyles.COL_CRIMSON if is_banned else UiStyles.COL_BORDER, is_banned, 40.0)
			bbtn.pressed.connect(func():
				SaveManager.toggle_ban_entry(iid)
				EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
				refresh_ui()
			)
			h.add_child(bbtn)
