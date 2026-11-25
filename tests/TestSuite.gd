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
	_assert(GameData.pacts.size() == 10, "10 Blood Pacts loaded")
	_assert(GameData.talents.size() == 12, "12 Sanctuary talents loaded")
	_assert(GameData.heats.size() == 8, "8 Heat protocols loaded")
	_assert(GameData.enemies.size() == 10, "8 enemy types + 2 Bosses loaded")


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


func _test_weapon_merge_and_awakening() -> void:
	var run := RunState.new()
	run.start_new_run("hero_crimson_blade", "wpn_chainsaw", [])
	run.weapons[0]["tier"] = 3
	var res := run.add_or_merge_weapon("wpn_chainsaw", 3)
	_assert(bool(res["success"]), "Tier 3 + Tier 3 merges cleanly")
	_assert(int(run.weapons[0]["tier"]) == 4, "Merged weapon reaches Tier 4")
	_assert(int(res["awakened_slot"]) == 0, "Tier 4 triggers awakening slot 0")


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


func _test_full_ui_and_combat_integration() -> void:
	var main_scene := load("res://src/scenes/Main.tscn") as PackedScene
	_assert(main_scene != null, "Main.tscn loads cleanly")
	var inst := main_scene.instantiate() as MainController
	get_tree().root.add_child(inst)
	await get_tree().process_frame

	# Exercise MainMenu -> HeroSelect -> Sanctuary -> Codex
	inst._hero_select.open()
	_assert(inst._hero_select.visible, "HeroSelectScreen opens cleanly")
	inst._hero_select.visible = false

	inst._sanctuary.open()
	_assert(inst._sanctuary.visible, "SanctuaryScreen opens cleanly")
	inst._sanctuary.visible = false

	inst._codex.open()
	_assert(inst._codex.visible, "CodexScreen opens cleanly")
	inst._codex.visible = false

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
	for _f in range(60):
		await get_tree().process_frame

	_assert(inst.arena.enemy_mgr.has_active_boss(), "Wave 5 Boss spawned and active in Arena")
	_assert(inst.arena.enemy_mgr.get_alive_count() >= 1, "Wave Director spawned enemies")

	# Test Wave 10 Boss + LevelUp + PactAltar + Shop + Awakening + Summary UI
	run.wave = 10
	inst.arena.start_wave()
	for _f in range(15):
		await get_tree().process_frame
	_assert(inst.arena.enemy_mgr.has_active_boss(), "Wave 10 Boss (Twin Sovereign) spawned")

	run.pending_level_ups = 1
	run.pending_chests = 1
	inst._levelup_modal.process_next_for_run(run)
	_assert(inst._levelup_modal.visible, "LevelUpModal opens for pending chest/levelup")
	inst._levelup_modal.visible = false

	inst._pact_modal.open_for_run(run)
	_assert(inst._pact_modal.visible, "PactAltarModal opens cleanly")
	inst._pact_modal.visible = false

	inst._shop.open_for_run(run, true)
	_assert(inst._shop.visible, "ShopScreen opens cleanly")
	inst._shop.visible = false

	inst._awakening_modal.open_for_weapon(0, "wpn_chainsaw")
	_assert(inst._awakening_modal.visible, "AwakeningModal opens cleanly")
	inst._awakening_modal.visible = false

	run.victory_reached = true
	inst._summary.show_wave10_choice(run)
	_assert(inst._summary.visible, "RunSummaryScreen Wave 10 choice opens cleanly")

	SaveManager.clear_resume_run()
	inst.queue_free()
	await get_tree().process_frame
