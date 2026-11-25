extends Node
## Manages permanent meta-progression (user://meta_save.json) and mid-run resume
## persistence (user://run_resume.json), including Sanctuary respec, weapon mastery,
## hero challenge unlocks, ban slots, and settings.

const META_PATH := "user://meta_save.json"
const RESUME_PATH := "user://run_resume.json"

var meta_data: Dictionary = {}
var active_run: RunState = null


func _ready() -> void:
	load_meta()


func _default_meta() -> Dictionary:
	return {
		"version": 1,
		"embers": 60,
		"talents": {},
		"unlocked_heroes": ["hero_crimson_blade", "hero_azure_arcanist"],
		"weapon_kills": {},
		"ban_list": [],
		"selected_heats": [],
		"selected_danger": 0,
		"best_danger_cleared": -1,
		"best_wave": 0,
		"best_kills": 0,
		"total_runs": 0,
		"total_victories": 0,
		"settings": {
			"bgm_volume": 0.72,
			"sfx_volume": 0.85,
			"vfx_opacity": 0.90,
			"screen_shake": true,
		},
	}


func load_meta() -> void:
	meta_data = _default_meta()
	if not FileAccess.file_exists(META_PATH):
		save_meta()
		return
	var f := FileAccess.open(META_PATH, FileAccess.READ)
	if f == null:
		return
	var txt := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) == TYPE_DICTIONARY:
		var def := _default_meta()
		for k in def:
			if parsed.has(k):
				meta_data[k] = parsed[k]
		if typeof(meta_data["settings"]) == TYPE_DICTIONARY:
			for sk in def["settings"]:
				if not meta_data["settings"].has(sk):
					meta_data["settings"][sk] = def["settings"][sk]


func save_meta() -> void:
	var f := FileAccess.open(META_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(meta_data, "\t"))
	f.close()


func get_embers() -> int:
	return int(meta_data.get("embers", 0))


func add_embers(amount: int) -> void:
	meta_data["embers"] = maxi(0, get_embers() + amount)
	save_meta()


func get_talent_rank(talent_id: String) -> int:
	var t_dict: Dictionary = meta_data.get("talents", {})
	return int(t_dict.get(talent_id, 0))


func get_talent_value(talent_id: String) -> float:
	var tdef := GameData.get_talent(talent_id)
	return float(get_talent_rank(talent_id)) * float(tdef.get("per_rank", 0.0))


func get_talent_next_cost(talent_id: String) -> int:
	var tdef := GameData.get_talent(talent_id)
	var rank := get_talent_rank(talent_id)
	if rank >= int(tdef.get("max_rank", 1)):
		return -1
	return int(tdef.get("base_cost", 30)) + rank * int(tdef.get("cost_step", 20))


func upgrade_talent(talent_id: String) -> bool:
	var cost := get_talent_next_cost(talent_id)
	if cost < 0 or get_embers() < cost:
		return false
	meta_data["embers"] = get_embers() - cost
	var t_dict: Dictionary = meta_data.get("talents", {})
	t_dict[talent_id] = int(t_dict.get(talent_id, 0)) + 1
	meta_data["talents"] = t_dict
	save_meta()
	return true


func respec_all_talents() -> int:
	var refunded := 0
	var t_dict: Dictionary = meta_data.get("talents", {})
	for tid in t_dict:
		var rank := int(t_dict[tid])
		var tdef := GameData.get_talent(String(tid))
		var base_c := int(tdef.get("base_cost", 30))
		var step_c := int(tdef.get("cost_step", 20))
		for r in range(rank):
			refunded += base_c + r * step_c
	meta_data["talents"] = {}
	meta_data["embers"] = get_embers() + refunded
	# Trim ban list if ban slots reduced
	var max_bans := get_max_ban_slots()
	var bans: Array = meta_data.get("ban_list", [])
	while bans.size() > max_bans:
		bans.pop_back()
	meta_data["ban_list"] = bans
	save_meta()
	return refunded


func is_hero_unlocked(hero_id: String) -> bool:
	var unlocked: Array = meta_data.get("unlocked_heroes", [])
	return unlocked.has(hero_id)


func unlock_hero(hero_id: String, pay_embers: bool = false) -> bool:
	if is_hero_unlocked(hero_id):
		return false
	if pay_embers:
		var hdef := GameData.get_hero(hero_id)
		var cost := int(hdef.get("unlock_cost", 999))
		if get_embers() < cost:
			return false
		meta_data["embers"] = get_embers() - cost
	var unlocked: Array = meta_data.get("unlocked_heroes", [])
	unlocked.append(hero_id)
	meta_data["unlocked_heroes"] = unlocked
	save_meta()
	return true


func get_weapon_kills(weapon_id: String) -> int:
	var wk: Dictionary = meta_data.get("weapon_kills", {})
	return int(wk.get(weapon_id, 0))


func get_weapon_mastery_level(weapon_id: String) -> int:
	var k := get_weapon_kills(weapon_id)
	if k >= 450:
		return 5
	if k >= 240:
		return 4
	if k >= 120:
		return 3
	if k >= 40:
		return 2
	return 1


func get_weapon_next_threshold(level: int) -> int:
	match level:
		1: return 40
		2: return 120
		3: return 240
		4: return 450
		_: return 450


func get_max_ban_slots() -> int:
	return int(roundf(get_talent_value("tal_ban_slots")))


func get_ban_list() -> Array[String]:
	var out: Array[String] = []
	for x in meta_data.get("ban_list", []):
		out.append(String(x))
	return out


func toggle_ban_entry(entry_id: String) -> String:
	var bans := get_ban_list()
	if bans.has(entry_id):
		bans.erase(entry_id)
		meta_data["ban_list"] = bans
		save_meta()
		return "unbanned"
	if bans.size() >= get_max_ban_slots():
		return "full"
	bans.append(entry_id)
	meta_data["ban_list"] = bans
	save_meta()
	return "banned"


func get_selected_heats() -> Array[String]:
	var out: Array[String] = []
	for h in meta_data.get("selected_heats", []):
		out.append(String(h))
	return out


func set_selected_heats(heats_arr: Array[String]) -> void:
	meta_data["selected_heats"] = heats_arr
	save_meta()


func get_selected_danger() -> int:
	return clampi(int(meta_data.get("selected_danger", 0)), 0, 5)


func set_selected_danger(level: int) -> void:
	meta_data["selected_danger"] = clampi(level, 0, 5)
	save_meta()


func get_best_danger_cleared() -> int:
	return int(meta_data.get("best_danger_cleared", -1))


func get_setting(key: String, default_val: Variant = null) -> Variant:
	var s: Dictionary = meta_data.get("settings", {})
	return s.get(key, default_val)


func set_setting(key: String, val: Variant) -> void:
	var s: Dictionary = meta_data.get("settings", {})
	s[key] = val
	meta_data["settings"] = s
	save_meta()


func save_resume_run(run: RunState) -> void:
	if run == null or run.is_run_over:
		return
	var f := FileAccess.open(RESUME_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(run.to_dict()))
	f.close()


func has_resume_run() -> bool:
	return FileAccess.file_exists(RESUME_PATH)


func load_resume_run() -> RunState:
	if not FileAccess.file_exists(RESUME_PATH):
		return null
	var f := FileAccess.open(RESUME_PATH, FileAccess.READ)
	if f == null:
		return null
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	var run := RunState.new()
	run.from_dict(parsed)
	active_run = run
	return run


func clear_resume_run() -> void:
	if FileAccess.file_exists(RESUME_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RESUME_PATH))


func commit_run_results(run: RunState) -> Dictionary:
	var earned_embers := run.calc_ember_reward()
	meta_data["embers"] = get_embers() + earned_embers
	meta_data["total_runs"] = int(meta_data.get("total_runs", 0)) + 1
	if run.victory_reached:
		meta_data["total_victories"] = int(meta_data.get("total_victories", 0)) + 1
		if run.danger_level > get_best_danger_cleared():
			meta_data["best_danger_cleared"] = run.danger_level
	if run.wave > int(meta_data.get("best_wave", 0)):
		meta_data["best_wave"] = run.wave
	if run.total_kills > int(meta_data.get("best_kills", 0)):
		meta_data["best_kills"] = run.total_kills

	var wk: Dictionary = meta_data.get("weapon_kills", {})
	for wid in run.weapon_kills_this_run:
		wk[wid] = int(wk.get(wid, 0)) + int(run.weapon_kills_this_run[wid])
	meta_data["weapon_kills"] = wk

	var newly_unlocked: Array[String] = []
	# Challenge unlocks
	if run.wave >= 3 and _all_melee(run) and unlock_hero("hero_frenzied_butcher", false):
		newly_unlocked.append("狂战屠夫")
	if run.victory_reached and run.pacts.size() >= 2 and unlock_hero("hero_one_arm_asura", false):
		newly_unlocked.append("独臂修罗")
	if run.max_crystals_held >= 300 and unlock_hero("hero_gilded_pactkeeper", false):
		newly_unlocked.append("契约守财奴")
	if run.bosses_killed >= 2 and unlock_hero("hero_void_weaver", false):
		newly_unlocked.append("虚空织命者")

	save_meta()
	clear_resume_run()
	return {
		"embers_earned": earned_embers,
		"newly_unlocked": newly_unlocked,
	}


func _all_melee(run: RunState) -> bool:
	if run.weapons.is_empty():
		return false
	for w in run.weapons:
		var wdef := GameData.get_weapon(String(w["id"]))
		if String(wdef.get("weapon_class", "")) != "melee":
			return false
	return true
