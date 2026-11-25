class_name CodexScreen
extends Control
## Weapon Mastery catalog (14 weapons, Lv.1-5 kills, Red Awakenings) and
## Shop Ban Slot configuration (powered by Sanctuary's 流派净化槽 talent).

signal back_requested()

var _ban_info_lbl: Label
var _list_box: VBoxContainer
var _synergy_modal: Control
var _synergy_panel: PanelContainer


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
	title.text = "深渊图鉴"
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

	var sm := UiStyles.make_centered_modal_shell(self, 640.0, UiStyles.COL_VOID, 95)
	_synergy_modal = sm["overlay"]
	_synergy_panel = sm["panel"]
	var syn_v: VBoxContainer = sm["body"]

	var syn_title := Label.new()
	syn_title.text = "神系羁绊与双神共鸣"
	syn_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	syn_title.add_theme_font_size_override("font_size", 24)
	syn_title.add_theme_color_override("font_color", UiStyles.COL_VOID)
	syn_v.add_child(syn_title)

	var syn_scroll := TouchScrollContainer.new()
	syn_scroll.custom_minimum_size = Vector2(0, 520)
	syn_v.add_child(syn_scroll)

	var syn_box := VBoxContainer.new()
	syn_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	syn_box.add_theme_constant_override("separation", 10)
	syn_scroll.add_child(syn_box)
	UiStyles.populate_synergy_details(syn_box, {}, false)

	var syn_close := Button.new()
	syn_close.text = "关闭"
	UiStyles.style_button(syn_close, UiStyles.COL_VOID, true, 54.0)
	syn_close.pressed.connect(func():
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
		_synergy_modal.visible = false
	)
	syn_v.add_child(syn_close)


func open() -> void:
	_synergy_modal.visible = false
	refresh_ui()
	visible = true
	UiStyles.animate_pop_in(self)


func refresh_ui() -> void:
	var max_bans := SaveManager.get_max_ban_slots()
	var bans := SaveManager.get_ban_list()
	_ban_info_lbl.text = "禁选: %d/%d" % [bans.size(), max_bans]

	for c in _list_box.get_children():
		_list_box.remove_child(c)
		c.queue_free()

	var syn_btn := Button.new()
	syn_btn.text = "查看神系羁绊与双神共鸣总览 ›"
	UiStyles.style_button(syn_btn, UiStyles.COL_VOID, false, 54.0)
	_list_box.add_child(syn_btn)

	syn_btn.pressed.connect(func():
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
		_synergy_modal.visible = true
		UiStyles.animate_pop_in(_synergy_panel)
	)

	var wh := Label.new()
	wh.text = "武装图鉴（14 把 · 精通 Lv.2 起全职业可带 · 点击看详情）"
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
		card.add_theme_stylebox_override("panel", UiStyles.make_panel_style(UiStyles.COL_CARD, Color(0.45, 0.25, 0.25) if is_banned else fcol, 14, 2))
		_list_box.add_child(card)

		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		card.add_child(h)

		var inspect_btn := Button.new()
		inspect_btn.flat = true
		inspect_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inspect_btn.custom_minimum_size.y = 84
		h.add_child(inspect_btn)

		var row := HBoxContainer.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.add_theme_constant_override("separation", 12)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inspect_btn.add_child(row)

		var icon := TextureRect.new()
		icon.texture = load(String(w["sprite"]))
		icon.custom_minimum_size = Vector2(80, 80)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)

		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.alignment = BoxContainer.ALIGNMENT_CENTER
		tv.add_theme_constant_override("separation", 4)
		tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(tv)

		var nl := Label.new()
		nl.text = "%s · %s系" % [String(w["name"]), UiStyles.faction_name(String(w["faction"]))]
		nl.add_theme_font_size_override("font_size", 19)
		nl.add_theme_color_override("font_color", fcol)
		tv.add_child(nl)

		var sub_l := Label.new()
		sub_l.text = "精通 Lv.%d (%d/%d 杀) · 点按看参数与觉醒 ›" % [lv, kills, next_req]
		sub_l.add_theme_font_size_override("font_size", 14)
		sub_l.add_theme_color_override("font_color", UiStyles.COL_TEXT_DIM)
		tv.add_child(sub_l)

		var w_copy := (w as Dictionary).duplicate(true)
		inspect_btn.pressed.connect(func():
			EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
			var awks: Array = w_copy.get("awakenings", [])
			var awk_lines := ""
			if awks.size() >= 2:
				awk_lines = "\n\n【四阶红武双觉醒分支】\n• %s：%s\n• %s：%s" % [
					String(awks[0]["name"]), String(awks[0]["desc"]),
					String(awks[1]["name"]), String(awks[1]["desc"]),
				]
			var body := "武器特点：%s\n\n基础伤害：%.0f   |   冷却：%.2fs\n攻击距离：%.0f   |   暴击加成：+%.0f%%\n精通进度：Lv.%d（%d / %d 击杀，Lv.2 解锁全英雄携带）%s" % [
				String(w_copy["desc"]),
				float(w_copy["base_damage"]), float(w_copy["base_cooldown"]),
				float(w_copy["base_range"]), float(w_copy["crit_bonus"]),
				lv, kills, next_req, awk_lines
			]
			UiStyles.show_detail_modal(self, {
				"title": String(w_copy["name"]),
				"subtitle": "%s神系 · %s武器" % [UiStyles.faction_name(String(w_copy["faction"])), "近战" if String(w_copy["weapon_class"]) == "melee" else ("召唤" if String(w_copy["weapon_class"]) == "summon" else "远程/法术")],
				"body": body,
				"accent": fcol,
				"icon_path": String(w_copy["sprite"]),
			})
		)

		if max_bans > 0:
			var bbtn := Button.new()
			bbtn.text = "已屏蔽" if is_banned else "屏蔽"
			bbtn.custom_minimum_size = Vector2(84, 52)
			bbtn.disabled = (not is_banned and bans.size() >= max_bans)
			UiStyles.style_button(bbtn, UiStyles.COL_CRIMSON if is_banned else UiStyles.COL_BORDER, is_banned, 52.0)
			bbtn.pressed.connect(func():
				SaveManager.toggle_ban_entry(wid)
				EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
				refresh_ui()
			)
			h.add_child(bbtn)

	var ih := Label.new()
	ih.text = "道具图鉴（18 种 · 点击查看详细属性）"
	ih.add_theme_font_size_override("font_size", 16)
	ih.add_theme_color_override("font_color", UiStyles.COL_GOLD)
	_list_box.add_child(ih)

	for it in GameData.items:
		var iid := String(it["id"])
		var is_banned := bans.has(iid)
		var itcol := UiStyles.tier_color(int(it["tier"]))
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UiStyles.make_panel_style(UiStyles.COL_CARD, Color(0.45, 0.25, 0.25) if is_banned else itcol, 14, 1))
		_list_box.add_child(card)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		card.add_child(h)

		var inspect_btn := Button.new()
		inspect_btn.flat = true
		inspect_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inspect_btn.custom_minimum_size.y = 76
		h.add_child(inspect_btn)

		var row := HBoxContainer.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.add_theme_constant_override("separation", 12)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inspect_btn.add_child(row)

		var icon := TextureRect.new()
		icon.texture = load(String(it.get("sprite", "")))
		icon.custom_minimum_size = Vector2(72, 72)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)

		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.alignment = BoxContainer.ALIGNMENT_CENTER
		tv.add_theme_constant_override("separation", 4)
		tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(tv)

		var nl := Label.new()
		nl.text = "%s · %s" % [String(it["name"]), UiStyles.tier_name(int(it["tier"]))]
		nl.add_theme_font_size_override("font_size", 18)
		nl.add_theme_color_override("font_color", itcol)
		tv.add_child(nl)

		var hint_l := Label.new()
		hint_l.text = String(it["desc"])
		hint_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint_l.add_theme_font_size_override("font_size", 14)
		hint_l.add_theme_color_override("font_color", UiStyles.COL_TEXT_DIM)
		tv.add_child(hint_l)

		var it_copy := (it as Dictionary).duplicate(true)
		inspect_btn.pressed.connect(func():
			EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
			UiStyles.show_detail_modal(self, {
				"title": String(it_copy["name"]),
				"subtitle": "%s品质 · 基础售价 %d 血晶" % [UiStyles.tier_name(int(it_copy["tier"])), int(it_copy["price"])],
				"body": "效果明细：\n%s\n\n%s" % [String(it_copy["desc"]), "当前已在商店货架屏蔽（不再刷出）" if is_banned else "可在商店与战利宝箱中获取（可叠加）"],
				"accent": itcol,
				"icon_path": String(it_copy.get("sprite", "")),
			})
		)

		if max_bans > 0:
			var bbtn := Button.new()
			bbtn.text = "已屏蔽" if is_banned else "屏蔽"
			bbtn.custom_minimum_size = Vector2(84, 50)
			bbtn.disabled = (not is_banned and bans.size() >= max_bans)
			UiStyles.style_button(bbtn, UiStyles.COL_CRIMSON if is_banned else UiStyles.COL_BORDER, is_banned, 50.0)
			bbtn.pressed.connect(func():
				SaveManager.toggle_ban_entry(iid)
				EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
				refresh_ui()
			)
			h.add_child(bbtn)
