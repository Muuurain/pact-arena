class_name ShopScreen
extends Control
## Between-wave tactical shop: weapon slot inspection/merge/sell, synergy overview,
## foldable full stat drawer, 4 shop cards with lock & merge hints, and next-wave launch.

signal next_wave_requested()
signal awakening_needed(slot_idx: int, weapon_id: String)

var _run: RunState
var _selected_slot: int = -1

var _header_lbl: Label
var _crystals_lbl: Label
var _synergy_lbl: Label
var _stats_modal: Control
var _stats_panel: PanelContainer
var _stats_grid: GridContainer
var _synergy_modal: Control
var _synergy_panel: PanelContainer
var _synergy_detail_box: VBoxContainer
var _slots_grid: GridContainer
var _slot_action_bar: PanelContainer
var _slot_detail_lbl: Label
var _merge_btn: Button
var _sell_btn: Button
var _offers_grid: GridContainer
var _sinks_box: VBoxContainer
var _sink_feedback_lbl: Label
var _reroll_btn: Button
var _next_btn: Button


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

	# TOP HEADER
	var top_p := PanelContainer.new()
	top_p.add_theme_stylebox_override("panel", UiStyles.make_panel_style(UiStyles.COL_PANEL, UiStyles.COL_BORDER, 14, 2))
	root_v.add_child(top_p)

	var top_v := VBoxContainer.new()
	top_v.add_theme_constant_override("separation", 6)
	top_p.add_child(top_v)

	var top_h := HBoxContainer.new()
	top_h.add_theme_constant_override("separation", 8)
	top_v.add_child(top_h)

	_header_lbl = Label.new()
	_header_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header_lbl.add_theme_font_size_override("font_size", 21)
	top_h.add_child(_header_lbl)

	_crystals_lbl = Label.new()
	_crystals_lbl.add_theme_font_size_override("font_size", 22)
	_crystals_lbl.add_theme_color_override("font_color", UiStyles.COL_GOLD)
	top_h.add_child(_crystals_lbl)

	var syn_toggle := Button.new()
	syn_toggle.text = "羁绊"
	syn_toggle.custom_minimum_size = Vector2(90, 52)
	UiStyles.style_button(syn_toggle, UiStyles.COL_VOID, false, 52.0)
	syn_toggle.pressed.connect(func():
		_stats_modal.visible = false
		_synergy_modal.visible = true
		UiStyles.animate_pop_in(_synergy_panel)
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
	)
	top_h.add_child(syn_toggle)

	var stats_toggle := Button.new()
	stats_toggle.text = "属性"
	stats_toggle.custom_minimum_size = Vector2(90, 52)
	UiStyles.style_button(stats_toggle, UiStyles.COL_AZURE, false, 52.0)
	stats_toggle.pressed.connect(func():
		_synergy_modal.visible = false
		_stats_modal.visible = true
		UiStyles.animate_pop_in(_stats_panel)
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
	)
	top_h.add_child(stats_toggle)

	_synergy_lbl = Label.new()
	_synergy_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_synergy_lbl.add_theme_font_size_override("font_size", 14)
	_synergy_lbl.add_theme_color_override("font_color", UiStyles.COL_AZURE)
	top_v.add_child(_synergy_lbl)

	# CENTERED FULL STATS MODAL
	var sm := UiStyles.make_centered_modal_shell(self, 620.0, UiStyles.COL_AZURE, 95)
	_stats_modal = sm["overlay"]
	_stats_panel = sm["panel"]
	var st_body: VBoxContainer = sm["body"]

	var st_title := Label.new()
	st_title.text = "当前角色完整面板"
	st_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	st_title.add_theme_font_size_override("font_size", 24)
	st_title.add_theme_color_override("font_color", UiStyles.COL_AZURE)
	st_body.add_child(st_title)

	var st_scroll := TouchScrollContainer.new()
	st_scroll.custom_minimum_size = Vector2(0, 440)
	st_body.add_child(st_scroll)

	_stats_grid = GridContainer.new()
	_stats_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stats_grid.columns = 2
	_stats_grid.add_theme_constant_override("h_separation", 12)
	_stats_grid.add_theme_constant_override("v_separation", 10)
	st_scroll.add_child(_stats_grid)

	var st_close := Button.new()
	st_close.text = "关闭面板"
	UiStyles.style_button(st_close, UiStyles.COL_AZURE, true, 54.0)
	st_close.pressed.connect(func():
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
		_stats_modal.visible = false
	)
	st_body.add_child(st_close)

	# CENTERED SYNERGY & RESONANCE MODAL
	var synm := UiStyles.make_centered_modal_shell(self, 640.0, UiStyles.COL_VOID, 95)
	_synergy_modal = synm["overlay"]
	_synergy_panel = synm["panel"]
	var syn_body: VBoxContainer = synm["body"]

	var syn_title := Label.new()
	syn_title.text = "神系羁绊与双神共鸣"
	syn_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	syn_title.add_theme_font_size_override("font_size", 24)
	syn_title.add_theme_color_override("font_color", UiStyles.COL_VOID)
	syn_body.add_child(syn_title)

	var syn_scroll := TouchScrollContainer.new()
	syn_scroll.custom_minimum_size = Vector2(0, 500)
	syn_body.add_child(syn_scroll)

	_synergy_detail_box = VBoxContainer.new()
	_synergy_detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_synergy_detail_box.add_theme_constant_override("separation", 10)
	syn_scroll.add_child(_synergy_detail_box)

	var syn_close := Button.new()
	syn_close.text = "关闭"
	UiStyles.style_button(syn_close, UiStyles.COL_VOID, true, 54.0)
	syn_close.pressed.connect(func():
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
		_synergy_modal.visible = false
	)
	syn_body.add_child(syn_close)

	# SCROLLABLE MIDDLE: WEAPONS + OFFERS
	var scroll := TouchScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_v.add_child(scroll)

	var mid_v := VBoxContainer.new()
	mid_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid_v.add_theme_constant_override("separation", 10)
	scroll.add_child(mid_v)

	var w_title := Label.new()
	w_title.text = "已装备武器 (点击武器可融合升阶或出售)"
	w_title.add_theme_font_size_override("font_size", 17)
	w_title.add_theme_color_override("font_color", UiStyles.COL_TEXT_DIM)
	mid_v.add_child(w_title)

	_slots_grid = GridContainer.new()
	_slots_grid.columns = 3
	_slots_grid.add_theme_constant_override("h_separation", 8)
	_slots_grid.add_theme_constant_override("v_separation", 8)
	mid_v.add_child(_slots_grid)

	# Selected weapon action bar
	_slot_action_bar = PanelContainer.new()
	_slot_action_bar.visible = false
	_slot_action_bar.add_theme_stylebox_override("panel", UiStyles.make_panel_style(UiStyles.COL_CARD, UiStyles.COL_GOLD, 12, 2))
	mid_v.add_child(_slot_action_bar)

	var sab_v := VBoxContainer.new()
	sab_v.add_theme_constant_override("separation", 8)
	_slot_action_bar.add_child(sab_v)

	_slot_detail_lbl = Label.new()
	_slot_detail_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_slot_detail_lbl.add_theme_font_size_override("font_size", 17)
	sab_v.add_child(_slot_detail_lbl)

	var sab_h := HBoxContainer.new()
	sab_h.add_theme_constant_override("separation", 10)
	sab_v.add_child(sab_h)

	_merge_btn = Button.new()
	_merge_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_merge_btn.text = "融合升阶"
	UiStyles.style_button(_merge_btn, UiStyles.COL_GOLD, true, 52.0)
	_merge_btn.pressed.connect(_on_merge_pressed)
	sab_h.add_child(_merge_btn)

	_sell_btn = Button.new()
	_sell_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sell_btn.text = "出售"
	UiStyles.style_button(_sell_btn, UiStyles.COL_CRIMSON, false, 52.0)
	_sell_btn.pressed.connect(_on_sell_pressed)
	sab_h.add_child(_sell_btn)

	var s_title := Label.new()
	s_title.text = "黑市货架（点图标看详情）"
	s_title.add_theme_font_size_override("font_size", 18)
	s_title.add_theme_color_override("font_color", UiStyles.COL_GOLD)
	mid_v.add_child(s_title)

	_offers_grid = GridContainer.new()
	_offers_grid.columns = 2
	_offers_grid.add_theme_constant_override("h_separation", 10)
	_offers_grid.add_theme_constant_override("v_separation", 10)
	mid_v.add_child(_offers_grid)

	var sink_title := Label.new()
	sink_title.text = "黑市熔炉（多余血晶永久淬炼）"
	sink_title.add_theme_font_size_override("font_size", 18)
	sink_title.add_theme_color_override("font_color", Color(1.0, 0.72, 0.32))
	mid_v.add_child(sink_title)

	_sink_feedback_lbl = Label.new()
	_sink_feedback_lbl.visible = false
	_sink_feedback_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sink_feedback_lbl.add_theme_font_size_override("font_size", 14)
	_sink_feedback_lbl.add_theme_color_override("font_color", UiStyles.COL_EMERALD)
	mid_v.add_child(_sink_feedback_lbl)

	_sinks_box = VBoxContainer.new()
	_sinks_box.add_theme_constant_override("separation", 8)
	mid_v.add_child(_sinks_box)

	# BOTTOM ACTION BAR
	var bot_h := HBoxContainer.new()
	bot_h.add_theme_constant_override("separation", 12)
	root_v.add_child(bot_h)

	_reroll_btn = Button.new()
	_reroll_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiStyles.style_button(_reroll_btn, UiStyles.COL_AZURE, false, 60.0)
	_reroll_btn.pressed.connect(_on_reroll_pressed)
	bot_h.add_child(_reroll_btn)

	_next_btn = Button.new()
	_next_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiStyles.style_button(_next_btn, UiStyles.COL_CRIMSON, true, 60.0)
	_next_btn.pressed.connect(func():
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
		visible = false
		next_wave_requested.emit()
	)
	bot_h.add_child(_next_btn)


func open_for_run(run: RunState, generate_new_stock: bool = true) -> void:
	_run = run
	_run.phase = "shop"
	_selected_slot = -1
	_stats_modal.visible = false
	_synergy_modal.visible = false
	_slot_action_bar.visible = false
	if _sink_feedback_lbl != null:
		_sink_feedback_lbl.visible = false
		_sink_feedback_lbl.text = ""
	if generate_new_stock or _run.shop_offers.is_empty():
		_run.shop_rerolls = 0
		_run.shop_offers = ShopGenerator.generate_shop_offers(_run)
		_run.locked_shop_offers.clear()
	SaveManager.save_resume_run(_run)
	refresh_ui()
	visible = true
	UiStyles.animate_pop_in(self)


func refresh_ui() -> void:
	if _run == null:
		return
	var ddef: Dictionary = GameData.get_difficulty(_run.danger_level)
	_header_lbl.text = "第 %d 波整备 | %s | 血契 %d" % [_run.wave, String(ddef.get("short_name", "D0")), _run.pacts.size()]
	_crystals_lbl.text = "血晶: %d" % _run.crystals

	# Synergy & Resonance summary + detailed drawer
	_synergy_lbl.text = SynergyEngine.format_shop_summary(_run.synergy_info)
	UiStyles.populate_synergy_details(_synergy_detail_box, _run.synergy_info, true)

	# Full Stats Modal Grid (2 spacious readable columns)
	for c in _stats_grid.get_children():
		_stats_grid.remove_child(c)
		c.queue_free()
	for k in StatBlock.STAT_KEYS:
		var stat_card := PanelContainer.new()
		stat_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sb := UiStyles.make_panel_style(Color(0.08, 0.06, 0.14, 0.9), UiStyles.COL_BORDER, 10, 1)
		sb.shadow_size = 0
		sb.content_margin_left = 10
		sb.content_margin_right = 10
		sb.content_margin_top = 8
		sb.content_margin_bottom = 8
		stat_card.add_theme_stylebox_override("panel", sb)
		var lbl := Label.new()
		var val := _run.stats.get_stat(k)
		lbl.text = "%s：%d" % [String(StatBlock.STAT_LABELS[k]), int(roundf(val))]
		lbl.add_theme_font_size_override("font_size", 17)
		lbl.add_theme_color_override("font_color", UiStyles.COL_CRIMSON if val < 0 else Color.WHITE)
		stat_card.add_child(lbl)
		_stats_grid.add_child(stat_card)

	# Weapon Slots
	for c in _slots_grid.get_children():
		_slots_grid.remove_child(c)
		c.queue_free()
	for i in range(_run.max_weapons):
		var slot_p := PanelContainer.new()
		slot_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_p.custom_minimum_size = Vector2(0, 124)
		if i < _run.weapons.size():
			var w: Dictionary = _run.weapons[i]
			var wdef := GameData.get_weapon(String(w["id"]))
			var tier := int(w["tier"])
			var tcol := UiStyles.tier_color(tier)
			var is_sel := (i == _selected_slot)
			slot_p.add_theme_stylebox_override("panel", UiStyles.make_panel_style(UiStyles.COL_CARD, UiStyles.COL_GOLD if is_sel else tcol, 14, 3 if is_sel else 2))

			var btn := Button.new()
			btn.flat = true
			var vb := VBoxContainer.new()
			vb.alignment = BoxContainer.ALIGNMENT_CENTER
			vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot_p.add_child(vb)

			var tex := TextureRect.new()
			tex.texture = load(String(wdef["sprite"]))
			tex.custom_minimum_size = Vector2(68, 68)
			tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vb.add_child(tex)

			var nl := Label.new()
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nl.text = "%s·%d阶" % [String(wdef["name"]), tier]
			nl.add_theme_font_size_override("font_size", 15)
			nl.add_theme_color_override("font_color", tcol)
			vb.add_child(nl)

			var fl := Label.new()
			fl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			fl.text = UiStyles.faction_name(String(wdef["faction"])) + ("★" if not String(w.get("awakening", "")).is_empty() else "")
			fl.add_theme_font_size_override("font_size", 12)
			fl.add_theme_color_override("font_color", UiStyles.faction_color(String(wdef["faction"])))
			vb.add_child(fl)

			var idx := i
			btn.pressed.connect(func():
				_selected_slot = idx if _selected_slot != idx else -1
				_update_slot_action_bar()
				refresh_ui()
			)
			btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			slot_p.add_child(btn)
		else:
			slot_p.add_theme_stylebox_override("panel", UiStyles.make_panel_style(Color(0.08, 0.06, 0.12, 0.65), Color(0.25, 0.22, 0.35, 0.5), 12, 1))
			var empty_l := Label.new()
			empty_l.text = "空武器槽"
			empty_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			empty_l.add_theme_font_size_override("font_size", 14)
			empty_l.add_theme_color_override("font_color", Color(0.45, 0.42, 0.55))
			slot_p.add_child(empty_l)

		_slots_grid.add_child(slot_p)

	_update_slot_action_bar()
	_rebuild_offers()
	_rebuild_sinks()

	var free_r := int(roundf(SaveManager.get_talent_value("tal_free_reroll")))
	var danger_price := float(GameData.get_difficulty(_run.danger_level).get("shop_price_mult", 1.0))
	var r_cost := CombatFormulas.calc_reroll_cost(_run.wave, _run.shop_rerolls, free_r, danger_price)
	_reroll_btn.text = "免费刷新" if r_cost == 0 else "刷新 ($%d)" % r_cost
	_reroll_btn.disabled = (_run.crystals < r_cost)
	_next_btn.text = "出战第 %d 波" % (_run.wave + 1)


func _update_slot_action_bar() -> void:
	if _selected_slot < 0 or _selected_slot >= _run.weapons.size():
		_slot_action_bar.visible = false
		return
	_slot_action_bar.visible = true
	var w: Dictionary = _run.weapons[_selected_slot]
	var wdef := GameData.get_weapon(String(w["id"]))
	var tier := int(w["tier"])
	_slot_detail_lbl.text = "【%s (%d阶)】 %s" % [String(wdef["name"]), tier, String(wdef["desc"])]

	var dup := _find_merge_partner(_selected_slot)
	_merge_btn.visible = (dup >= 0)
	_sell_btn.disabled = (_run.weapons.size() <= 1)
	var danger_price := float(GameData.get_difficulty(_run.danger_level).get("shop_price_mult", 1.0))
	var price := CombatFormulas.calc_shop_price(int(wdef.get("price", 18)), tier, _run.wave, 0.0, false, danger_price)
	var refund := maxi(5, int(roundf(float(price) * 0.6)))
	_sell_btn.text = "出售 (+%d)" % refund


func _find_merge_partner(slot_idx: int) -> int:
	var w: Dictionary = _run.weapons[slot_idx]
	if int(w["tier"]) >= 4:
		return -1
	for i in range(_run.weapons.size()):
		if i == slot_idx:
			continue
		if String(_run.weapons[i]["id"]) == String(w["id"]) and int(_run.weapons[i]["tier"]) == int(w["tier"]):
			return i
	return -1


func _on_merge_pressed() -> void:
	if _selected_slot < 0:
		return
	var partner := _find_merge_partner(_selected_slot)
	if partner < 0:
		return
	var res := _run.try_merge_slots(_selected_slot, partner)
	_selected_slot = -1
	EventBus.sfx_requested.emit("sfx_buy_merge", 0.0)
	SaveManager.save_resume_run(_run)
	refresh_ui()
	if res >= 0:
		awakening_needed.emit(res, String(_run.weapons[res]["id"]))


func _on_sell_pressed() -> void:
	if _selected_slot < 0:
		return
	var gained := _run.sell_weapon_slot(_selected_slot)
	if gained > 0:
		_selected_slot = -1
		EventBus.sfx_requested.emit("sfx_pickup_crystal", 0.0)
		SaveManager.save_resume_run(_run)
		refresh_ui()


func _rebuild_offers() -> void:
	for c in _offers_grid.get_children():
		_offers_grid.remove_child(c)
		c.queue_free()
	for i in range(_run.shop_offers.size()):
		var offer: Dictionary = _run.shop_offers[i]
		if bool(offer.get("sold", false)):
			var sold_p := PanelContainer.new()
			sold_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sold_p.custom_minimum_size = Vector2(0, 212)
			sold_p.add_theme_stylebox_override("panel", UiStyles.make_panel_style(Color(0.08, 0.07, 0.12, 0.5), Color(0.22, 0.2, 0.3, 0.4), 14, 1))
			var sl := Label.new()
			sl.text = "已售罄"
			sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			sl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.55))
			sold_p.add_child(sl)
			_offers_grid.add_child(sold_p)
			continue

		var is_w := String(offer["kind"]) == "weapon"
		var tier := int(offer.get("tier", 1))
		var tcol := UiStyles.tier_color(tier)
		var price := int(offer["price"])
		var locked := bool(offer.get("locked", false))
		var can_merge := false
		var can_replace := false
		var can_buy := _run.crystals >= price

		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(0, 212)

		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 8)
		card.add_child(cv)

		if is_w:
			var wdef := GameData.get_weapon(String(offer["id"]))
			var chk := _run.can_add_or_merge_weapon(String(offer["id"]), tier)
			var mode := String(chk["mode"])
			can_merge = mode == "merge"
			can_replace = mode == "replace"
			can_buy = can_buy and bool(chk["ok"])
			var border_col: Color = UiStyles.COL_GOLD if can_merge else (UiStyles.COL_AZURE if can_replace else tcol)
			card.add_theme_stylebox_override("panel", UiStyles.make_panel_style(UiStyles.COL_CARD, border_col, 16, 3 if (can_merge or can_replace) else 2))

			var info_btn := Button.new()
			info_btn.flat = true
			info_btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
			info_btn.custom_minimum_size.y = 128
			cv.add_child(info_btn)

			var info_v := VBoxContainer.new()
			info_v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			info_v.add_theme_constant_override("separation", 6)
			info_v.mouse_filter = Control.MOUSE_FILTER_IGNORE
			info_btn.add_child(info_v)

			var top_row := HBoxContainer.new()
			top_row.add_theme_constant_override("separation", 8)
			top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			info_v.add_child(top_row)

			var icon := TextureRect.new()
			icon.texture = load(String(wdef["sprite"]))
			icon.custom_minimum_size = Vector2(72, 72)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			top_row.add_child(icon)

			var tv := VBoxContainer.new()
			tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tv.alignment = BoxContainer.ALIGNMENT_CENTER
			tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
			top_row.add_child(tv)

			var nl := Label.new()
			nl.text = "%s (%d阶)" % [String(wdef["name"]), tier]
			nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			nl.add_theme_font_size_override("font_size", 17)
			nl.add_theme_color_override("font_color", tcol)
			tv.add_child(nl)

			var fac := String(wdef["faction"])
			var eff_cnt := int((_run.synergy_info.get("effective_counts", {}) as Dictionary).get(fac, 0))
			var tag_l := Label.new()
			tag_l.text = ("★可合成升阶!" if can_merge else ("▲可替换升阶!" if can_replace else "%s系 (现有%d)" % [UiStyles.faction_name(fac), eff_cnt]))
			tag_l.add_theme_font_size_override("font_size", 13)
			tag_l.add_theme_color_override("font_color", UiStyles.COL_GOLD if can_merge else (UiStyles.COL_AZURE if can_replace else UiStyles.faction_color(fac)))
			tv.add_child(tag_l)

			var dl := Label.new()
			dl.text = "伤害%d · 冷却%.1fs  (点看详情›)" % [int(roundf(float(wdef["base_damage"]) * CombatFormulas.TIER_DAMAGE_MULT[tier - 1])), float(wdef["base_cooldown"]) * CombatFormulas.TIER_COOLDOWN_MULT[tier - 1]]
			dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			dl.add_theme_font_size_override("font_size", 13)
			dl.add_theme_color_override("font_color", UiStyles.COL_TEXT_DIM)
			info_v.add_child(dl)

			var w_copy := (wdef as Dictionary).duplicate(true)
			var t_val := tier
			info_btn.pressed.connect(func():
				EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
				var awks: Array = w_copy.get("awakenings", [])
				var awk_lines := ""
				if awks.size() >= 2:
					awk_lines = "\n\n【四阶红武双觉醒分支】\n• %s：%s\n• %s：%s" % [
						String(awks[0]["name"]), String(awks[0]["desc"]),
						String(awks[1]["name"]), String(awks[1]["desc"]),
					]
				var eff_d := float(w_copy["base_damage"]) * CombatFormulas.TIER_DAMAGE_MULT[t_val - 1]
				var eff_cd := float(w_copy["base_cooldown"]) * CombatFormulas.TIER_COOLDOWN_MULT[t_val - 1]
				UiStyles.show_detail_modal(self, {
					"title": "%s (%d阶)" % [String(w_copy["name"]), t_val],
					"subtitle": "%s神系 · 点此查看完整数值" % UiStyles.faction_name(String(w_copy["faction"])),
					"body": "%s\n\n面板伤害：%.0f   |   冷却：%.2fs\n攻击距离：%.0f   |   暴击加成：+%.0f%%%s" % [
						String(w_copy["desc"]), eff_d, eff_cd, float(w_copy["base_range"]), float(w_copy["crit_bonus"]), awk_lines
					],
					"accent": border_col,
					"icon_path": String(w_copy["sprite"]),
				})
			)
		else:
			var idef := GameData.get_item(String(offer["id"]))
			card.add_theme_stylebox_override("panel", UiStyles.make_panel_style(UiStyles.COL_CARD, tcol, 16, 2))
			var info_btn := Button.new()
			info_btn.flat = true
			info_btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
			info_btn.custom_minimum_size.y = 128
			cv.add_child(info_btn)

			var info_v := VBoxContainer.new()
			info_v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			info_v.add_theme_constant_override("separation", 6)
			info_v.mouse_filter = Control.MOUSE_FILTER_IGNORE
			info_btn.add_child(info_v)

			var top_row := HBoxContainer.new()
			top_row.add_theme_constant_override("separation", 8)
			top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			info_v.add_child(top_row)

			var icon := TextureRect.new()
			icon.texture = load(String(idef.get("sprite", "")))
			icon.custom_minimum_size = Vector2(72, 72)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			top_row.add_child(icon)

			var tv := VBoxContainer.new()
			tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tv.alignment = BoxContainer.ALIGNMENT_CENTER
			tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
			top_row.add_child(tv)

			var nl := Label.new()
			nl.text = String(idef["name"])
			nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			nl.add_theme_font_size_override("font_size", 17)
			nl.add_theme_color_override("font_color", tcol)
			tv.add_child(nl)

			var tag_l := Label.new()
			tag_l.text = "被动 · %s (点看›)" % UiStyles.tier_name(tier)
			tag_l.add_theme_font_size_override("font_size", 13)
			tag_l.add_theme_color_override("font_color", UiStyles.COL_TEXT_DIM)
			tv.add_child(tag_l)

			var dl := Label.new()
			dl.text = String(idef["desc"])
			dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			dl.add_theme_font_size_override("font_size", 13)
			dl.add_theme_color_override("font_color", Color.WHITE)
			info_v.add_child(dl)

			var it_copy := (idef as Dictionary).duplicate(true)
			var pr_val := price
			info_btn.pressed.connect(func():
				EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
				UiStyles.show_detail_modal(self, {
					"title": String(it_copy["name"]),
					"subtitle": "%s品质 · 本波售价 %d 血晶" % [UiStyles.tier_name(tier), pr_val],
					"body": "道具效果：\n%s\n\n同类被动道具可无限叠加，永久增强本局人物属性。" % String(it_copy["desc"]),
					"accent": tcol,
					"icon_path": String(it_copy.get("sprite", "")),
				})
			)

		var btn_h := HBoxContainer.new()
		btn_h.add_theme_constant_override("separation", 6)
		cv.add_child(btn_h)

		var idx := i
		var lock_btn := Button.new()
		lock_btn.text = "已锁" if locked else "锁定"
		lock_btn.custom_minimum_size = Vector2(78, 48)
		UiStyles.style_button(lock_btn, UiStyles.COL_GOLD if locked else UiStyles.COL_BORDER, locked, 48.0)
		lock_btn.add_theme_font_size_override("font_size", 15)
		lock_btn.pressed.connect(func():
			_run.shop_offers[idx]["locked"] = not bool(_run.shop_offers[idx].get("locked", false))
			_sync_locked_offers()
			EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
			refresh_ui()
		)
		btn_h.add_child(lock_btn)

		var buy_btn := Button.new()
		buy_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buy_btn.text = "合成 $%d" % price if can_merge else ("替换 $%d" % price if can_replace else "购买 $%d" % price)
		buy_btn.disabled = not can_buy
		UiStyles.style_button(buy_btn, UiStyles.COL_GOLD if can_merge else (UiStyles.COL_AZURE if can_replace else UiStyles.COL_EMERALD), true, 48.0)
		buy_btn.add_theme_font_size_override("font_size", 16)
		buy_btn.pressed.connect(func(): _buy_offer(idx))
		btn_h.add_child(buy_btn)

		_offers_grid.add_child(card)


func _sync_locked_offers() -> void:
	_run.locked_shop_offers.clear()
	for o in _run.shop_offers:
		if not bool(o.get("sold", false)) and bool(o.get("locked", false)):
			_run.locked_shop_offers.append((o as Dictionary).duplicate(true))


func _buy_offer(idx: int) -> void:
	var offer: Dictionary = _run.shop_offers[idx]
	var price := int(offer["price"])
	if _run.crystals < price or bool(offer.get("sold", false)):
		return

	var awakened_slot := -1
	if String(offer["kind"]) == "weapon":
		var res := _run.add_or_merge_weapon(String(offer["id"]), int(offer["tier"]))
		if not bool(res["success"]):
			return
		awakened_slot = int(res["awakened_slot"])
	else:
		_run.items.append(String(offer["id"]))
		_run.recompute_effective_stats()

	_run.add_crystals(-price)
	offer["sold"] = true
	offer["locked"] = false
	_sync_locked_offers()
	EventBus.sfx_requested.emit("sfx_buy_merge", 0.05)
	SaveManager.save_resume_run(_run)
	refresh_ui()

	if awakened_slot >= 0:
		awakening_needed.emit(awakened_slot, String(_run.weapons[awakened_slot]["id"]))


func _on_reroll_pressed() -> void:
	var free_r := int(roundf(SaveManager.get_talent_value("tal_free_reroll")))
	var danger_price := float(GameData.get_difficulty(_run.danger_level).get("shop_price_mult", 1.0))
	var cost := CombatFormulas.calc_reroll_cost(_run.wave, _run.shop_rerolls, free_r, danger_price)
	if _run.crystals < cost:
		return
	_run.add_crystals(-cost)
	_run.shop_rerolls += 1
	_sync_locked_offers()
	_run.shop_offers = ShopGenerator.generate_shop_offers(_run)
	_run.locked_shop_offers.clear()
	EventBus.sfx_requested.emit("sfx_reroll", 0.05)
	SaveManager.save_resume_run(_run)
	refresh_ui()


func _rebuild_sinks() -> void:
	if _sinks_box == null:
		return
	for c in _sinks_box.get_children():
		_sinks_box.remove_child(c)
		c.queue_free()
	for s in GameData.shop_sinks:
		var sid := String(s["id"])
		var cnt := int(_run.shop_sink_counts.get(sid, 0))
		var cost := _run.get_shop_sink_cost(sid)
		var can_buy := (_run.crystals >= cost)

		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UiStyles.make_panel_style(UiStyles.COL_CARD, Color(0.75, 0.52, 0.22), 12, 2))
		_sinks_box.add_child(card)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)

		var icon := TextureRect.new()
		icon.texture = load(String(s.get("sprite", "")))
		icon.custom_minimum_size = Vector2(64, 64)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)

		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(tv)

		var nl := Label.new()
		nl.text = "%s（已用 %d 次）" % [String(s["name"]), cnt]
		nl.add_theme_font_size_override("font_size", 16)
		nl.add_theme_color_override("font_color", UiStyles.COL_GOLD)
		tv.add_child(nl)

		var dl := Label.new()
		dl.text = String(s["effect_text"])
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dl.add_theme_font_size_override("font_size", 14)
		dl.add_theme_color_override("font_color", UiStyles.COL_TEXT_DIM)
		tv.add_child(dl)

		var buy_btn := Button.new()
		buy_btn.text = "淬炼 $%d" % cost
		buy_btn.custom_minimum_size = Vector2(122, 52)
		buy_btn.disabled = not can_buy
		UiStyles.style_button(buy_btn, UiStyles.COL_GOLD, true, 52.0)
		buy_btn.add_theme_font_size_override("font_size", 16)
		buy_btn.pressed.connect(func(): _on_buy_sink_pressed(sid))
		row.add_child(buy_btn)


func _on_buy_sink_pressed(sink_id: String) -> void:
	var res := _run.buy_shop_sink(sink_id)
	if not bool(res.get("ok", false)):
		return
	if _sink_feedback_lbl != null:
		_sink_feedback_lbl.text = "★ " + String(res.get("msg", "淬炼完成"))
		_sink_feedback_lbl.visible = true
	EventBus.sfx_requested.emit("sfx_awakening" if sink_id == "sink_mystery_relic" else "sfx_buy_merge", 0.05)
	SaveManager.save_resume_run(_run)
	refresh_ui()
