class_name MainController
extends Node
## Root application controller coordinating Menu, Sanctuary, Codex, Arena combat,
## between-wave Level-Ups / Blood Pacts / Shop / Red Awakenings, and Run Summary.

@onready var arena: ArenaController = $Arena
@onready var hud: BattleHud = $BattleHud
@onready var ui_layer: CanvasLayer = $UiLayer

var _run: RunState
var _menu: MainMenu
var _hero_select: HeroSelectScreen
var _sanctuary: SanctuaryScreen
var _codex: CodexScreen
var _levelup_modal: LevelUpModal
var _pact_modal: PactAltarModal
var _shop: ShopScreen
var _awakening_modal: AwakeningModal
var _summary: RunSummaryScreen


func _ready() -> void:
	_instantiate_ui()
	_connect_signals()
	_show_main_menu()


func _instantiate_ui() -> void:
	_menu = MainMenu.new()
	_hero_select = HeroSelectScreen.new()
	_sanctuary = SanctuaryScreen.new()
	_codex = CodexScreen.new()
	_levelup_modal = LevelUpModal.new()
	_pact_modal = PactAltarModal.new()
	_shop = ShopScreen.new()
	_awakening_modal = AwakeningModal.new()
	_summary = RunSummaryScreen.new()

	for w in [_menu, _hero_select, _sanctuary, _codex, _shop, _levelup_modal, _pact_modal, _awakening_modal, _summary]:
		ui_layer.add_child(w)


func _connect_signals() -> void:
	_menu.start_new_run_requested.connect(func():
		_menu.visible = false
		_hero_select.open()
	)
	_menu.resume_run_requested.connect(_on_resume_run)
	_menu.open_sanctuary_requested.connect(func():
		_menu.visible = false
		_sanctuary.open()
	)
	_menu.open_codex_requested.connect(func():
		_menu.visible = false
		_codex.open()
	)

	_hero_select.back_requested.connect(_show_main_menu)
	_hero_select.launch_run_requested.connect(_start_fresh_run)

	_sanctuary.back_requested.connect(_show_main_menu)
	_codex.back_requested.connect(_show_main_menu)

	arena.wave_completed.connect(_on_wave_completed)
	arena.game_over_triggered.connect(_on_game_over)
	hud.pause_exit_requested.connect(_show_main_menu)

	_levelup_modal.all_rewards_resolved.connect(_on_rewards_resolved)
	_pact_modal.pact_resolved.connect(_on_pact_resolved)
	_shop.awakening_needed.connect(func(slot_idx: int, wid: String):
		_awakening_modal.open_for_weapon(slot_idx, wid)
	)
	_awakening_modal.awakening_chosen.connect(_on_awakening_chosen)
	_shop.next_wave_requested.connect(_on_next_wave)

	_summary.continue_endless_requested.connect(_on_continue_endless)
	_summary.return_menu_requested.connect(_on_summary_done)


func _show_main_menu() -> void:
	get_tree().paused = false
	arena.visible = false
	arena.stop_and_clear()
	hud.visible = false
	_shop.visible = false
	_levelup_modal.visible = false
	_pact_modal.visible = false
	_awakening_modal.visible = false
	_summary.visible = false
	_hero_select.visible = false
	_sanctuary.visible = false
	_codex.visible = false
	AudioManager.stop_all_sfx()
	_menu.refresh_ui()
	_menu.visible = true
	EventBus.bgm_requested.emit("bgm_sanctuary")


func _start_fresh_run(hero_id: String, weapon_id: String, heats: Array[String], danger_level: int = 0) -> void:
	_run = RunState.new()
	_run.start_new_run(hero_id, weapon_id, heats, danger_level)
	SaveManager.active_run = _run
	_enter_combat()


func _on_resume_run() -> void:
	var loaded := SaveManager.load_resume_run()
	if loaded == null:
		_show_main_menu()
		return
	_run = loaded
	_menu.visible = false
	arena.bind_run(_run)
	hud.bind_run(_run, arena.player)
	if _run.phase == "pact":
		arena.visible = true
		hud.visible = false
		_pact_modal.open_for_run(_run)
	elif _run.phase == "shop":
		arena.visible = false
		hud.visible = false
		_shop.open_for_run(_run, false)
	else:
		_enter_combat()


func _enter_combat() -> void:
	_menu.visible = false
	_shop.visible = false
	arena.visible = true
	hud.visible = true
	arena.bind_run(_run)
	hud.bind_run(_run, arena.player)
	SaveManager.save_resume_run(_run)
	arena.start_wave()


func _on_wave_completed(_eco: Dictionary) -> void:
	hud.visible = false
	EventBus.bgm_requested.emit("bgm_sanctuary")
	if _run.wave == 10 and not _run.endless_mode:
		_summary.show_wave10_choice(_run)
		return
	_begin_intermission_flow()


func _on_continue_endless() -> void:
	_run.endless_mode = true
	_begin_intermission_flow()


func _begin_intermission_flow() -> void:
	if _run.pending_chests > 0 or _run.pending_level_ups > 0:
		_levelup_modal.process_next_for_run(_run)
	else:
		_on_rewards_resolved()


func _on_rewards_resolved() -> void:
	if _run.wave % 2 == 0 and _run.pacts.size() < GameData.pacts.size():
		_run.phase = "pact"
		SaveManager.save_resume_run(_run)
		_pact_modal.open_for_run(_run)
	else:
		_shop.open_for_run(_run, true)


func _on_pact_resolved(pact_id: String) -> void:
	if not pact_id.is_empty():
		_run.apply_blood_pact(pact_id)
	_shop.open_for_run(_run, true)


func _on_awakening_chosen(slot_idx: int, awakening_id: String) -> void:
	if slot_idx >= 0 and slot_idx < _run.weapons.size():
		_run.weapons[slot_idx]["awakening"] = awakening_id
		SaveManager.save_resume_run(_run)
		EventBus.weapon_awakened.emit(slot_idx, String(_run.weapons[slot_idx]["id"]), awakening_id)
		_shop.refresh_ui()


func _on_next_wave() -> void:
	_run.wave += 1
	_enter_combat()


func _on_game_over() -> void:
	hud.visible = false
	_run.is_run_over = true
	var report := SaveManager.commit_run_results(_run)
	_summary.show_final_summary(_run, report)


func _on_summary_done() -> void:
	if _run != null and not _run.is_run_over:
		_run.is_run_over = true
		var report := SaveManager.commit_run_results(_run)
		_summary.show_final_summary(_run, report)
		return
	_show_main_menu()
