class_name BattleHud
extends CanvasLayer
## Mobile-ergonomic combat HUD with Safe Area support, floating joystick,
## Blood Dash thumb button, Boss bar, faction synergy pills, and pause menu.

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
var _dash_lbl: Label
var _dash_cd_bar: ProgressBar
var _pause_panel: PanelContainer


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
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# Danger Vignette
	_vignette = ColorRect.new()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vmat := ShaderMaterial.new()
	vmat.shader = load("res://assets/shaders/danger_vignette.gdshader")
	_vignette.material = vmat
	root.add_child(_vignette)

	# Floating Virtual Joystick (under interactive buttons)
	_joystick = TouchJoystick.new()
	_joystick.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(_joystick)

	var safe_box := Control.new()
	safe_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	safe_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyles.apply_safe_area_padding(safe_box, 14.0, 18.0)
	root.add_child(safe_box)

	# TOP HUD BAR
	var top_panel := PanelContainer.new()
	top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_panel.offset_left = 14
	top_panel.offset_right = -14
	top_panel.offset_bottom = 92
	top_panel.add_theme_stylebox_override("panel", UiStyles.make_panel_style(Color(0.08, 0.06, 0.14, 0.85), UiStyles.COL_BORDER, 14, 2))
	safe_box.add_child(top_panel)

	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 10)
	top_panel.add_child(top_hbox)

	var left_col := VBoxContainer.new()
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(left_col)

	_crystals_lbl = Label.new()
	_crystals_lbl.text = "血晶: 20"
	_crystals_lbl.add_theme_font_size_override("font_size", 21)
	_crystals_lbl.add_theme_color_override("font_color", UiStyles.COL_CRIMSON)
	left_col.add_child(_crystals_lbl)

	_kills_lbl = Label.new()
	_kills_lbl.text = "击杀: 0"
	_kills_lbl.add_theme_font_size_override("font_size", 17)
	_kills_lbl.add_theme_color_override("font_color", UiStyles.COL_TEXT_DIM)
	left_col.add_child(_kills_lbl)

	var mid_col := VBoxContainer.new()
	mid_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(mid_col)

	_wave_lbl = Label.new()
	_wave_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_lbl.text = "第 1 波"
	_wave_lbl.add_theme_font_size_override("font_size", 20)
	mid_col.add_child(_wave_lbl)

	_timer_lbl = Label.new()
	_timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_lbl.text = "26s"
	_timer_lbl.add_theme_font_size_override("font_size", 32)
	_timer_lbl.add_theme_color_override("font_color", UiStyles.COL_GOLD)
	mid_col.add_child(_timer_lbl)

	var pause_btn := Button.new()
	pause_btn.text = "暂停"
	pause_btn.custom_minimum_size = Vector2(84, 52)
	UiStyles.style_button(pause_btn, UiStyles.COL_BORDER, false, 52.0)
	pause_btn.pressed.connect(_toggle_pause)
	top_hbox.add_child(pause_btn)

	# BOSS BAR (below top bar)
	_boss_box = VBoxContainer.new()
	_boss_box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_boss_box.offset_left = 36
	_boss_box.offset_right = -36
	_boss_box.offset_top = 102
	_boss_box.offset_bottom = 148
	_boss_box.visible = false
	_boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_box.add_child(_boss_box)

	_boss_name_lbl = Label.new()
	_boss_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_name_lbl.add_theme_font_size_override("font_size", 20)
	_boss_name_lbl.add_theme_color_override("font_color", UiStyles.COL_CRIMSON)
	_boss_box.add_child(_boss_name_lbl)

	_boss_bar = ProgressBar.new()
	_boss_bar.custom_minimum_size.y = 18
	_boss_bar.show_percentage = false
	_style_progress(_boss_bar, UiStyles.COL_CRIMSON)
	_boss_box.add_child(_boss_bar)

	# BOTTOM STATUS + DASH BUTTON
	var bot_hbox := HBoxContainer.new()
	bot_hbox.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bot_hbox.offset_left = 16
	bot_hbox.offset_right = -16
	bot_hbox.offset_top = -152
	bot_hbox.offset_bottom = -8
	bot_hbox.add_theme_constant_override("separation", 12)
	bot_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_box.add_child(bot_hbox)

	var bars_panel := PanelContainer.new()
	bars_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bars_panel.add_theme_stylebox_override("panel", UiStyles.make_panel_style(Color(0.08, 0.06, 0.14, 0.85), UiStyles.COL_BORDER, 14, 2))
	bot_hbox.add_child(bars_panel)

	var bars_v := VBoxContainer.new()
	bars_v.add_theme_constant_override("separation", 6)
	bars_panel.add_child(bars_v)

	var hp_row := HBoxContainer.new()
	bars_v.add_child(hp_row)
	_hp_lbl = Label.new()
	_hp_lbl.text = "HP 45 / 45"
	_hp_lbl.add_theme_font_size_override("font_size", 18)
	hp_row.add_child(_hp_lbl)
	_lv_lbl = Label.new()
	_lv_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lv_lbl.text = "Lv.1"
	_lv_lbl.add_theme_font_size_override("font_size", 18)
	_lv_lbl.add_theme_color_override("font_color", UiStyles.COL_AZURE)
	hp_row.add_child(_lv_lbl)

	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size.y = 20
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
	bars_v.add_child(_synergy_box)

	# Thumb Blood Dash Button
	var dash_wrap := VBoxContainer.new()
	dash_wrap.custom_minimum_size = Vector2(126, 134)
	bot_hbox.add_child(dash_wrap)

	_dash_btn = Button.new()
	_dash_btn.custom_minimum_size = Vector2(126, 114)
	_dash_btn.text = "血步\n2/2"
	UiStyles.style_button(_dash_btn, UiStyles.COL_CRIMSON, true, 114.0)
	_dash_btn.icon = load("res://assets/art/ui/icon_dash.png")
	_dash_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dash_btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	_dash_btn.pressed.connect(func(): dash_pressed.emit())
	dash_wrap.add_child(_dash_btn)

	_dash_cd_bar = ProgressBar.new()
	_dash_cd_bar.custom_minimum_size.y = 10
	_dash_cd_bar.show_percentage = false
	_dash_cd_bar.max_value = 1.0
	_dash_cd_bar.value = 1.0
	_style_progress(_dash_cd_bar, UiStyles.COL_GOLD)
	dash_wrap.add_child(_dash_cd_bar)

	_build_pause_modal(root)


func _build_pause_modal(root: Control) -> void:
	_pause_panel = PanelContainer.new()
	_pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	_pause_panel.offset_left = -220
	_pause_panel.offset_right = 220
	_pause_panel.offset_top = -180
	_pause_panel.offset_bottom = 180
	_pause_panel.visible = false
	_pause_panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_pause_panel.add_theme_stylebox_override("panel", UiStyles.make_panel_style(Color(0.09, 0.07, 0.16, 0.98), UiStyles.COL_CRIMSON, 18, 3))
	root.add_child(_pause_panel)

	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 16)
	_pause_panel.add_child(pv)

	var title := Label.new()
	title.text = "战斗已暂停"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	pv.add_child(title)

	var resume_btn := Button.new()
	resume_btn.text = "继续战斗"
	UiStyles.style_button(resume_btn, UiStyles.COL_EMERALD, true, 56.0)
	resume_btn.pressed.connect(_toggle_pause)
	pv.add_child(resume_btn)

	var shake_chk := CheckButton.new()
	shake_chk.text = "屏幕震动反馈"
	shake_chk.button_pressed = bool(SaveManager.get_setting("screen_shake", true))
	shake_chk.toggled.connect(func(v: bool): SaveManager.set_setting("screen_shake", v))
	pv.add_child(shake_chk)

	var exit_btn := Button.new()
	exit_btn.text = "返回主菜单 (不保存本波进度)"
	UiStyles.style_button(exit_btn, UiStyles.COL_CRIMSON, false, 54.0)
	exit_btn.pressed.connect(func():
		get_tree().paused = false
		_pause_panel.visible = false
		pause_exit_requested.emit()
	)
	pv.add_child(exit_btn)


func bind_run(run: RunState, player: PlayerController) -> void:
	_run = run
	_boss_box.visible = false
	if not _joystick.move_vector_changed.is_connected(player.set_touch_move_vector):
		_joystick.move_vector_changed.connect(player.set_touch_move_vector)
	if not dash_pressed.is_connected(player.trigger_dash):
		dash_pressed.connect(player.trigger_dash)
	_refresh_synergy_pills()


func _refresh_synergy_pills() -> void:
	for c in _synergy_box.get_children():
		c.queue_free()
	if _run == null:
		return
	var counts: Dictionary = _run.synergy_info.get("effective_counts", {})
	for f in SynergyEngine.FACTIONS:
		var n := int(counts.get(f, 0))
		if n <= 0:
			continue
		var lbl := Label.new()
		lbl.text = "%s %d" % [UiStyles.faction_name(f), n]
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.add_theme_color_override("font_color", UiStyles.faction_color(f))
		_synergy_box.add_child(lbl)


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
	_pause_panel.visible = p
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


func _on_dash_changed(charges: int, max_c: int, ratio: float) -> void:
	_dash_btn.text = "血步\n%d/%d" % [charges, max_c]
	_dash_btn.disabled = (charges <= 0)
	_dash_cd_bar.value = 1.0 if charges >= max_c else ratio


func _on_crystals_changed(amount: int) -> void:
	_crystals_lbl.text = "血晶: %d" % amount


func _on_wave_changed(wave: int, time_left: float, _total: float, kills: int) -> void:
	_wave_lbl.text = ("无尽第 %d 波" % wave) if (_run != null and _run.endless_mode) else ("第 %d / 10 波" % wave)
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
