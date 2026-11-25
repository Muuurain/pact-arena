class_name RunSummaryScreen
extends Control
## Handles both Wave 10 Victory Choice (Evacuate vs Endless Mode) and final Post-Run Summary
## showing Embers earned, unlocked heroes, active Blood Pacts, and weapon kills.

signal continue_endless_requested()
signal return_menu_requested()

var _title_lbl: Label
var _sub_lbl: Label
var _body_lbl: Label
var _endless_btn: Button
var _done_btn: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.02, 0.08, 0.94)
	add_child(bg)

	var scroll := TouchScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiStyles.apply_safe_area_padding(scroll, 28.0, 26.0)
	add_child(scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	scroll.add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	margin.add_child(v)

	_title_lbl = Label.new()
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 36)
	v.add_child(_title_lbl)

	_sub_lbl = Label.new()
	_sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sub_lbl.add_theme_font_size_override("font_size", 20)
	_sub_lbl.add_theme_color_override("font_color", UiStyles.COL_GOLD)
	v.add_child(_sub_lbl)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiStyles.make_panel_style(UiStyles.COL_CARD, UiStyles.COL_BORDER, 16, 2))
	v.add_child(card)

	_body_lbl = Label.new()
	_body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_lbl.add_theme_font_size_override("font_size", 18)
	card.add_child(_body_lbl)

	_endless_btn = Button.new()
	_endless_btn.text = "踏入无尽深渊 (挑战第 11+ 波冲榜)"
	UiStyles.style_button(_endless_btn, UiStyles.COL_VOID, true, 58.0)
	_endless_btn.pressed.connect(func():
		EventBus.sfx_requested.emit("sfx_pact_sign", 0.0)
		visible = false
		continue_endless_requested.emit()
	)
	v.add_child(_endless_btn)

	_done_btn = Button.new()
	_done_btn.text = "带回余烬返回主界面"
	UiStyles.style_button(_done_btn, UiStyles.COL_CRIMSON, true, 58.0)
	_done_btn.pressed.connect(func():
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
		visible = false
		return_menu_requested.emit()
	)
	v.add_child(_done_btn)


func show_wave10_choice(run: RunState) -> void:
	_title_lbl.text = "深渊主宰已陨落！"
	_title_lbl.add_theme_color_override("font_color", UiStyles.COL_GOLD)
	_sub_lbl.text = "成功打通第 10 波！现在可以携余烬凯旋，或潜入无尽深渊继续冲击极限。"
	_body_lbl.text = _format_stats_summary(run, run.calc_ember_reward(), [])
	_endless_btn.visible = true
	_done_btn.text = "见好就收（结算 +%d 余烬）" % run.calc_ember_reward()
	EventBus.sfx_requested.emit("sfx_victory", 0.0)
	visible = true
	UiStyles.animate_pop_in(self)


func show_final_summary(run: RunState, commit_report: Dictionary) -> void:
	var earned := int(commit_report.get("embers_earned", 0))
	var unlocked: Array = commit_report.get("newly_unlocked", [])
	if run.victory_reached:
		_title_lbl.text = "深渊凯旋"
		_title_lbl.add_theme_color_override("font_color", UiStyles.COL_GOLD)
	else:
		_title_lbl.text = "饮恨深渊"
		_title_lbl.add_theme_color_override("font_color", UiStyles.COL_CRIMSON)

	_sub_lbl.text = "本局收获：【+%d 深渊余烬】" % earned
	_body_lbl.text = _format_stats_summary(run, earned, unlocked)
	_endless_btn.visible = false
	_done_btn.text = "返回主菜单"
	visible = true
	UiStyles.animate_pop_in(self)


func _format_stats_summary(run: RunState, embers: int, unlocked: Array) -> String:
	var hdef := GameData.get_hero(run.hero_id)
	var ddef: Dictionary = GameData.get_difficulty(run.danger_level)
	var d_ember := int(ddef.get("ember_bonus_pct", 0))
	var lines: Array[String] = [
		"出战英雄：%s  |  挑战难度：%s" % [String(hdef.get("name", "")), String(ddef.get("name", "试炼 (D0)"))],
		"推进波次：第 %d 波  |  总击杀：%d  |  精英/首领：%d / %d" % [run.wave, run.total_kills, run.elites_killed, run.bosses_killed],
		"难度加成 +%d%%  |  热度词缀：%d 项 (+%d%%)" % [d_ember, run.active_heats.size(), run.active_heats.size() * 25],
		"预估结算余烬：%d" % embers,
		"",
		"已签血契（%d）：" % run.pacts.size(),
	]
	if run.pacts.is_empty():
		lines.append("  无")
	else:
		for pid in run.pacts:
			lines.append("  • " + String(GameData.get_pact(pid).get("name", pid)))

	lines.append("")
	lines.append("武器击杀贡献：")
	for wid in run.weapon_kills_this_run:
		var wname := String(GameData.get_weapon(wid).get("name", wid))
		lines.append("  • %s：%d 杀" % [wname, int(run.weapon_kills_this_run[wid])])

	if not unlocked.is_empty():
		lines.append("")
		lines.append("★ 达成新英雄解锁：" + "、".join(unlocked))

	return "\n".join(lines)
