class_name BattleHud
extends CanvasLayer
## Mobile-ergonomic combat HUD with Safe Area support, floating joystick,
## crystal-clear Blood Dash cooldown seconds & charge pips, Boss bar, and pause menu.

signal dash_pressed()
signal pause_exit_requested()

var _run: RunState
var _joystick: TouchJoystick
var _vignette: ColorRect

var _wave_lbl: Label
var _timer_lbl: Label
var _kills_lbl: Label
var _crystals_lbl: Label
var _boss_box: VBoxContainer
var _boss_name_lbl: Label
var _boss_bar: ProgressBar

var _hp_bar: ProgressBar
var _hp_lbl: Label
var _xp_bar: ProgressBar
var _lv_lbl: Label
var _synergy_box: HBoxContainer

var _dash_btn: Button
var _dash_sweep: ColorRect
var _dash_icon: TextureRect
var _dash_cd_big_lbl: Label
var _dash_sub_lbl: Label
var _dash_pips: Array[ColorRect] = []
var _prev_charges: int = 2

var _pause_modal: Control
var _pause_panel: PanelContainer
var _pause_synergy_lbl: Label


func _ready() -> void:
	layer = 10
	_build_ui()
	EventBus.player_hp_changed.connect(_on_hp_changed)
	EventBus.player_xp_changed.connect(_on_xp_changed)
	EventBus.player_dash_changed.connect(_on_dash_changed)
	EventBus.crystals_changed.connect(_on_crystals_changed)
	EventBus.wave_progress_changed.connect(_on_wave_changed)
	EventBus.boss_spawned.connect(_on_boss_spawned)
	EventBus.boss_hp_changed.connect(_on_boss_hp_changed)
	EventBus.boss_defeated.connect(_on_boss_defeated)


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	_vignette = ColorRect.new()
	_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vmat := ShaderMaterial.new()
	vmat.shader = load("res://assets/shaders/danger_vignette.gdshader")
	_vignette.material = vmat
	root.add_child(_vignette)

	_joystick = TouchJoystick.new()
	_joystick.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(_joystick)

	var safe_box := Control.new()
	safe_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyles.apply_safe_area_padding(safe_box, 14.0, 18.0)
	root.add_child(safe_box)

	# TOP HUD BAR
	var top_panel := PanelContainer.new()
	top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_panel.offset_left = 14
	top_panel.offset_right = -14
	top_panel.offset_bottom = 94
	top_panel.add_theme_stylebox_override("panel", UiStyles.make_panel_style(Color(0.08, 0.06, 0.14, 0.86), UiStyles.COL_BORDER, 16, 2))
	safe_box.add_child(top_panel)

	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 10)
	top_panel.add_child(top_hbox)

	var left_col := VBoxContainer.new()
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_col.alignment = BoxContainer.ALIGNMENT_CENTER
	top_hbox.add_child(left_col)

	var crys_row := HBoxContainer.new()
	crys_row.add_theme_constant_override("separation", 6)
	left_col.add_child(crys_row)

	var crys_ic := TextureRect.new()
	crys_ic.texture = load("res://assets/art/sprites/pickups/pickup_crystal.png")
	crys_ic.custom_minimum_size = Vector2(34, 34)
	crys_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crys_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crys_row.add_child(crys_ic)

	_crystals_lbl = Label.new()
	_crystals_lbl.text = "20"
	_crystals_lbl.add_theme_font_size_override("font_size", 22)
	_crystals_lbl.add_theme_color_override("font_color", UiStyles.COL_CRIMSON)
	crys_row.add_child(_crystals_lbl)

	_kills_lbl = Label.new()
	_kills_lbl.text = "击杀: 0"
	_kills_lbl.add_theme_font_size_override("font_size", 16)
	_kills_lbl.add_theme_color_override("font_color", UiStyles.COL_TEXT_DIM)
	left_col.add_child(_kills_lbl)

	var mid_col := VBoxContainer.new()
	mid_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid_col.alignment = BoxContainer.ALIGNMENT_CENTER
	top_hbox.add_child(mid_col)

	_wave_lbl = Label.new()
	_wave_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_lbl.text = "第 1 波"
	_wave_lbl.add_theme_font_size_override("font_size", 19)
	mid_col.add_child(_wave_lbl)

	_timer_lbl = Label.new()
	_timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_lbl.text = "26s"
	_timer_lbl.add_theme_font_size_override("font_size", 32)
	_timer_lbl.add_theme_color_override("font_color", UiStyles.COL_GOLD)
	mid_col.add_child(_timer_lbl)

	var pause_btn := Button.new()
	pause_btn.text = "暂停"
	pause_btn.custom_minimum_size = Vector2(102, 58)
	UiStyles.style_button(pause_btn, UiStyles.COL_BORDER, false, 58.0)
	pause_btn.pressed.connect(_toggle_pause)
	top_hbox.add_child(pause_btn)

	# BOSS BAR
	_boss_box = VBoxContainer.new()
	_boss_box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_boss_box.offset_left = 36
	_boss_box.offset_right = -36
	_boss_box.offset_top = 104
	_boss_box.offset_bottom = 154
	_boss_box.visible = false
	_boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_box.add_child(_boss_box)

	_boss_name_lbl = Label.new()
	_boss_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_name_lbl.add_theme_font_size_override("font_size", 21)
	_boss_name_lbl.add_theme_color_override("font_color", UiStyles.COL_CRIMSON)
	_boss_name_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	_boss_name_lbl.add_theme_constant_override("outline_size", 4)
	_boss_box.add_child(_boss_name_lbl)

	_boss_bar = ProgressBar.new()
	_boss_bar.custom_minimum_size.y = 20
	_boss_bar.show_percentage = false
	_style_progress(_boss_bar, UiStyles.COL_CRIMSON)
	_boss_box.add_child(_boss_bar)

	# BOTTOM STATUS + BLOOD DASH SKILL PAD
	var bot_hbox := HBoxContainer.new()
	bot_hbox.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bot_hbox.offset_left = 14
	bot_hbox.offset_right = -14
	bot_hbox.offset_top = -170
	bot_hbox.offset_bottom = -8
	bot_hbox.add_theme_constant_override("separation", 12)
	bot_hbox.alignment = BoxContainer.ALIGNMENT_END
	bot_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_box.add_child(bot_hbox)

	var bars_panel := PanelContainer.new()
	bars_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bars_panel.size_flags_vertical = Control.SIZE_SHRINK_END
	bars_panel.add_theme_stylebox_override("panel", UiStyles.make_panel_style(Color(0.08, 0.06, 0.14, 0.88), UiStyles.COL_BORDER, 16, 2))
	bot_hbox.add_child(bars_panel)

	var bars_v := VBoxContainer.new()
	bars_v.add_theme_constant_override("separation", 6)
	bars_panel.add_child(bars_v)

	var hp_row := HBoxContainer.new()
	bars_v.add_child(hp_row)
	_hp_lbl = Label.new()
	_hp_lbl.text = "HP 45 / 45"
	_hp_lbl.add_theme_font_size_override("font_size", 19)
	hp_row.add_child(_hp_lbl)
	_lv_lbl = Label.new()
	_lv_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lv_lbl.text = "Lv.1"
	_lv_lbl.add_theme_font_size_override("font_size", 19)
	_lv_lbl.add_theme_color_override("font_color", UiStyles.COL_AZURE)
	hp_row.add_child(_lv_lbl)

	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size.y = 22
	_hp_bar.show_percentage = false
	_style_progress(_hp_bar, UiStyles.COL_CRIMSON)
	bars_v.add_child(_hp_bar)

	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size.y = 10
	_xp_bar.show_percentage = false
	_style_progress(_xp_bar, UiStyles.COL_AZURE)
	bars_v.add_child(_xp_bar)

	_synergy_box = HBoxContainer.new()
	_synergy_box.add_theme_constant_override("separation", 8)
	_synergy_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars_v.add_child(_synergy_box)

	# ANDROID ERGONOMIC BLOOD DASH SKILL PAD WITH LIVE COOLDOWN SECONDS
	var dash_wrap := VBoxContainer.new()
	dash_wrap.custom_minimum_size = Vector2(144, 156)
	dash_wrap.add_theme_constant_override("separation", 6)
	bot_hbox.add_child(dash_wrap)

	_dash_btn = Button.new()
	_dash_btn.custom_minimum_size = Vector2(144, 136)
	_dash_btn.pivot_offset = Vector2(72, 68)
	_dash_btn.text = ""
	_dash_btn.clip_contents = true
	UiStyles.style_button(_dash_btn, UiStyles.COL_CRIMSON, true, 136.0)
	_dash_btn.pressed.connect(func(): dash_pressed.emit())
	dash_wrap.add_child(_dash_btn)

	# Cooldown progress fill bar sweeping upward from bottom inside button
	_dash_sweep = ColorRect.new()
	_dash_sweep.color = Color(0.98, 0.72, 0.16, 0.28)
	_dash_sweep.anchor_left = 0.0
	_dash_sweep.anchor_right = 1.0
	_dash_sweep.anchor_top = 0.0
	_dash_sweep.anchor_bottom = 1.0
	_dash_sweep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dash_btn.add_child(_dash_sweep)

	var dash_inner := VBoxContainer.new()
	dash_inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dash_inner.alignment = BoxContainer.ALIGNMENT_CENTER
	dash_inner.add_theme_constant_override("separation", 2)
	dash_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dash_btn.add_child(dash_inner)

	var icon_box := Control.new()
	icon_box.custom_minimum_size = Vector2(68, 68)
	icon_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dash_inner.add_child(icon_box)

	_dash_icon = TextureRect.new()
	_dash_icon.texture = load("res://assets/art/ui/icon_dash.png")
	_dash_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dash_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dash_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_dash_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_box.add_child(_dash_icon)

	_dash_cd_big_lbl = Label.new()
	_dash_cd_big_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dash_cd_big_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dash_cd_big_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_dash_cd_big_lbl.add_theme_font_size_override("font_size", 28)
	_dash_cd_big_lbl.add_theme_color_override("font_color", Color.WHITE)
	_dash_cd_big_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	_dash_cd_big_lbl.add_theme_constant_override("outline_size", 6)
	_dash_cd_big_lbl.visible = false
	icon_box.add_child(_dash_cd_big_lbl)

	_dash_sub_lbl = Label.new()
	_dash_sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dash_sub_lbl.text = "血步 · 2/2"
	_dash_sub_lbl.add_theme_font_size_override("font_size", 17)
	_dash_sub_lbl.add_theme_color_override("font_color", UiStyles.COL_GOLD)
	_dash_sub_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	_dash_sub_lbl.add_theme_constant_override("outline_size", 4)
	dash_inner.add_child(_dash_sub_lbl)

	# Discrete charge pips row beneath skill button
	var pips_row := HBoxContainer.new()
	pips_row.add_theme_constant_override("separation", 6)
	dash_wrap.add_child(pips_row)
	_dash_pips.clear()
	for _p in range(2):
		var pip := ColorRect.new()
		pip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pip.custom_minimum_size.y = 10
		pip.color = UiStyles.COL_GOLD
		pips_row.add_child(pip)
		_dash_pips.append(pip)

	_build_pause_modal(root)


func _build_pause_modal(root: Control) -> void:
	_pause_modal = Control.new()
	_pause_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_modal.visible = false
	_pause_modal.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_pause_modal.z_index = 90
	root.add_child(_pause_modal)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.01, 0.05, 0.78)
	_pause_modal.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_modal.add_child(center)

	_pause_panel = PanelContainer.new()
	_pause_panel.custom_minimum_size = Vector2(580, 0)
	_pause_panel.add_theme_stylebox_override("panel", UiStyles.make_panel_style(Color(0.09, 0.07, 0.17, 0.98), UiStyles.COL_CRIMSON, 20, 3))
	center.add_child(_pause_panel)

	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 14)
	_pause_panel.add_child(pv)

	var title := Label.new()
	title.text = "战斗暂停"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	pv.add_child(title)

	var syn_scroll := TouchScrollContainer.new()
	syn_scroll.custom_minimum_size = Vector2(0, 220)
	pv.add_child(syn_scroll)

	_pause_synergy_lbl = Label.new()
	_pause_synergy_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pause_synergy_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pause_synergy_lbl.add_theme_font_size_override("font_size", 17)
	_pause_synergy_lbl.add_theme_color_override("font_color", UiStyles.COL_AZURE)
	syn_scroll.add_child(_pause_synergy_lbl)

	var resume_btn := Button.new()
	resume_btn.text = "继续战斗"
	UiStyles.style_button(resume_btn, UiStyles.COL_EMERALD, true, 58.0)
	resume_btn.pressed.connect(_toggle_pause)
	pv.add_child(resume_btn)

	var shake_chk := CheckButton.new()
	shake_chk.text = "受击震屏"
	shake_chk.custom_minimum_size.y = 52
	shake_chk.add_theme_font_size_override("font_size", 18)
	shake_chk.button_pressed = bool(SaveManager.get_setting("screen_shake", true))
	shake_chk.toggled.connect(func(v: bool): SaveManager.set_setting("screen_shake", v))
	pv.add_child(shake_chk)

	var exit_btn := Button.new()
	exit_btn.text = "返回主菜单（放弃本波进度）"
	UiStyles.style_button(exit_btn, UiStyles.COL_CRIMSON, false, 56.0)
	exit_btn.pressed.connect(func():
		get_tree().paused = false
		_pause_modal.visible = false
		pause_exit_requested.emit()
	)
	pv.add_child(exit_btn)


func bind_run(run: RunState, player: PlayerController) -> void:
	_run = run
	_prev_charges = 2
	_boss_box.visible = false
	if not _joystick.move_vector_changed.is_connected(player.set_touch_move_vector):
		_joystick.move_vector_changed.connect(player.set_touch_move_vector)
	if not dash_pressed.is_connected(player.trigger_dash):
		dash_pressed.connect(player.trigger_dash)
	_refresh_synergy_pills()


func _refresh_synergy_pills() -> void:
	for c in _synergy_box.get_children():
		_synergy_box.remove_child(c)
		c.queue_free()
	if _run == null:
		return
	var counts: Dictionary = _run.synergy_info.get("effective_counts", {})
	for f in SynergyEngine.FACTIONS:
		var n := int(counts.get(f, 0))
		if n <= 0:
			continue
		var stars := "★★★" if n >= 6 else ("★★" if n >= 4 else ("★" if n >= 2 else "/2"))
		var pill := PanelContainer.new()
		var fcol := UiStyles.faction_color(f) if n >= 2 else UiStyles.COL_TEXT_DIM
		var st := UiStyles.make_panel_style(Color(0.10, 0.08, 0.18, 0.85), fcol, 8, 1)
		st.shadow_size = 0
		st.content_margin_left = 7
		st.content_margin_right = 7
		st.content_margin_top = 2
		st.content_margin_bottom = 2
		pill.add_theme_stylebox_override("panel", st)
		pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var lbl := Label.new()
		lbl.text = "%s%d%s" % [UiStyles.faction_name(f), n, stars]
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", fcol)
		pill.add_child(lbl)
		_synergy_box.add_child(pill)
	for r in SynergyEngine.get_active_resonances(_run.synergy_info.get("flags", {})):
		var rpill := PanelContainer.new()
		var rst := UiStyles.make_panel_style(Color(0.18, 0.13, 0.06, 0.90), UiStyles.COL_GOLD, 8, 1)
		rst.shadow_size = 0
		rst.content_margin_left = 7
		rst.content_margin_right = 7
		rst.content_margin_top = 2
		rst.content_margin_bottom = 2
		rpill.add_theme_stylebox_override("panel", rst)
		rpill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rlbl := Label.new()
		rlbl.text = "⚡" + String(r["name"])
		rlbl.add_theme_font_size_override("font_size", 14)
		rlbl.add_theme_color_override("font_color", UiStyles.COL_GOLD)
		rpill.add_child(rlbl)
		_synergy_box.add_child(rpill)


func _style_progress(bar: ProgressBar, col: Color) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.14, 0.11, 0.20, 0.95)
	bg.set_corner_radius_all(6)
	var fg := StyleBoxFlat.new()
	fg.bg_color = col
	fg.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)


func _toggle_pause() -> void:
	var p := not get_tree().paused
	get_tree().paused = p
	if p and _run != null and _pause_synergy_lbl != null:
		var effects := SynergyEngine.format_active_effects(_run.synergy_info)
		var pause_text := ""
		if effects.is_empty():
			pause_text = "当前生效羁绊：暂未激活（凑齐同系 2/4/6 把或双系 2+2 激活共鸣）"
		else:
			pause_text = "当前生效羁绊：\n" + "\n".join(effects)
		var item_summary := _run.get_item_counts_summary()
		if item_summary.is_empty():
			pause_text += "\n\n已购道具：暂无"
		else:
			var parts: Array[String] = []
			for entry in item_summary:
				var idef: Dictionary = entry["def"]
				parts.append("%s ×%d" % [String(idef.get("name", entry["id"])), int(entry["count"])])
			pause_text += "\n\n已购道具（共 %d 件 / %d 种）：\n%s" % [_run.items.size(), item_summary.size(), " · ".join(parts)]
		_pause_synergy_lbl.text = pause_text
	_pause_modal.visible = p
	EventBus.sfx_requested.emit("sfx_ui_click", 0.0)


func _on_hp_changed(cur: float, max_v: float) -> void:
	_hp_bar.max_value = maxf(1.0, max_v)
	_hp_bar.value = clampf(cur, 0.0, max_v)
	_hp_lbl.text = "HP %d / %d" % [int(ceilf(cur)), int(roundf(max_v))]
	var danger := clampf(1.0 - (cur / maxf(1.0, max_v)) / 0.35, 0.0, 1.0)
	var mat := _vignette.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("danger_intensity", danger)
		mat.set_shader_parameter("pact_pulse", 0.35 if (_run != null and not _run.pacts.is_empty()) else 0.0)


func _on_xp_changed(xp: float, next_xp: float, lv: int) -> void:
	_xp_bar.max_value = maxf(1.0, next_xp)
	_xp_bar.value = xp
	_lv_lbl.text = "Lv.%d" % lv


func _on_dash_changed(charges: int, max_c: int, time_left: float, total_cd: float) -> void:
	_dash_btn.disabled = (charges <= 0)
	var progress := 1.0 if charges >= max_c else clampf(1.0 - (time_left / maxf(0.1, total_cd)), 0.0, 1.0)

	# Sweep overlay rises smoothly from bottom (anchor_top = 1.0 -> 0.0)
	_dash_sweep.anchor_top = 1.0 - progress
	_dash_sweep.color = Color(0.98, 0.78, 0.22, 0.34) if charges > 0 else Color(0.96, 0.25, 0.37, 0.38)

	if charges == 0:
		_dash_icon.modulate = Color(0.55, 0.55, 0.62, 0.42)
		_dash_cd_big_lbl.visible = true
		_dash_cd_big_lbl.text = "%.1fs" % time_left
		_dash_sub_lbl.text = "冷却中 0/%d" % max_c
		_dash_sub_lbl.add_theme_color_override("font_color", Color(0.98, 0.65, 0.72))
	elif charges < max_c:
		_dash_icon.modulate = Color.WHITE
		_dash_cd_big_lbl.visible = false
		_dash_sub_lbl.text = "血步 %d/%d · %.1fs" % [charges, max_c, time_left]
		_dash_sub_lbl.add_theme_color_override("font_color", UiStyles.COL_AZURE)
	else:
		_dash_icon.modulate = Color.WHITE
		_dash_cd_big_lbl.visible = false
		_dash_sub_lbl.text = "血步 · %d/%d 满" % [charges, max_c]
		_dash_sub_lbl.add_theme_color_override("font_color", UiStyles.COL_GOLD)

	for i in range(_dash_pips.size()):
		if i < charges:
			_dash_pips[i].color = UiStyles.COL_GOLD
		elif i == charges:
			_dash_pips[i].color = Color(0.22, 0.74, 0.97, 0.35 + progress * 0.65)
		else:
			_dash_pips[i].color = Color(0.22, 0.18, 0.30, 0.7)

	# Charge-complete pop feedback
	if charges > _prev_charges:
		var tw := _dash_btn.create_tween()
		tw.tween_property(_dash_btn, "scale", Vector2(1.14, 1.14), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(_dash_btn, "scale", Vector2.ONE, 0.12)
	_prev_charges = charges


func _on_crystals_changed(amount: int) -> void:
	_crystals_lbl.text = str(amount)


func _on_wave_changed(wave: int, time_left: float, _total: float, kills: int) -> void:
	var d_tag := ("D%d · " % _run.danger_level) if _run != null else ""
	_wave_lbl.text = (d_tag + ("无尽第 %d 波" % wave)) if (_run != null and _run.endless_mode) else (d_tag + ("第 %d / 10 波" % wave))
	_timer_lbl.text = "%ds" % int(ceilf(time_left))
	_kills_lbl.text = "击杀: %d" % kills


func _on_boss_spawned(boss_name: String, max_hp: float) -> void:
	_boss_box.visible = true
	_boss_name_lbl.text = "【首领】" + boss_name
	_boss_bar.max_value = maxf(1.0, max_hp)
	_boss_bar.value = max_hp


func _on_boss_hp_changed(cur: float, max_hp: float) -> void:
	_boss_bar.max_value = maxf(1.0, max_hp)
	_boss_bar.value = clampf(cur, 0.0, max_hp)


func _on_boss_defeated(_boss_id: String) -> void:
	_boss_box.visible = false
