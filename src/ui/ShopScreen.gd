class_name ShopScreen
extends Control
## Between-wave tactical shop: weapon slot inspection/merge/sell, synergy overview,
## foldable full stat drawer, 4 shop cards with lock & merge hints, and next-wave launch.

signal next_wave_requested()
signal awakening_needed(slot_idx: int, weapon_id: String)

var _run: RunState
var _selected_slot: int = -1
var _stats_drawer_open: bool = false

var _header_lbl: Label
var _crystals_lbl: Label
var _synergy_lbl: Label
var _stats_panel: PanelContainer
var _stats_grid: GridContainer
var _slots_grid: GridContainer
var _slot_action_bar: PanelContainer
var _slot_detail_lbl: Label
var _merge_btn: Button
var _sell_btn: Button
var _offers_grid: GridContainer
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

	var top_h := HBoxContainer.new()
	top_h.add_theme_constant_override("separation", 10)
	top_p.add_child(top_h)

	var hv := VBoxContainer.new()
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_h.add_child(hv)

	_header_lbl = Label.new()
	_header_lbl.add_theme_font_size_override("font_size", 22)
	hv.add_child(_header_lbl)

	_synergy_lbl = Label.new()
	_synergy_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_synergy_lbl.add_theme_font_size_override("font_size", 15)
	_synergy_lbl.add_theme_color_override("font_color", UiStyles.COL_AZURE)
	hv.add_child(_synergy_lbl)

	_crystals_lbl = Label.new()
	_crystals_lbl.add_theme_font_size_override("font_size", 24)
	_crystals_lbl.add_theme_color_override("font_color", UiStyles.COL_GOLD)
	top_h.add_child(_crystals_lbl)

	var stats_toggle := Button.new()
	stats_toggle.text = "属性"
	stats_toggle.custom_minimum_size = Vector2(78, 48)
	UiStyles.style_button(stats_toggle, UiStyles.COL_AZURE, false, 48.0)
	stats_toggle.pressed.connect(func():
		_stats_drawer_open = not _stats_drawer_open
		_stats_panel.visible = _stats_drawer_open
		EventBus.sfx_requested.emit("sfx_ui_click", 0.0)
	)
	top_h.add_child(stats_toggle)

	# FOLDABLE FULL STATS DRAWER
	_stats_panel = PanelContainer.new()
	_stats_panel.visible = false
	_stats_panel.add_theme_stylebox_override("panel", UiStyles.make_panel_style(UiStyles.COL_CARD, UiStyles.COL_AZURE, 12, 2))
	root_v.add_child(_stats_panel)

	_stats_grid = GridContainer.new()
	_stats_grid.columns = 3
	_stats_grid.add_theme_constant_override("h_separation", 12)
	_stats_grid.add_theme_constant_override("v_separation", 6)
	_stats_panel.add_child(_stats_grid)

	# SCROLLABLE MIDDLE: WEAPONS + OFFERS
	var scroll := ScrollContainer.new()
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
	_slot_detail_lbl.add_theme_font_size_override("font_size", 16)
	sab_v.add_child(_slot_detail_lbl)

	var sab_h := HBoxContainer.new()
	sab_h.add_theme_constant_override("separation", 10)
	sab_v.add_child(sab_h)

	_merge_btn = Button.new()
	_merge_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_merge_btn.text = "融合升阶"
	UiStyles.style_button(_merge_btn, UiStyles.COL_GOLD, true, 46.0)
	_merge_btn.pressed.connect(_on_merge_pressed)
	sab_h.add_child(_merge_btn)

	_sell_btn = Button.new()
	_sell_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sell_btn.text = "出售"
	UiStyles.style_button(_sell_btn, UiStyles.COL_CRIMSON, false, 46.0)
	_sell_btn.pressed.connect(_on_sell_pressed)
	sab_h.add_child(_sell_btn)

	var s_title := Label.new()
	s_title.text = "深渊黑市货架"
	s_title.add_theme_font_size_override("font_size", 18)
	s_title.add_theme_color_override("font_color", UiStyles.COL_GOLD)
	mid_v.add_child(s_title)

	_offers_grid = GridContainer.new()
	_offers_grid.columns = 2
	_offers_grid.add_theme_constant_override("h_separation", 10)
	_offers_grid.add_theme_constant_override("v_separation", 10)
	mid_v.add_child(_offers_grid)

	# BOTTOM ACTION BAR
	var bot_h := HBoxContainer.new()
	bot_h.add_theme_constant_override("separation", 12)
	root_v.add_child(bot_h)

	_reroll_btn = Button.new()
	_reroll_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiStyles.style_button(_reroll_btn, UiStyles.COL_AZURE, false, 58.0)
	_reroll_btn.pressed.connect(_on_reroll_pressed)
	bot_h.add_child(_reroll_btn)

	_next_btn = Button.new()
	_next_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiStyles.style_button(_next_btn, UiStyles.COL_CRIMSON, true, 58.0)
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
	_slot_action_bar.visible = false
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
	_header_lbl.text = "第 %d 波整备 | 血契 %d" % [_run.wave, _run.pacts.size()]
	_crystals_lbl.text = "血晶: %d" % _run.crystals

	# Synergy & Resonance summary
	var counts: Dictionary = _run.synergy_info.get("effective_counts", {})
	var syn_parts: Array[String] = []
	for f in SynergyEngine.FACTIONS:
		syn_parts.append("%s%d" % [UiStyles.faction_name(f), int(counts.get(f, 0))])
	var res_list := SynergyEngine.get_active_resonances(_run.synergy_info.get("flags", {}))
	for r in res_list:
		syn_parts.append("【%s】" % String(r["name"]))
	_synergy_lbl.text = "羁绊：" + "  ".join(syn_parts)

	# Full Stats Drawer
	for c in _stats_grid.get_children():
		c.queue_free()
	for k in StatBlock.STAT_KEYS:
		var lbl := Label.new()
		var val := _run.stats.get_stat(k)
		lbl.text = "%s: %d" % [String(StatBlock.STAT_LABELS[k]), int(roundf(val))]
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", UiStyles.COL_CRIMSON if val < 0 else Color.WHITE)
		_stats_grid.add_child(lbl)

	# Weapon Slots
	for c in _slots_grid.get_children():
		c.queue_free()
	for i in range(_run.max_weapons):
		var slot_p := PanelContainer.new()
		slot_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_p.custom_minimum_size = Vector2(0, 108)
		if i < _run.weapons.size():
			var w: Dictionary = _run.weapons[i]
			var wdef := GameData.get_weapon(String(w["id"]))
			var tier := int(w["tier"])
			var tcol := UiStyles.tier_color(tier)
			var is_sel := (i == _selected_slot)
			slot_p.add_theme_stylebox_override("panel", UiStyles.make_panel_style(UiStyles.COL_CARD, UiStyles.COL_GOLD if is_sel else tcol, 12, 3 if is_sel else 2))

			var btn := Button.new()
			btn.flat = true
			var vb := VBoxContainer.new()
			vb.alignment = BoxContainer.ALIGNMENT_CENTER
			vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot_p.add_child(vb)

			var tex := TextureRect.new()
			tex.texture = load(String(wdef["sprite"]))
			tex.custom_minimum_size = Vector2(58, 58)
			tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vb.add_child(tex)

			var nl := Label.new()
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nl.text = "%s·%d阶" % [String(wdef["name"]), tier]
			nl.add_theme_font_size_override("font_size", 14)
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

	var free_r := int(roundf(SaveManager.get_talent_value("tal_free_reroll")))
	var r_cost := CombatFormulas.calc_reroll_cost(_run.wave, _run.shop_rerolls, free_r)
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
	var price := CombatFormulas.calc_shop_price(int(wdef.get("price", 18)), tier, _run.wave, 0.0, false)
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
		c.queue_free()
	for i in range(_run.shop_offers.size()):
		var offer: Dictionary = _run.shop_offers[i]
		if bool(offer.get("sold", false)):
			var sold_p := PanelContainer.new()
			sold_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sold_p.custom_minimum_size = Vector2(0, 210)
			sold_p.add_theme_stylebox_override("panel", UiStyles.make_panel_style(Color(0.08, 0.07, 0.12, 0.5), Color(0.22, 0.2, 0.3, 0.4), 12, 1))
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
		card.custom_minimum_size = Vector2(0, 210)

		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 5)
		card.add_child(cv)

		if is_w:
			var wdef := GameData.get_weapon(String(offer["id"]))
			var chk := _run.can_add_or_merge_weapon(String(offer["id"]), tier)
			var mode := String(chk["mode"])
			can_merge = mode == "merge"
			can_replace = mode == "replace"
			can_buy = can_buy and bool(chk["ok"])
			var border_col: Color = UiStyles.COL_GOLD if can_merge else (UiStyles.COL_AZURE if can_replace else tcol)
			card.add_theme_stylebox_override("panel", UiStyles.make_panel_style(UiStyles.COL_CARD, border_col, 14, 3 if (can_merge or can_replace) else 2))

			var top_row := HBoxContainer.new()
			cv.add_child(top_row)
			var icon := TextureRect.new()
			icon.texture = load(String(wdef["sprite"]))
			icon.custom_minimum_size = Vector2(62, 62)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			top_row.add_child(icon)

			var tv := VBoxContainer.new()
			tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			top_row.add_child(tv)

			var nl := Label.new()
			nl.text = "%s (%d阶)" % [String(wdef["name"]), tier]
			nl.add_theme_font_size_override("font_size", 16)
			nl.add_theme_color_override("font_color", tcol)
			tv.add_child(nl)

			var tag_l := Label.new()
			tag_l.text = ("★可合成升阶!" if can_merge else ("▲可替换升阶!" if can_replace else UiStyles.faction_name(String(wdef["faction"])) + "系"))
			tag_l.add_theme_font_size_override("font_size", 13)
			tag_l.add_theme_color_override("font_color", UiStyles.COL_GOLD if can_merge else (UiStyles.COL_AZURE if can_replace else UiStyles.faction_color(String(wdef["faction"]))))
			tv.add_child(tag_l)

			var dl := Label.new()
			dl.text = String(wdef["desc"])
			dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			dl.size_flags_vertical = Control.SIZE_EXPAND_FILL
			dl.add_theme_font_size_override("font_size", 13)
			dl.add_theme_color_override("font_color", UiStyles.COL_TEXT_DIM)
			cv.add_child(dl)
		else:
			var idef := GameData.get_item(String(offer["id"]))
			card.add_theme_stylebox_override("panel", UiStyles.make_panel_style(UiStyles.COL_CARD, tcol, 14, 2))
			var nl := Label.new()
			nl.text = "[道具] " + String(idef["name"])
			nl.add_theme_font_size_override("font_size", 17)
			nl.add_theme_color_override("font_color", tcol)
			cv.add_child(nl)

			var dl := Label.new()
			dl.text = String(idef["desc"])
			dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			dl.size_flags_vertical = Control.SIZE_EXPAND_FILL
			dl.add_theme_font_size_override("font_size", 14)
			cv.add_child(dl)

		var btn_h := HBoxContainer.new()
		btn_h.add_theme_constant_override("separation", 6)
		cv.add_child(btn_h)

		var idx := i
		var lock_btn := Button.new()
		lock_btn.text = "已锁" if locked else "锁定"
		lock_btn.custom_minimum_size = Vector2(76, 42)
		UiStyles.style_button(lock_btn, UiStyles.COL_GOLD if locked else UiStyles.COL_BORDER, locked, 42.0)
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
		UiStyles.style_button(buy_btn, UiStyles.COL_GOLD if can_merge else (UiStyles.COL_AZURE if can_replace else UiStyles.COL_EMERALD), true, 42.0)
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
	var cost := CombatFormulas.calc_reroll_cost(_run.wave, _run.shop_rerolls, free_r)
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
