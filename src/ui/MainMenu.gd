class_name MainMenu
extends Control
## Landing screen with Abyssal Ember wallet, Resume Run support, Navigation, and Settings modal.

signal start_new_run_requested()
signal resume_run_requested()
signal open_sanctuary_requested()
signal open_codex_requested()

var _embers_lbl: Label
var _record_lbl: Label
var _resume_btn: Button
var _settings_panel: PanelContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	refresh_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = UiStyles.COL_BG
	add_child(bg)

	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 28)
	safe.add_theme_constant_override("margin_right", 28)
	UiStyles.apply_safe_area_padding(safe, 34.0, 28.0)
	add_child(safe)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	safe.add_child(v)

	# Top wallet & record strip
	var top_p := PanelContainer.new()
	top_p.add_theme_stylebox_override("panel", UiStyles.make_panel_style(UiStyles.COL_PANEL, UiStyles.COL_BORDER, 14, 2))
	v.add_child(top_p)

	var top_h := HBoxContainer.new()
	top_p.add_child(top_h)

	_embers_lbl = Label.new()
	_embers_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_embers_lbl.add_theme_font_size_override("font_size", 22)
	_embers_lbl.add_theme_color_override("font_color", UiStyles.COL_GOLD)
	top_h.add_child(_embers_lbl)

	_record_lbl = Label.new()
	_record_lbl.add_theme_font_size_override("font_size", 17)
	_record_lbl.add_theme_color_override("font_color", UiStyles.COL_TEXT_DIM)
	top_h.add_child(_record_lbl)

	# Center Emblem + Title
	var spacer_top := Control.new()
	spacer_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer_top)

	var emblem := TextureRect.new()
	emblem.texture = load("res://assets/art/ui/launcher_192.png")
	emblem.custom_minimum_size = Vector2(154, 154)
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	v.add_child(emblem)

	var title := Label.new()
	title.text = "血契竞技场"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", UiStyles.COL_CRIMSON)
	v.add_child(title)

	var sub := Label.new()
	sub.text = "PACT ARENA · 三神系共鸣 × 赌命血契肉鸽"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", UiStyles.COL_TEXT_DIM)
	v.add_child(sub)

	var spacer_mid := Control.new()
	spacer_mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer_mid)

	# Action Buttons
	_resume_btn = Button.new()
	_resume_btn.text = "继续上次深渊征程"
	UiStyles.style_button(_resume_btn, UiStyles.COL_GOLD, true, 62.0)
	_resume_btn.pressed.connect(func():
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
		resume_run_requested.emit()
	)
	v.add_child(_resume_btn)

	var play_btn := Button.new()
	play_btn.text = "踏入竞技场 (新征程)"
	UiStyles.style_button(play_btn, UiStyles.COL_CRIMSON, true, 64.0)
	play_btn.pressed.connect(func():
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
		start_new_run_requested.emit()
	)
	v.add_child(play_btn)

	var meta_h := HBoxContainer.new()
	meta_h.add_theme_constant_override("separation", 12)
	v.add_child(meta_h)

	var sanc_btn := Button.new()
	sanc_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sanc_btn.text = "深渊圣所 (天赋)"
	UiStyles.style_button(sanc_btn, UiStyles.COL_AZURE, false, 58.0)
	sanc_btn.pressed.connect(func():
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
		open_sanctuary_requested.emit()
	)
	meta_h.add_child(sanc_btn)

	var codex_btn := Button.new()
	codex_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	codex_btn.text = "武器图鉴 & 禁用"
	UiStyles.style_button(codex_btn, UiStyles.COL_VOID, false, 58.0)
	codex_btn.pressed.connect(func():
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
		open_codex_requested.emit()
	)
	meta_h.add_child(codex_btn)

	var cfg_btn := Button.new()
	cfg_btn.text = "音频与视觉设置"
	UiStyles.style_button(cfg_btn, UiStyles.COL_BORDER, false, 50.0)
	cfg_btn.pressed.connect(func():
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
		_settings_panel.visible = true
	)
	v.add_child(cfg_btn)

	_build_settings_modal()


func _build_settings_modal() -> void:
	_settings_panel = PanelContainer.new()
	_settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	_settings_panel.offset_left = -260
	_settings_panel.offset_right = 260
	_settings_panel.offset_top = -230
	_settings_panel.offset_bottom = 230
	_settings_panel.visible = false
	_settings_panel.add_theme_stylebox_override("panel", UiStyles.make_panel_style(Color(0.09, 0.07, 0.16, 0.98), UiStyles.COL_AZURE, 18, 3))
	add_child(_settings_panel)

	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 14)
	_settings_panel.add_child(sv)

	var t := Label.new()
	t.text = "系统设置"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 26)
	sv.add_child(t)

	_add_slider_row(sv, "背景音乐音量", "bgm_volume", 0.72, func(v: float):
		SaveManager.set_setting("bgm_volume", v)
		AudioManager.apply_volumes()
	)
	_add_slider_row(sv, "战斗音效音量", "sfx_volume", 0.85, func(v: float):
		SaveManager.set_setting("sfx_volume", v)
	)
	_add_slider_row(sv, "友方特效透明度", "vfx_opacity", 0.90, func(v: float):
		SaveManager.set_setting("vfx_opacity", v)
	)

	var shake_btn := CheckButton.new()
	shake_btn.text = "屏幕震动反馈"
	shake_btn.button_pressed = bool(SaveManager.get_setting("screen_shake", true))
	shake_btn.toggled.connect(func(v: bool): SaveManager.set_setting("screen_shake", v))
	sv.add_child(shake_btn)

	var close_btn := Button.new()
	close_btn.text = "关闭"
	UiStyles.style_button(close_btn, UiStyles.COL_CRIMSON, true, 52.0)
	close_btn.pressed.connect(func():
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
		_settings_panel.visible = false
	)
	sv.add_child(close_btn)


func _add_slider_row(parent: VBoxContainer, label_txt: String, key: String, def_v: float, on_change: Callable) -> void:
	var lbl := Label.new()
	lbl.text = label_txt
	lbl.add_theme_font_size_override("font_size", 17)
	parent.add_child(lbl)

	var sl := HSlider.new()
	sl.min_value = 0.0
	sl.max_value = 1.0
	sl.step = 0.05
	sl.value = float(SaveManager.get_setting(key, def_v))
	sl.value_changed.connect(on_change)
	parent.add_child(sl)


func refresh_ui() -> void:
	_embers_lbl.text = "深渊余烬：%d" % SaveManager.get_embers()
	_record_lbl.text = "最高第 %d 波 | 胜场 %d" % [int(SaveManager.meta_data.get("best_wave", 0)), int(SaveManager.meta_data.get("total_victories", 0))]
	if SaveManager.has_resume_run():
		var r := SaveManager.load_resume_run()
		if r != null:
			_resume_btn.visible = true
			_resume_btn.text = "继续征程 (%s · 第 %d 波)" % [String(GameData.get_hero(r.hero_id).get("name", "")), r.wave]
			return
	_resume_btn.visible = false
