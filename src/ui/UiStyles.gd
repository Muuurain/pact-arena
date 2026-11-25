class_name UiStyles
extends RefCounted
## Shared style factory for dark-neon roguelite panels, tier borders, and mobile touch targets.

const COL_BG := Color(0.05, 0.04, 0.09, 1.0)
const COL_PANEL := Color(0.10, 0.08, 0.16, 0.94)
const COL_CARD := Color(0.13, 0.10, 0.21, 0.96)
const COL_BORDER := Color(0.32, 0.22, 0.45, 0.9)
const COL_CRIMSON := Color(0.96, 0.25, 0.37, 1.0)
const COL_AZURE := Color(0.22, 0.74, 0.97, 1.0)
const COL_VOID := Color(0.75, 0.52, 0.99, 1.0)
const COL_GOLD := Color(0.98, 0.80, 0.08, 1.0)
const COL_EMERALD := Color(0.20, 0.83, 0.60, 1.0)
const COL_TEXT_DIM := Color(0.72, 0.68, 0.80, 1.0)


static func tier_color(tier: int) -> Color:
	match tier:
		2: return COL_AZURE
		3: return COL_VOID
		4: return COL_CRIMSON
		_: return Color(0.78, 0.82, 0.88, 1.0)


static func tier_name(tier: int) -> String:
	match tier:
		2: return "稀有"
		3: return "史诗"
		4: return "觉醒红"
		_: return "普通"


static func faction_color(faction: String) -> Color:
	match faction:
		"crimson": return COL_CRIMSON
		"azure": return COL_AZURE
		"void": return COL_VOID
		_: return Color.WHITE


static func faction_name(faction: String) -> String:
	match faction:
		"crimson": return "猩红"
		"azure": return "苍蓝"
		"void": return "虚空"
		_: return "通用"


static func make_panel_style(bg: Color = COL_CARD, border: Color = COL_BORDER, radius: int = 16, border_w: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.shadow_color = Color(0.02, 0.01, 0.05, 0.42)
	sb.shadow_size = 7
	sb.shadow_offset = Vector2(0, 3)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb


static func style_button(btn: Button, accent: Color = COL_CRIMSON, filled: bool = true, min_h: float = 54.0) -> void:
	btn.custom_minimum_size.y = min_h
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(0.48, 0.48, 0.56))

	var normal := make_panel_style(
		Color(accent.r * 0.46, accent.g * 0.46, accent.b * 0.46, 0.96) if filled else Color(0.11, 0.08, 0.18, 0.95),
		accent,
		14,
		2
	)
	normal.shadow_size = 6 if filled else 3
	var hover := make_panel_style(
		Color(accent.r * 0.62, accent.g * 0.62, accent.b * 0.62, 1.0) if filled else Color(0.17, 0.13, 0.27, 1.0),
		accent.lightened(0.28),
		14,
		2
	)
	var pressed := make_panel_style(
		Color(accent.r * 0.34, accent.g * 0.34, accent.b * 0.34, 1.0),
		Color.WHITE,
		14,
		2
	)
	pressed.shadow_size = 1
	var disabled := make_panel_style(Color(0.11, 0.10, 0.15, 0.72), Color(0.26, 0.24, 0.32, 0.6), 14, 1)
	disabled.shadow_size = 0

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)
	_attach_touch_bounce(btn)


static func _attach_touch_bounce(btn: Button) -> void:
	if btn.get_meta("_bounce_bound", false):
		return
	btn.set_meta("_bounce_bound", true)
	btn.resized.connect(func(): btn.pivot_offset = btn.size * 0.5)
	btn.button_down.connect(func():
		if btn.disabled:
			return
		btn.pivot_offset = btn.size * 0.5
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	var restore := func():
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2.ONE, 0.11).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	btn.button_up.connect(restore)
	btn.mouse_exited.connect(restore)


static func make_centered_modal_shell(host: Control, width: float = 620.0, accent: Color = COL_VOID, z_idx: int = 95) -> Dictionary:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	overlay.z_index = z_idx
	host.add_child(overlay)

	var dim := Button.new()
	dim.flat = true
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim_sb := StyleBoxFlat.new()
	dim_sb.bg_color = Color(0.02, 0.01, 0.05, 0.80)
	dim.add_theme_stylebox_override("normal", dim_sb)
	dim.add_theme_stylebox_override("hover", dim_sb)
	dim.add_theme_stylebox_override("pressed", dim_sb)
	dim.pressed.connect(func():
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
		overlay.visible = false
	)
	overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, 0)
	panel.add_theme_stylebox_override("panel", make_panel_style(Color(0.10, 0.07, 0.18, 0.98), accent, 20, 3))
	center.add_child(panel)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	panel.add_child(body)

	return {"overlay": overlay, "panel": panel, "body": body}


static func show_detail_modal(host: Control, opts: Dictionary) -> void:
	if host == null:
		return
	var existing := host.get_node_or_null("_DetailModalOverlay")
	if existing != null:
		existing.queue_free()

	var accent: Color = opts.get("accent", COL_GOLD)
	var overlay := Control.new()
	overlay.name = "_DetailModalOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 120
	host.add_child(overlay)

	var dim := Button.new()
	dim.flat = true
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim_bg := StyleBoxFlat.new()
	dim_bg.bg_color = Color(0.02, 0.01, 0.05, 0.80)
	dim.add_theme_stylebox_override("normal", dim_bg)
	dim.add_theme_stylebox_override("hover", dim_bg)
	dim.add_theme_stylebox_override("pressed", dim_bg)
	overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(610, 0)
	card.add_theme_stylebox_override("panel", make_panel_style(Color(0.11, 0.08, 0.19, 0.98), accent, 20, 3))
	center.add_child(card)

	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 14)
	card.add_child(cv)

	var top_h := HBoxContainer.new()
	top_h.add_theme_constant_override("separation", 14)
	cv.add_child(top_h)

	var icon_path := String(opts.get("icon_path", ""))
	if not icon_path.is_empty():
		var icon_wrap := PanelContainer.new()
		icon_wrap.custom_minimum_size = Vector2(106, 106)
		icon_wrap.add_theme_stylebox_override("panel", make_panel_style(Color(0.07, 0.05, 0.13, 0.96), accent, 16, 2))
		top_h.add_child(icon_wrap)

		var ic := TextureRect.new()
		ic.texture = load(icon_path)
		ic.custom_minimum_size = Vector2(88, 88)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.modulate = opts.get("icon_modulate", Color.WHITE)
		icon_wrap.add_child(ic)

	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	tv.add_theme_constant_override("separation", 6)
	top_h.add_child(tv)

	var tl := Label.new()
	tl.text = String(opts.get("title", ""))
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tl.add_theme_font_size_override("font_size", 25)
	tl.add_theme_color_override("font_color", accent)
	tv.add_child(tl)

	var sub := String(opts.get("subtitle", ""))
	if not sub.is_empty():
		var sl := Label.new()
		sl.text = sub
		sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sl.add_theme_font_size_override("font_size", 16)
		sl.add_theme_color_override("font_color", COL_TEXT_DIM)
		tv.add_child(sl)

	var body_scroll := TouchScrollContainer.new()
	body_scroll.custom_minimum_size = Vector2(0, 220)
	cv.add_child(body_scroll)

	var bl := Label.new()
	bl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bl.text = String(opts.get("body", ""))
	bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bl.add_theme_font_size_override("font_size", 18)
	bl.add_theme_color_override("font_color", Color.WHITE)
	body_scroll.add_child(bl)

	var close_btn := Button.new()
	close_btn.text = "知道了"
	style_button(close_btn, accent, true, 56.0)
	cv.add_child(close_btn)

	var close_fn := func():
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
		overlay.queue_free()
	dim.pressed.connect(close_fn)
	close_btn.pressed.connect(close_fn)
	animate_pop_in(card)


static func apply_safe_area_padding(ctrl: Control, base_top: float = 12.0, base_bottom: float = 12.0) -> void:
	var safe := DisplayServer.get_display_safe_area()
	var win := DisplayServer.window_get_size()
	var top_pad := base_top
	var bot_pad := base_bottom
	if win.y > 0 and safe.size.y > 0:
		var scale_y := 1280.0 / float(win.y)
		top_pad = maxf(base_top, float(safe.position.y) * scale_y + 6.0)
		var bottom_cut := float(win.y - (safe.position.y + safe.size.y))
		bot_pad = maxf(base_bottom, bottom_cut * scale_y + 8.0)
	ctrl.offset_top = top_pad
	ctrl.offset_bottom = -bot_pad


static func animate_pop_in(ctrl: Control) -> void:
	ctrl.modulate.a = 0.0
	ctrl.pivot_offset = ctrl.size * 0.5
	ctrl.scale = Vector2(0.96, 0.96)
	var tw := ctrl.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ctrl, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(ctrl, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


static func make_android_nav_tile(icon_path: String, title_txt: String, sub_txt: String, accent: Color, on_press: Callable) -> Button:
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 128)
	btn.text = ""
	style_button(btn, accent, false, 128.0)

	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 5)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vb)

	var ic := TextureRect.new()
	ic.texture = load(icon_path)
	ic.custom_minimum_size = Vector2(66, 66)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(ic)

	var tl := Label.new()
	tl.text = title_txt
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tl.add_theme_font_size_override("font_size", 19)
	tl.add_theme_color_override("font_color", Color.WHITE)
	vb.add_child(tl)

	var sl := Label.new()
	sl.text = sub_txt
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sl.add_theme_font_size_override("font_size", 13)
	sl.add_theme_color_override("font_color", accent.lightened(0.25))
	vb.add_child(sl)

	btn.pressed.connect(on_press)
	return btn


static func populate_synergy_details(container: Control, synergy_info: Dictionary = {}, show_progress: bool = false) -> void:
	for c in container.get_children():
		c.queue_free()

	var counts: Dictionary = synergy_info.get("effective_counts", {})
	var flags: Dictionary = synergy_info.get("flags", {})

	var fac_hdr := Label.new()
	fac_hdr.text = "【三大神系羁绊（同系武器 2 / 4 / 6 把激活；苍蓝魔导所需 -1）】"
	fac_hdr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fac_hdr.add_theme_font_size_override("font_size", 15)
	fac_hdr.add_theme_color_override("font_color", COL_AZURE)
	container.add_child(fac_hdr)

	for f in SynergyEngine.FACTIONS:
		var meta: Dictionary = SynergyEngine.FACTION_META[f]
		var fcol: Color = meta["color"]
		var cnt: int = int(counts.get(f, 0))
		var any_active: bool = (not show_progress) or (cnt >= 2)

		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", make_panel_style(COL_CARD, fcol if any_active else COL_BORDER, 12, 2 if any_active else 1))
		container.add_child(card)

		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 4)
		card.add_child(cv)

		var tl := Label.new()
		tl.text = "%s系羁绊" % String(meta["name"]) + (" · 当前 %d 把" % cnt if show_progress else "")
		tl.add_theme_font_size_override("font_size", 17)
		tl.add_theme_color_override("font_color", fcol)
		cv.add_child(tl)

		for tier in [2, 4, 6]:
			var reached: bool = show_progress and (cnt >= int(tier))
			var prefix: String = ("✓ %d件：" % tier) if reached else ("%d件：" % tier)
			var dl := Label.new()
			dl.text = prefix + String(meta["desc_%d" % tier])
			dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			dl.add_theme_font_size_override("font_size", 14)
			dl.add_theme_color_override("font_color", COL_GOLD if reached else (Color.WHITE if not show_progress else COL_TEXT_DIM))
			cv.add_child(dl)

	var res_hdr := Label.new()
	res_hdr.text = "【跨系双神融合共鸣（任意两系均达 2 阶自动激活）】"
	res_hdr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	res_hdr.add_theme_font_size_override("font_size", 15)
	res_hdr.add_theme_color_override("font_color", COL_GOLD)
	container.add_child(res_hdr)

	for r in SynergyEngine.get_all_resonances():
		var rid := String(r["id"])
		var active: bool = show_progress and bool(flags.get(rid, false))
		var rcard := PanelContainer.new()
		rcard.add_theme_stylebox_override("panel", make_panel_style(COL_CARD, COL_GOLD if active else (COL_VOID if not show_progress else COL_BORDER), 12, 2 if (active or not show_progress) else 1))
		container.add_child(rcard)

		var rl := Label.new()
		var badge := "✓ [已激活] " if active else ""
		rl.text = "%s【%s】%s" % [badge, String(r["name"]), String(r["desc"])]
		rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rl.add_theme_font_size_override("font_size", 14)
		rl.add_theme_color_override("font_color", COL_GOLD if active else (Color.WHITE if not show_progress else COL_TEXT_DIM))
		rcard.add_child(rl)
