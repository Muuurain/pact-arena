class_name MainMenu
extends Control
## Modern Android-first lobby screen featuring Nano Banana key art, animated hero
## showcase, large Android navigation tiles, and top-right settings button.

signal start_new_run_requested()
signal resume_run_requested()
signal open_sanctuary_requested()
signal open_codex_requested()

var _embers_lbl: Label
var _record_lbl: Label
var _resume_btn: Button
var _settings_panel: PanelContainer
var _hero_showcase: TextureRect
var _ember_particles: CPUParticles2D
var _anim_t: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	refresh_ui()


func _process(delta: float) -> void:
	if not visible:
		return
	_anim_t += delta
	if _hero_showcase != null:
		var breath := sin(_anim_t * 2.8)
		_hero_showcase.pivot_offset = _hero_showcase.size * 0.5
		_hero_showcase.position.y = breath * 6.0
		_hero_showcase.scale = Vector2(1.0 - breath * 0.025, 1.0 + breath * 0.03)


func _build_ui() -> void:
	# Full-bleed Key Art Backdrop
	var bg_tex := TextureRect.new()
	bg_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_tex.texture = load("res://assets/art/ui/menu_bg.png")
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg_tex)

	# Atmospheric scrim for crisp UI legibility
	var scrim := ColorRect.new()
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.03, 0.02, 0.06, 0.42)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

	# Rising Glowing Ember Particles
	_ember_particles = CPUParticles2D.new()
	_ember_particles.position = Vector2(360, 1080)
	_ember_particles.texture = load("res://assets/art/sprites/projectiles/glow_soft.png")
	_ember_particles.amount = 28
	_ember_particles.lifetime = 3.8
	_ember_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_ember_particles.emission_rect_extents = Vector2(340, 40)
	_ember_particles.direction = Vector2(0, -1)
	_ember_particles.spread = 18.0
	_ember_particles.initial_velocity_min = 45.0
	_ember_particles.initial_velocity_max = 110.0
	_ember_particles.gravity = Vector2(0, -12)
	_ember_particles.scale_amount_min = 0.08
	_ember_particles.scale_amount_max = 0.20
	_ember_particles.color = Color(1.0, 0.58, 0.18, 0.65)
	add_child(_ember_particles)

	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 20)
	safe.add_theme_constant_override("margin_right", 20)
	UiStyles.apply_safe_area_padding(safe, 22.0, 24.0)
	add_child(safe)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	safe.add_child(v)

	# TOP ANDROID HEADER BAR (Embers + Best Record + Gear Icon Button)
	var top_h := HBoxContainer.new()
	top_h.add_theme_constant_override("separation", 10)
	v.add_child(top_h)

	var wallet_p := PanelContainer.new()
	wallet_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wallet_p.custom_minimum_size.y = 64
	wallet_p.add_theme_stylebox_override("panel", UiStyles.make_panel_style(Color(0.08, 0.06, 0.14, 0.88), UiStyles.COL_GOLD, 16, 2))
	top_h.add_child(wallet_p)

	var wh := HBoxContainer.new()
	wh.add_theme_constant_override("separation", 10)
	wallet_p.add_child(wh)

	var ember_ic := TextureRect.new()
	ember_ic.texture = load("res://assets/art/ui/icon_ember.png")
	ember_ic.custom_minimum_size = Vector2(40, 40)
	ember_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ember_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	wh.add_child(ember_ic)

	var w_txt_v := VBoxContainer.new()
	w_txt_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	w_txt_v.alignment = BoxContainer.ALIGNMENT_CENTER
	wh.add_child(w_txt_v)

	_embers_lbl = Label.new()
	_embers_lbl.add_theme_font_size_override("font_size", 22)
	_embers_lbl.add_theme_color_override("font_color", UiStyles.COL_GOLD)
	w_txt_v.add_child(_embers_lbl)

	_record_lbl = Label.new()
	_record_lbl.add_theme_font_size_override("font_size", 14)
	_record_lbl.add_theme_color_override("font_color", UiStyles.COL_TEXT_DIM)
	w_txt_v.add_child(_record_lbl)

	# Android Top-Right Square Settings Icon Button
	var cfg_btn := Button.new()
	cfg_btn.custom_minimum_size = Vector2(64, 64)
	cfg_btn.text = ""
	UiStyles.style_button(cfg_btn, UiStyles.COL_AZURE, false, 64.0)
	var cfg_ic := TextureRect.new()
	cfg_ic.texture = load("res://assets/art/ui/icon_settings.png")
	cfg_ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cfg_ic.offset_left = 10
	cfg_ic.offset_top = 10
	cfg_ic.offset_right = -10
	cfg_ic.offset_bottom = -10
	cfg_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cfg_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cfg_ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cfg_btn.add_child(cfg_ic)
	cfg_btn.pressed.connect(func():
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
		_settings_panel.visible = true
		UiStyles.animate_pop_in(_settings_panel)
	)
	top_h.add_child(cfg_btn)

	# TITLE & CREST HERO BLOCK
	var brand_box := VBoxContainer.new()
	brand_box.add_theme_constant_override("separation", 6)
	v.add_child(brand_box)

	var crest := TextureRect.new()
	crest.texture = load("res://assets/art/ui/launcher_512.png")
	crest.custom_minimum_size = Vector2(110, 110)
	crest.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	brand_box.add_child(crest)

	var title := Label.new()
	title.text = "血契竞技场"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color(1.0, 0.28, 0.42))
	title.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.08, 0.95))
	title.add_theme_constant_override("outline_size", 8)
	brand_box.add_child(title)

	var sub := Label.new()
	sub.text = "PACT ARENA · 三神系共鸣 × 赌命血契肉鸽"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 17)
	sub.add_theme_color_override("font_color", Color(0.90, 0.86, 0.96))
	sub.add_theme_color_override("font_outline_color", Color(0.04, 0.02, 0.08, 0.9))
	sub.add_theme_constant_override("outline_size", 4)
	brand_box.add_child(sub)

	# CENTER ANIMATED HERO SHOWCASE (sits cleanly over the glowing altar sigil)
	var showcase_wrap := Control.new()
	showcase_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(showcase_wrap)

	_hero_showcase = TextureRect.new()
	_hero_showcase.texture = load("res://assets/art/sprites/heroes/hero_crimson_blade.png")
	_hero_showcase.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_hero_showcase.offset_left = -125
	_hero_showcase.offset_right = 125
	_hero_showcase.offset_top = -125
	_hero_showcase.offset_bottom = 125
	_hero_showcase.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hero_showcase.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	showcase_wrap.add_child(_hero_showcase)

	# ANDROID BOTTOM ACTION DOCK
	_resume_btn = Button.new()
	_resume_btn.text = "继续上次深渊征程"
	UiStyles.style_button(_resume_btn, UiStyles.COL_GOLD, true, 66.0)
	_resume_btn.add_theme_font_size_override("font_size", 22)
	_resume_btn.pressed.connect(func():
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
		resume_run_requested.emit()
	)
	v.add_child(_resume_btn)

	# Large Primary Play CTA Button with Icon
	var play_btn := Button.new()
	play_btn.custom_minimum_size.y = 86
	play_btn.text = ""
	UiStyles.style_button(play_btn, UiStyles.COL_CRIMSON, true, 86.0)
	var play_h := HBoxContainer.new()
	play_h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	play_h.alignment = BoxContainer.ALIGNMENT_CENTER
	play_h.add_theme_constant_override("separation", 14)
	play_h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_btn.add_child(play_h)

	var play_ic := TextureRect.new()
	play_ic.texture = load("res://assets/art/ui/icon_dash.png")
	play_ic.custom_minimum_size = Vector2(52, 52)
	play_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	play_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	play_ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_h.add_child(play_ic)

	var play_tv := VBoxContainer.new()
	play_tv.alignment = BoxContainer.ALIGNMENT_CENTER
	play_tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_h.add_child(play_tv)

	var pt := Label.new()
	pt.text = "踏入竞技场"
	pt.add_theme_font_size_override("font_size", 28)
	pt.add_theme_color_override("font_color", Color.WHITE)
	play_tv.add_child(pt)

	var ps := Label.new()
	ps.text = "选择英雄 · 热度协议 · 开启第 1 波"
	ps.add_theme_font_size_override("font_size", 14)
	ps.add_theme_color_override("font_color", Color(1.0, 0.85, 0.88))
	play_tv.add_child(ps)

	play_btn.pressed.connect(func():
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
		start_new_run_requested.emit()
	)
	v.add_child(play_btn)

	# 3-Column Android Large Icon-Above-Text Navigation Dock
	var dock_h := HBoxContainer.new()
	dock_h.add_theme_constant_override("separation", 12)
	v.add_child(dock_h)

	dock_h.add_child(UiStyles.make_android_nav_tile(
		"res://assets/art/ui/icon_sanctuary.png",
		"深渊圣所",
		"永久天赋",
		UiStyles.COL_GOLD,
		func():
			EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
			open_sanctuary_requested.emit()
	))
	dock_h.add_child(UiStyles.make_android_nav_tile(
		"res://assets/art/ui/icon_codex.png",
		"武装图鉴",
		"精通 & 禁用",
		UiStyles.COL_AZURE,
		func():
			EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
			open_codex_requested.emit()
	))
	dock_h.add_child(UiStyles.make_android_nav_tile(
		"res://assets/art/sprites/heroes/hero_one_arm_asura.png",
		"英雄殿堂",
		"6 大职业",
		UiStyles.COL_VOID,
		func():
			EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
			start_new_run_requested.emit()
	))

	_build_settings_modal()


func _build_settings_modal() -> void:
	_settings_panel = PanelContainer.new()
	_settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	_settings_panel.offset_left = -270
	_settings_panel.offset_right = 270
	_settings_panel.offset_top = -240
	_settings_panel.offset_bottom = 240
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
	UiStyles.style_button(close_btn, UiStyles.COL_CRIMSON, true, 54.0)
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
	var best_d := SaveManager.get_best_danger_cleared()
	var d_txt := ("D%d" % best_d) if best_d >= 0 else "未通关"
	_record_lbl.text = "最高第 %d 波 · 胜场 %d · 最高难度 %s" % [int(SaveManager.meta_data.get("best_wave", 0)), int(SaveManager.meta_data.get("total_victories", 0)), d_txt]
	if SaveManager.has_resume_run():
		var r := SaveManager.load_resume_run()
		if r != null:
			_resume_btn.visible = true
			_resume_btn.text = "继续征程 (%s · 第 %d 波)" % [String(GameData.get_hero(r.hero_id).get("name", "")), r.wave]
			return
	_resume_btn.visible = false
