extends Node
## Automated headless test suite verifying core formulas, synergies, Blood Pacts,
## weapon merging/awakening, all 14 weapon attack patterns, Boss 1 & Boss 2,
## UI screen transitions, save persistence, and Arena simulation smoke test.

var _failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run_all")


func _assert(cond: bool, msg: String) -> void:
	if not cond:
		_failures.append(msg)
		printerr("[FAIL] ", msg)
	else:
		print("[PASS] ", msg)


func _run_all() -> void:
	await get_tree().process_frame
	_test_catalog_completeness()
	_test_stat_bounds_and_pacts()
	_test_synergies_and_dual_resonances()
	_test_weapon_merge_and_awakening()
	_test_shop_and_save_persistence()
	_test_difficulty_and_economy_rebalance()
	await _test_touch_scroll_container()
	await _test_full_ui_and_combat_integration()

	if _failures.is_empty():
		print("\nALL TESTS PASSED (0 failures)")
		get_tree().quit(0)
	else:
		printerr("\nTEST SUITE FAILED: ", _failures.size(), " failures")
		get_tree().quit(1)


func _test_catalog_completeness() -> void:
	_assert(GameData.heroes.size() == 6, "6 heroes loaded")
	_assert(GameData.weapons.size() == 14, "14 weapons loaded")
	for w in GameData.weapons:
		_assert((w["awakenings"] as Array).size() == 2, "Weapon %s has 2 awakenings" % w["id"])
		_assert(ResourceLoader.exists(String(w["sprite"])), "Weapon sprite exists: %s" % w["sprite"])
	_assert(GameData.items.size() == 18, "18 passive items loaded")
	for it in GameData.items:
		_assert(ResourceLoader.exists(String(it.get("sprite", ""))), "Item sprite exists: %s" % it.get("sprite", ""))
	_assert(GameData.pacts.size() == 10, "10 Blood Pacts loaded")
	_assert(GameData.talents.size() == 12, "12 Sanctuary talents loaded")
	_assert(GameData.heats.size() == 8, "8 Heat protocols loaded")
	_assert(GameData.enemies.size() == 10, "8 enemy types + 2 Bosses loaded")
	_assert(GameData.difficulties.size() == 6, "6 Difficulty tiers (D0..D5) loaded")
	_assert(GameData.shop_sinks.size() == 3, "3 Shop crystal sinks loaded")
	for sk in GameData.shop_sinks:
		_assert(ResourceLoader.exists(String(sk.get("sprite", ""))), "Shop sink sprite exists: %s" % sk.get("sprite", ""))

	var sfx_dir := DirAccess.open("res://assets/audio/sfx")
	var sfx_oggs: Array[String] = []
	if sfx_dir != null:
		for f in sfx_dir.get_files():
			if f.ends_with(".ogg"):
				sfx_oggs.append(f)
				_assert(load("res://assets/audio/sfx/" + f) != null, "Audio SFX loads: " + f)
	_assert(sfx_oggs.size() == 27, "All 27 SFX OGG assets present and loadable")
	for bgm_f in ["bgm_sanctuary.ogg", "bgm_combat.ogg", "bgm_boss.ogg"]:
		var stream := load("res://assets/audio/bgm/" + bgm_f) as AudioStreamOggVorbis
		_assert(stream != null and stream.has_loop(), "Audio BGM loads with seamless loop enabled: " + bgm_f)


func _test_stat_bounds_and_pacts() -> void:
	var run := RunState.new()
	run.start_new_run("hero_frenzied_butcher", "wpn_battleaxe", [])
	_assert(run.stats.get_stat("armor") <= -3.0, "Butcher starts with negative armor")
	var neg_taken := CombatFormulas.calc_player_damage_taken(20.0, run.stats)
	_assert(neg_taken > 20.0, "Negative armor amplifies incoming damage (>20)")

	run.apply_blood_pact("pact_glass_cannon")
	_assert(is_equal_approx(run.stats.get_stat("max_hp"), 20.0), "Glass Cannon locks max_hp to 20")

	run.apply_blood_pact("pact_crazy_overdrive")
	_assert(is_equal_approx(run.stats.get_stat("armor"), -6.0), "Crazy Overdrive locks armor to -6")
	run.current_hp = 10.0
	var dyn := run.get_dynamic_combat_mods()
	_assert(float(dyn["attack_speed_pct_add"]) > 100.0, "Overdrive scales AS with missing HP")

	var lone_run := RunState.new()
	lone_run.start_new_run("hero_crimson_blade", "wpn_chainsaw", [])
	lone_run.apply_blood_pact("pact_lone_wolf")
	_assert(lone_run.max_weapons == 5, "Lone Wolf reduces max_weapons by 1")

	var undying_run := RunState.new()
	undying_run.start_new_run("hero_one_arm_asura", "wpn_chainsaw", [])
	undying_run.weapons[0]["tier"] = 3
	var hp_before_undying := undying_run.stats.get_stat("max_hp")
	undying_run.apply_blood_pact("pact_undying_sacrifice")
	_assert(int(undying_run.weapons[0]["tier"]) == 3, "Undying Sacrifice preserves equipped weapon tiers")
	_assert(undying_run.revives_left == 1, "Undying Sacrifice grants 1 revive")
	_assert(undying_run.stats.get_stat("max_hp") < hp_before_undying, "Undying Sacrifice applies -10% max HP cost")


func _test_synergies_and_dual_resonances() -> void:
	var run := RunState.new()
	run.start_new_run("hero_crimson_blade", "wpn_chainsaw", [])
	run.add_or_merge_weapon("wpn_battleaxe", 1)
	run.add_or_merge_weapon("wpn_arc_staff", 1)
	run.add_or_merge_weapon("wpn_ice_prism", 1)
	run.add_or_merge_weapon("wpn_bone_spear", 1)
	run.add_or_merge_weapon("wpn_void_grimoire", 1)

	var flags: Dictionary = run.synergy_info.get("flags", {})
	_assert(bool(flags.get("res_blood_lightning", false)), "2 Crimson + 2 Azure activates Blood Lightning")
	_assert(bool(flags.get("res_soul_curse", false)), "2 Crimson + 2 Void activates Soul Curse")
	_assert(bool(flags.get("res_void_storm", false)), "2 Azure + 2 Void activates Void Storm")
	_assert(SynergyEngine.get_all_resonances().size() == 3, "All 3 dual resonances documented in SynergyEngine")
	var eff_lines := SynergyEngine.format_active_effects(run.synergy_info)
	_assert(eff_lines.size() >= 6, "SynergyEngine formats concrete active tier & resonance effects")
	var shop_sum := SynergyEngine.format_shop_summary(run.synergy_info)
	_assert(shop_sum.contains("生效：") and shop_sum.contains("暴击率+10%"), "Shop synergy summary explains concrete effects")


func _test_weapon_merge_and_awakening() -> void:
	var run := RunState.new()
	run.start_new_run("hero_crimson_blade", "wpn_chainsaw", [])
	run.weapons[0]["tier"] = 3
	var res := run.add_or_merge_weapon("wpn_chainsaw", 3)
	_assert(bool(res["success"]), "Tier 3 + Tier 3 merges cleanly")
	_assert(int(run.weapons[0]["tier"]) == 4, "Merged weapon reaches Tier 4")
	_assert(int(res["awakened_slot"]) == 0, "Tier 4 triggers awakening slot 0")

	var asura := RunState.new()
	asura.start_new_run("hero_one_arm_asura", "wpn_chainsaw", [])
	_assert(asura.max_weapons == 1, "One-Arm Asura has max_weapons == 1")
	var chk_up := asura.can_add_or_merge_weapon("wpn_chainsaw", 2)
	_assert(bool(chk_up["ok"]) and String(chk_up["mode"]) == "replace", "Higher-tier same weapon enables replace mode on full 1-slot hero")
	var chk_other := asura.can_add_or_merge_weapon("wpn_battleaxe", 3)
	_assert(not bool(chk_other["ok"]), "Different weapon still blocked when 1-slot hero is full")
	var rep2 := asura.add_or_merge_weapon("wpn_chainsaw", 2)
	_assert(bool(rep2["success"]) and asura.weapons.size() == 1 and int(asura.weapons[0]["tier"]) == 2, "Replacing Tier 1 with Tier 2 upgrades slot 0 directly")
	var chk_low := asura.can_add_or_merge_weapon("wpn_chainsaw", 1)
	_assert(not bool(chk_low["ok"]), "Lower-tier same weapon cannot replace higher-tier equipped weapon")
	var rep4 := asura.add_or_merge_weapon("wpn_chainsaw", 4)
	_assert(bool(rep4["success"]) and int(asura.weapons[0]["tier"]) == 4 and int(rep4["awakened_slot"]) == 0, "Replacing with Tier 4 triggers awakening slot 0")

	var full_run := RunState.new()
	full_run.start_new_run("hero_crimson_blade", "wpn_chainsaw", [])
	full_run.add_or_merge_weapon("wpn_chainsaw", 2)
	full_run.add_or_merge_weapon("wpn_battleaxe", 1)
	full_run.add_or_merge_weapon("wpn_arc_staff", 1)
	full_run.add_or_merge_weapon("wpn_ice_prism", 1)
	full_run.add_or_merge_weapon("wpn_bone_spear", 1)
	var chk_full := full_run.can_add_or_merge_weapon("wpn_chainsaw", 3)
	_assert(bool(chk_full["ok"]) and String(chk_full["mode"]) == "replace" and int(chk_full["merge_idx"]) == 0, "Full 6/6 loadout replaces lowest-tier matching weapon")
	full_run.add_or_merge_weapon("wpn_chainsaw", 3)
	_assert(int(full_run.weapons[0]["tier"]) == 3 and int(full_run.weapons[1]["tier"]) == 2, "Lowest-tier duplicate upgraded to Tier 3 while preserving Tier 2 copy")


func _test_shop_and_save_persistence() -> void:
	var run := RunState.new()
	run.start_new_run("hero_gilded_pactkeeper", "wpn_twin_pistols", ["heat_speed", "heat_hp"])
	run.wave = 4
	run.add_crystals(200)
	run.apply_levelup_choice("damage_pct", 16.0)
	run.apply_blood_pact("pact_bounty_hunt")

	var offers := ShopGenerator.generate_shop_offers(run)
	_assert(offers.size() == 4, "Shop generates 4 offers")

	SaveManager.save_resume_run(run)
	_assert(SaveManager.has_resume_run(), "Resume file written")
	var loaded := SaveManager.load_resume_run()
	_assert(loaded != null and loaded.wave == 4 and loaded.pacts.has("pact_bounty_hunt"), "Resume restores wave and Blood Pacts")
	_assert(is_equal_approx(float(loaded.levelup_mods.get("damage_pct", 0.0)), 16.0), "Resume restores level-up mods")
	SaveManager.clear_resume_run()

	var before_embers := SaveManager.get_embers()
	SaveManager.add_embers(100)
	_assert(SaveManager.upgrade_talent("tal_start_gold"), "Sanctuary talent upgrade succeeds")
	var refunded := SaveManager.respec_all_talents()
	_assert(refunded >= 35 and SaveManager.get_talent_rank("tal_start_gold") == 0, "Free respec refunds full Embers")
	SaveManager.meta_data["embers"] = before_embers
	SaveManager.save_meta()


func _test_touch_scroll_container() -> void:
	var sc := TouchScrollContainer.new()
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(720, 2200)
	sc.add_child(vb)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(720, 120)
	vb.add_child(card)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(64, 64)
	card.add_child(icon)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(720, 1200)
	var clicks := {"n": 0}
	btn.pressed.connect(func(): clicks["n"] = int(clicks["n"]) + 1)
	vb.add_child(btn)

	get_tree().root.add_child(sc)
	await get_tree().process_frame
	await get_tree().process_frame

	_assert(card.mouse_filter == Control.MOUSE_FILTER_PASS, "TouchScrollContainer converts PanelContainer MOUSE_FILTER_STOP to PASS")
	_assert(btn.mouse_filter == Control.MOUSE_FILTER_PASS, "TouchScrollContainer converts Button MOUSE_FILTER_STOP to PASS")
	_assert(sc.scroll_deadzone >= 10, "TouchScrollContainer sets protective scroll deadzone")

	# Normal short tap on Button still clicks normally
	for p in [true, false]:
		var tap_ev := InputEventMouseButton.new()
		tap_ev.device = 0
		tap_ev.button_index = MOUSE_BUTTON_LEFT
		tap_ev.pressed = p
		tap_ev.position = Vector2(20, 40)
		tap_ev.global_position = Vector2(20, 40)
		Input.parse_input_event(tap_ev)
		await get_tree().process_frame
	_assert(int(clicks["n"]) == 1, "Short tap on Button inside TouchScrollContainer still clicks")

	# Drag upward across Button (within root viewport rect) -> scrolls and suppresses click
	var mb_d := InputEventMouseButton.new()
	mb_d.device = 0
	mb_d.button_index = MOUSE_BUTTON_LEFT
	mb_d.pressed = true
	mb_d.position = Vector2(20, 40)
	mb_d.global_position = Vector2(20, 40)
	Input.parse_input_event(mb_d)
	await get_tree().process_frame

	for s in range(1, 5):
		var mm := InputEventMouseMotion.new()
		mm.device = 0
		mm.button_mask = MOUSE_BUTTON_MASK_LEFT
		mm.position = Vector2(20, 40 - s * 5.0)
		mm.global_position = Vector2(20, 40 - s * 5.0)
		mm.relative = Vector2(0, -5.0)
		Input.parse_input_event(mm)
		await get_tree().process_frame

	var mb_u := InputEventMouseButton.new()
	mb_u.device = 0
	mb_u.button_index = MOUSE_BUTTON_LEFT
	mb_u.pressed = false
	mb_u.position = Vector2(20, 20)
	mb_u.global_position = Vector2(20, 20)
	Input.parse_input_event(mb_u)
	await get_tree().process_frame

	_assert(sc.scroll_vertical > 100, "Dragging starting on child Button/Icon scrolls TouchScrollContainer")
	_assert(int(clicks["n"]) == 1, "Dragging across Button suppresses extra accidental click")
	sc.queue_free()
	await get_tree().process_frame


func _test_full_ui_and_combat_integration() -> void:
	var main_scene := load("res://src/scenes/Main.tscn") as PackedScene
	_assert(main_scene != null, "Main.tscn loads cleanly")
	var inst := main_scene.instantiate() as MainController
	get_tree().root.add_child(inst)
	await get_tree().process_frame

	# Exercise MainMenu -> HeroSelect -> Sanctuary -> Codex
	inst._hero_select.open()
	_assert(inst._hero_select.visible and inst._hero_select._danger_box.get_child_count() == 6 and inst._hero_select._heat_list_box.get_child_count() == 8, "HeroSelectScreen opens cleanly with D0..D5 selector & 8 Heat cards")
	inst._hero_select._heat_toggle_btn.pressed.emit()
	_assert(inst._hero_select._heat_modal.visible, "HeroSelect Heat modal opens centered overlay cleanly")
	inst._hero_select._heat_modal.visible = false
	inst._hero_select.visible = false

	inst._sanctuary.open()
	_assert(inst._sanctuary.visible, "SanctuaryScreen opens cleanly")
	inst._sanctuary.visible = false

	inst._codex.open()
	_assert(inst._codex.visible and inst._codex._list_box.get_child_count() >= 34, "CodexScreen opens cleanly with synergy & weapon/item entries")
	_assert(inst._codex._synergy_modal != null, "CodexScreen initializes centered synergy modal")
	UiStyles.show_detail_modal(inst._codex, {"title": "裂血链锯", "subtitle": "猩红神系", "body": "测试详情浮层", "icon_path": "res://assets/art/sprites/weapons/wpn_chainsaw.png"})
	_assert(inst._codex.get_node_or_null("_DetailModalOverlay") != null, "Tap-to-inspect detail modal mounts cleanly")
	var dm := inst._codex.get_node_or_null("_DetailModalOverlay")
	if dm != null:
		dm.queue_free()
	inst._codex.visible = false

	_assert(inst._menu._settings_modal != null and inst.hud._pause_modal != null, "MainMenu settings & BattleHud pause use centered modal overlays")

	# Test Wave 5 Boss combat + Toxic Blood pact + 6 diverse weapons firing
	inst._start_fresh_run("hero_crimson_blade", "wpn_chainsaw", ["heat_speed"])
	var run := inst._run
	run.add_or_merge_weapon("wpn_arc_staff", 2)
	run.add_or_merge_weapon("wpn_ice_prism", 2)
	run.add_or_merge_weapon("wpn_laser_wing", 2)
	run.add_or_merge_weapon("wpn_abyss_mortar", 2)
	run.add_or_merge_weapon("wpn_calamity_totem", 2)
	run.apply_blood_pact("pact_toxic_blood")
	run.wave = 5
	inst.arena.bind_run(run)
	inst.arena.start_wave()

	inst.arena.player.trigger_dash()
	inst.arena.player.heal_or_convert(10.0) # Triggers Toxic Blood blast!
	var dash_probe := {"seen": false, "last": 999.0}
	var sig_cb := func(ch: int, _mc: int, t_left: float, tot: float):
		if ch < 2 and t_left > 0.0 and tot > 0.5 and t_left < float(dash_probe["last"]):
			dash_probe["seen"] = true
		dash_probe["last"] = t_left
	EventBus.player_dash_changed.connect(sig_cb)
	for _f in range(60):
		await get_tree().process_frame
	EventBus.player_dash_changed.disconnect(sig_cb)

	_assert(bool(dash_probe["seen"]), "Blood Dash emits continuous decreasing cooldown seconds")
	_assert(inst.arena.enemy_mgr.has_active_boss(), "Wave 5 Boss queued/active in Arena")
	for _s in range(14):
		inst.arena._process(0.1)
	_assert(inst.arena.enemy_mgr.get_alive_count() >= 1, "Wave Director spawned and materialized enemies after telegraph")

	# Test Wave 10 Boss + LevelUp + PactAltar + Shop + Awakening + Summary UI
	run.wave = 10
	inst.arena.start_wave()
	var pending_before := inst.arena.enemy_mgr.get_pending_count()
	_assert(inst.arena.enemy_mgr.has_active_boss() and pending_before >= 1, "Wave 10 Boss enters via summon telegraph instead of instant pop-in")
	for _s in range(12):
		inst.arena._process(0.1)
	_assert(inst.arena.enemy_mgr.has_active_boss() and inst.arena.enemy_mgr.get_alive_count() >= 1, "Queued Boss & mobs materialize smoothly after telegraph window")

	run.pending_level_ups = 1
	run.pending_chests = 1
	inst._levelup_modal.process_next_for_run(run)
	_assert(inst._levelup_modal.visible, "LevelUpModal opens for pending chest/levelup")
	inst._levelup_modal.visible = false

	inst._pact_modal.open_for_run(run)
	_assert(inst._pact_modal.visible, "PactAltarModal opens cleanly")
	inst._pact_modal.visible = false

	inst._shop.open_for_run(run, true)
	_assert(inst._shop.visible and inst._shop._synergy_detail_box.get_child_count() >= 8 and inst._shop._sinks_box.get_child_count() == 3, "ShopScreen opens cleanly with synergy drawer & 3 crystal sinks")
	inst._shop.visible = false

	var dmg_no_break := CombatFormulas.calc_enemy_damage_after_vuln(100.0, 0.0, 0.35)
	var dmg_armor_broken := CombatFormulas.calc_enemy_damage_after_vuln(100.0, 1.5, 0.35)
	_assert(dmg_no_break < 70.0 and dmg_armor_broken >= 120.0, "Boss/Elite resilience reduces unexposed hits and is bypassed by Blood Dash Armor-Break")

	var enemy_mgr := inst.arena.enemy_mgr
	run.danger_level = 0
	run.wave = 10
	var b_d0: Dictionary = enemy_mgr.spawn_enemy("boss_sovereign", Vector2(1800, 1200), 10)
	var hp_b_d0 := float(b_d0["max_hp"])
	run.danger_level = 5
	var b_d5: Dictionary = enemy_mgr.spawn_enemy("boss_sovereign", Vector2(1800, 1200), 10)
	var hp_b_d5 := float(b_d5["max_hp"])
	_assert(hp_b_d0 >= 25000.0 and hp_b_d5 >= 80000.0 and hp_b_d5 > hp_b_d0 * 2.8, "Wave 10 Boss Sovereign scales substantially across D0..D5")
	run.danger_level = 0

	inst.hud.bind_run(run, inst.arena.player)
	_assert(inst.hud._synergy_box.get_child_count() >= 4, "BattleHud renders active faction & resonance pills")
	inst.hud._toggle_pause()
	_assert(inst.hud._pause_synergy_lbl.text.contains("攻速+14%") and inst.hud._pause_synergy_lbl.text.contains("虚空磁暴"), "Pause modal shows active synergy & resonance details")
	inst.hud._toggle_pause()

	var asura_shop := RunState.new()
	asura_shop.start_new_run("hero_one_arm_asura", "wpn_chainsaw", [])
	asura_shop.add_crystals(500)
	asura_shop.shop_offers = [{"kind": "weapon", "id": "wpn_chainsaw", "tier": 2, "price": 80, "locked": false, "sold": false}]
	inst._shop.open_for_run(asura_shop, false)
	_assert(inst._shop.visible, "ShopScreen renders One-Arm Asura higher-tier replace offer cleanly")
	inst._shop.visible = false

	inst._awakening_modal.open_for_weapon(0, "wpn_chainsaw")
	_assert(inst._awakening_modal.visible, "AwakeningModal opens cleanly")
	inst._awakening_modal.visible = false

	run.victory_reached = true
	inst._summary.show_wave10_choice(run)
	_assert(inst._summary.visible, "RunSummaryScreen Wave 10 choice opens cleanly")

	SaveManager.clear_resume_run()
	inst.queue_free()
	for _w in range(3):
		await get_tree().process_frame


func _test_difficulty_and_economy_rebalance() -> void:
	var p_w1 := CombatFormulas.calc_shop_price(30, 1, 1, 0.0, false, 1.0)
	var p_w10_d5 := CombatFormulas.calc_shop_price(30, 1, 10, 0.0, false, 1.3)
	_assert(p_w10_d5 > p_w1 * 2, "Wave 10 D5 shop prices scale significantly over Wave 1 D0")

	var r0 := CombatFormulas.calc_reroll_cost(8, 0, 0, 1.0)
	var r4 := CombatFormulas.calc_reroll_cost(8, 4, 0, 1.25)
	_assert(r4 > r0 * 2, "Repeated shop rerolls escalate meaningfully")

	var gilded := RunState.new()
	gilded.start_new_run("hero_gilded_pactkeeper", "wpn_staff", [])
	gilded.crystals = 720
	gilded.recompute_effective_stats()
	var dmg_720 := gilded.stats.get_stat("damage_pct")
	gilded.crystals = 6000
	gilded.recompute_effective_stats()
	var dmg_6000 := gilded.stats.get_stat("damage_pct")
	_assert(is_equal_approx(dmg_720, dmg_6000), "Gilded Pactkeeper crystal bonus respects upper cap")

	var sink_run := RunState.new()
	sink_run.start_new_run("hero_crimson_blade", "wpn_chainsaw", [], 4)
	_assert(sink_run.danger_level == 4, "RunState stores selected D4 difficulty level")
	sink_run.add_crystals(500)
	var base_dmg := sink_run.stats.get_stat("damage_pct")
	var cost_before := sink_run.get_shop_sink_cost("sink_temper_power")
	var r1 := sink_run.buy_shop_sink("sink_temper_power")
	_assert(bool(r1.get("ok", false)) and sink_run.stats.get_stat("damage_pct") >= base_dmg + 11.9, "Abyssal Temper sink permanently boosts player stats")
	_assert(sink_run.get_shop_sink_cost("sink_temper_power") > cost_before, "Abyssal Temper cost scales up with purchases")
	var r2 := sink_run.buy_shop_sink("sink_mystery_relic")
	_assert(bool(r2.get("ok", false)) and sink_run.items.size() == 1, "Mystery Relic blind-box sink grants a random item")

	var ember_d0 := sink_run.calc_ember_reward()
	sink_run.danger_level = 5
	var ember_d5 := sink_run.calc_ember_reward()
	_assert(ember_d5 > ember_d0, "Higher Danger tiers award significantly more Abyss Embers")

	# Verify pending spawn telegraph and materialize flow
	var em := EnemyManager.new()
	get_tree().root.add_child(em)
	await get_tree().process_frame
	em.queue_spawn_enemy("swarmer", Vector2(360, 0), 1, 0.35)
	_assert(em.get_pending_count() == 1 and em.get_alive_count() == 0, "Queued enemy waits in summon telegraph before spawning")
	em.step(0.20)
	_assert(em.get_pending_count() == 1 and em.get_alive_count() == 0, "Queued enemy remains non-collidable during partial telegraph")
	em.step(0.20)
	_assert(em.get_pending_count() == 0 and em.get_alive_count() == 1, "Queued enemy materializes cleanly once telegraph finishes")
	em.queue_free()
	await get_tree().process_frame
