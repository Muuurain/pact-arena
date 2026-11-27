class_name WeaponRig
extends Node2D
## Manages up to 6 floating weapon slots orbiting the player, independent auto-aim,
## all 14 weapon attack patterns + 28 Red Awakenings, and deployed turrets/drones.

var _run: RunState
var _player: PlayerController
var _enemy_mgr: EnemyManager
var _proj_mgr: ProjectileManager
var _vfx: VfxManager

var _slot_nodes: Array[Dictionary] = []
var _turrets: Array[Dictionary] = []
var _attack_counter: int = 0
var _vibro_count: int = 0
var _orbit_angle: float = 0.0


func setup(run: RunState, player: PlayerController, enemy_mgr: EnemyManager, proj_mgr: ProjectileManager, vfx: VfxManager) -> void:
	_run = run
	_player = player
	_enemy_mgr = enemy_mgr
	_proj_mgr = proj_mgr
	_vfx = vfx
	rebuild_weapons()


func clear_all() -> void:
	for sn in _slot_nodes:
		if is_instance_valid(sn["sprite"]):
			(sn["sprite"] as Node).queue_free()
		if sn.has("aura") and is_instance_valid(sn["aura"]):
			(sn["aura"] as Node).queue_free()
	_slot_nodes.clear()
	clear_turrets()


func rebuild_weapons() -> void:
	clear_all()

	if _run == null:
		return

	var count := _run.weapons.size()
	var glow_tex: Texture2D = load("res://assets/art/sprites/projectiles/glow_soft.png")
	for i in range(count):
		var w_entry: Dictionary = _run.weapons[i]
		var wdef := GameData.get_weapon(String(w_entry["id"]))
		var tier := int(w_entry.get("tier", 1))
		var sc := 0.34 + float(tier - 1) * 0.025
		if _run.hero_id == "hero_one_arm_asura":
			sc *= 1.38

		var aura := Sprite2D.new()
		aura.texture = glow_tex
		aura.scale = Vector2.ONE * (sc * 1.4)
		aura.modulate = UiStyles.tier_color(tier)
		aura.modulate.a = 0.0 if tier == 1 else (0.28 + float(tier - 2) * 0.14)
		aura.z_index = 36
		add_child(aura)

		var sp := Sprite2D.new()
		sp.texture = load(String(wdef.get("sprite", "")))
		sp.scale = Vector2.ONE * sc
		sp.z_index = 38
		add_child(sp)
		_slot_nodes.append({
			"idx": i,
			"sprite": sp,
			"aura": aura,
			"base_scale": sc,
			"cooldown": randf_range(0.05, 0.25),
			"recoil": 0.0,
			"swing_anim": 0.0,
			"swing_sign": 1.0,
			"aim_angle": 0.0,
			"turret_deployed": false,
		})


func clear_turrets() -> void:
	for t in _turrets:
		if is_instance_valid(t["sprite"]):
			(t["sprite"] as Node).queue_free()
	_turrets.clear()


func reset_melee_cooldowns() -> void:
	for sn in _slot_nodes:
		var idx := int(sn["idx"])
		if idx < _run.weapons.size():
			var wdef := GameData.get_weapon(String(_run.weapons[idx]["id"]))
			if String(wdef.get("weapon_class", "")) == "melee":
				sn["cooldown"] = 0.0


func step(delta: float) -> void:
	if _run == null or _run.is_run_over:
		return
	_orbit_angle += delta * 1.35
	var dyn := _run.get_dynamic_combat_mods()
	var dmg_pct_add := float(dyn["damage_pct_add"])
	var as_pct_add := float(dyn["attack_speed_pct_add"])
	var flags: Dictionary = _run.synergy_info.get("flags", {})
	var extra_pierce := int(flags.get("extra_pierce", 0))
	var melee_range_mult := float(flags.get("melee_range_mult", 1.0))

	var count := maxi(1, _slot_nodes.size())
	for i in range(_slot_nodes.size()):
		if i >= _run.weapons.size():
			continue
		var sn: Dictionary = _slot_nodes[i]
		var w_entry: Dictionary = _run.weapons[i]
		var wid := String(w_entry["id"])
		var tier := int(w_entry.get("tier", 1))
		var awk := String(w_entry.get("awakening", ""))
		var wdef := GameData.get_weapon(wid)

		var base_ang := _orbit_angle + float(i) * (TAU / float(count))
		var bob := Vector2(0.0, sin(_orbit_angle * 2.5 + float(i) * 1.1) * 3.5)
		var anchor := _player.global_position + Vector2.from_angle(base_ang) * 52.0 + bob

		sn["recoil"] = maxf(0.0, float(sn["recoil"]) - delta * 6.0)
		sn["swing_anim"] = maxf(0.0, float(sn["swing_anim"]) - delta * 6.5)
		sn["cooldown"] = float(sn["cooldown"]) - delta

		var eff_range := maxf(80.0, float(wdef["base_range"]) + _run.stats.get_stat("range_bonus"))
		if String(wdef["weapon_class"]) == "melee":
			eff_range *= melee_range_mult
			if awk == "awk_chainsaw_spin" or awk == "awk_spear_lance":
				eff_range *= 1.45

		var nearest := _enemy_mgr.find_nearest_pos(anchor, eff_range)
		var sp: Sprite2D = sn["sprite"]
		var aura: Sprite2D = sn["aura"]
		if nearest.has("found"):
			var target_dir := (Vector2(nearest["pos"]) - anchor).normalized()
			sn["aim_angle"] = lerp_angle(float(sn["aim_angle"]), target_dir.angle(), minf(1.0, delta * 18.0))
		else:
			sn["aim_angle"] = lerp_angle(float(sn["aim_angle"]), base_ang, minf(1.0, delta * 8.0))

		var is_melee := String(wdef["weapon_class"]) == "melee"
		var swing := float(sn["swing_anim"])
		var swing_offset := sin((1.0 - swing) * PI) * 1.25 * float(sn["swing_sign"]) if (is_melee and swing > 0.0) else 0.0
		var lunge := (float(sn["recoil"]) * 34.0) if is_melee else (-float(sn["recoil"]) * 14.0)
		var final_ang := float(sn["aim_angle"]) + swing_offset
		var pos := anchor + Vector2.from_angle(float(sn["aim_angle"])) * lunge
		var bs := float(sn.get("base_scale", 0.34))
		var punch := 1.0 + swing * 0.28

		sp.global_position = pos
		sp.rotation = final_ang
		sp.flip_v = absf(wrapf(final_ang, -PI, PI)) > PI * 0.5
		sp.scale = Vector2.ONE * (bs * punch)
		aura.global_position = pos
		aura.rotation += delta * 2.2

		# Turret deployment once per wave per totem
		if String(wdef["pattern"]) == "turret_deploy" and not bool(sn["turret_deployed"]):
			sn["turret_deployed"] = true
			_spawn_turret(anchor + Vector2(randf_range(-40, 40), randf_range(-40, 40)), wdef, tier, awk)
			if awk == "awk_totem_dual":
				_spawn_turret(anchor + Vector2(randf_range(-70, 70), randf_range(-70, 70)), wdef, tier, awk)

		if float(sn["cooldown"]) <= 0.0 and nearest.has("found"):
			var bonus_as := as_pct_add
			if awk == "awk_axe_vamp" or awk == "awk_vibro_sonic" or awk == "awk_grim_fleet":
				bonus_as += 32.0
			if String(wdef["weapon_class"]) == "summon":
				bonus_as += float(flags.get("summon_speed_pct", 0.0))

			sn["cooldown"] = CombatFormulas.calc_weapon_cooldown(wdef, tier, _run.stats, bonus_as)
			sn["recoil"] = 1.0
			if is_melee and String(wdef["pattern"]) != "thrust":
				sn["swing_anim"] = 1.0
				sn["swing_sign"] = -float(sn["swing_sign"])
			else:
				_vfx.spawn_burst(anchor + Vector2.from_angle(float(sn["aim_angle"])) * 26.0, UiStyles.faction_color(String(wdef["faction"])), 24.0, 0.11)
			_fire_weapon(sn, w_entry, wdef, anchor, nearest, dmg_pct_add, extra_pierce, eff_range)

	_step_turrets(delta, dmg_pct_add, extra_pierce, flags)


func _fire_weapon(
	sn: Dictionary,
	w_entry: Dictionary,
	wdef: Dictionary,
	anchor: Vector2,
	nearest: Dictionary,
	dmg_pct_add: float,
	extra_pierce: int,
	eff_range: float
) -> void:
	var wid := String(w_entry["id"])
	var tier := int(w_entry.get("tier", 1))
	var awk := String(w_entry.get("awakening", ""))
	var faction := String(wdef["faction"])
	var pattern := String(wdef["pattern"])
	var aim_pos := Vector2(nearest["pos"])
	var aim_dir := (aim_pos - anchor).normalized()

	var extra_mult := 1.0 + dmg_pct_add / 100.0
	if _run.hero_id == "hero_void_weaver" and String(wdef["scale_tag"]) == "elemental":
		extra_mult *= 1.38
	if awk == "awk_chainsaw_drill":
		extra_mult *= 1.45

	var dmg_info := CombatFormulas.calc_weapon_damage(wdef, tier, _run.stats, _run.pacts, extra_mult)
	if awk == "awk_pistol_snipe" and not bool(dmg_info["is_crit"]) and randf() < 0.35:
		dmg_info["is_crit"] = true
		dmg_info["damage"] = float(dmg_info["damage"]) * (_run.stats.get_stat("crit_mult_pct") / 100.0)

	var dmg := float(dmg_info["damage"])
	var is_crit := bool(dmg_info["is_crit"])
	var kb := float(wdef.get("knockback", 50.0))
	var sfx_id := String(wdef.get("sfx", "sfx_slash"))
	EventBus.sfx_requested.emit(sfx_id, 0.12)

	_attack_counter += 1
	var flags: Dictionary = _run.synergy_info.get("flags", {})
	if bool(flags.get("superconduct", false)) and _attack_counter % 3 == 0:
		_fire_chain_lightning(anchor, nearest["enemy"], dmg * 0.75, 4, wid, "")

	match pattern:
		"arc_sweep", "heavy_cleave", "rapid_stab":
			var is_360 := (awk == "awk_chainsaw_spin")
			var arc_col := Color(0.28, 0.85, 1.0) if faction == "azure" else Color(0.98, 0.28, 0.42)
			var flip_swing := float(sn["swing_sign"]) < 0.0
			_vfx.spawn_slash_arc(anchor, aim_dir.angle(), eff_range * 0.82, arc_col, is_360, flip_swing, pattern == "heavy_cleave")
			var hits := _enemy_mgr.query_radius(anchor, eff_range)
			for e in hits:
				var to_e := Vector2(e["pos"]) - anchor
				if to_e.length() > eff_range + float(e["radius"]):
					continue
				if not is_360 and to_e.normalized().dot(aim_dir) < 0.15:
					continue
				if awk == "awk_chainsaw_drill":
					_enemy_mgr.apply_armor_break(e, 4.0)
					e["bleed_timer"] = 4.0
					e["bleed_dps"] = maxf(float(e["bleed_dps"]), dmg * 0.55)
				_enemy_mgr.apply_hit_to_enemy(e, dmg, is_crit, aim_dir * kb, faction, wid, false, true)
			if awk == "awk_axe_quake":
				var quake_p := anchor + aim_dir * (eff_range * 0.65)
				_vfx.spawn_burst(quake_p, Color(0.98, 0.28, 0.42), 160.0, 0.25)
				_enemy_mgr.damage_in_radius(quake_p, 160.0, dmg * 0.65, false, false, true, false, wid)
			if pattern == "rapid_stab":
				_vibro_count += 1
				if awk == "awk_vibro_wave" and _vibro_count % 3 == 0:
					_vfx.spawn_burst(anchor, Color(0.35, 0.9, 1.0), 220.0, 0.24)
					_enemy_mgr.damage_in_radius(anchor, 220.0, dmg * 1.15, is_crit, true, false, false, wid)

		"thrust":
			var angles := [0.0, -0.22, 0.22] if awk == "awk_spear_triple" else [0.0]
			for off in angles:
				var d := aim_dir.rotated(off)
				var end_p := anchor + d * eff_range
				_vfx.spawn_beam(anchor, end_p, 16.0, Color(1.0, 0.3, 0.45), 0.16)
				_hit_along_line(anchor, end_p, 28.0, dmg, is_crit, d * kb, faction, wid)
				if awk == "awk_spear_lance":
					_vfx.spawn_burst(end_p, Color(1.0, 0.25, 0.42), 95.0, 0.22)
					_enemy_mgr.damage_in_radius(end_p, 95.0, dmg * 0.7, false, false, false, false, wid)

		"orbit_scythe":
			var count := 2 if awk == "awk_scythe_twin" else 1
			for k in range(count):
				var d := aim_dir.rotated(0.25 * float(k) - (0.12 if count == 2 else 0.0))
				_proj_mgr.spawn_player_projectile({
					"pos": anchor,
					"vel": d * float(wdef["proj_speed"]),
					"speed": float(wdef["proj_speed"]),
					"damage": dmg,
					"is_crit": is_crit,
					"knockback": kb,
					"pierce": 99,
					"life": 1.15,
					"kind": "boomerang",
					"faction": faction,
					"weapon_id": wid,
					"awakening": awk,
					"radius": 24.0,
				})

		"twin_shot":
			var angles := [-0.15, -0.05, 0.05, 0.15] if awk == "awk_pistol_fan" else [-0.04, 0.04]
			var pierce := (4 if awk == "awk_pistol_snipe" else 1) + extra_pierce
			for off in angles:
				var d := aim_dir.rotated(off)
				_proj_mgr.spawn_player_projectile({
					"pos": anchor,
					"vel": d * float(wdef["proj_speed"]),
					"speed": float(wdef["proj_speed"]),
					"damage": dmg,
					"is_crit": is_crit,
					"knockback": kb,
					"pierce": pierce,
					"faction": faction,
					"weapon_id": wid,
					"awakening": awk,
				})

		"chain_lightning":
			var jumps := 9 if awk == "awk_arc_matrix" else (int(wdef["bounces"]) + extra_pierce)
			_fire_chain_lightning(anchor, nearest["enemy"], dmg, jumps, wid, awk)

		"ice_cone":
			var count := 5 if awk == "awk_ice_nova" else 3
			var spread := 0.22
			for k in range(count):
				var off := (float(k) - float(count - 1) * 0.5) * spread
				var d := aim_dir.rotated(off)
				_proj_mgr.spawn_player_projectile({
					"pos": anchor,
					"vel": d * float(wdef["proj_speed"]),
					"speed": float(wdef["proj_speed"]),
					"damage": dmg,
					"is_crit": is_crit,
					"knockback": kb,
					"pierce": int(wdef["pierce"]) + extra_pierce,
					"chill": true,
					"faction": faction,
					"weapon_id": wid,
					"awakening": awk,
				})

		"laser_beam":
			var end_p := anchor + aim_dir * eff_range
			var w_px := 22.0 if awk == "awk_laser_over" else 14.0
			_vfx.spawn_beam(anchor, end_p, w_px, Color(0.28, 0.85, 1.0), 0.18)
			_hit_along_line(anchor, end_p, w_px + 12.0, dmg * (1.45 if awk == "awk_laser_over" else 1.0), is_crit, aim_dir * kb, faction, wid, awk == "awk_laser_over")
			if awk == "awk_laser_twin":
				var second_d := aim_dir.rotated(0.35)
				_vfx.spawn_beam(anchor, anchor + second_d * eff_range, 14.0, Color(0.28, 0.85, 1.0), 0.18)
				_hit_along_line(anchor, anchor + second_d * eff_range, 24.0, dmg * 0.9, is_crit, second_d * kb, faction, wid)

		"ricochet_orb":
			var bounces := (7 if awk == "awk_ion_storm" else int(wdef["bounces"])) + extra_pierce
			_proj_mgr.spawn_player_projectile({
				"pos": anchor,
				"vel": aim_dir * float(wdef["proj_speed"]),
				"speed": float(wdef["proj_speed"]),
				"damage": dmg,
				"is_crit": is_crit,
				"knockback": kb,
				"pierce": 1 + extra_pierce,
				"bounces": bounces,
				"faction": faction,
				"weapon_id": wid,
				"awakening": awk,
			})

		"homing_bone", "summon_drone":
			var count := 3 if awk == "awk_bone_swarm" else (2 if awk == "awk_grim_fleet" else 1)
			for k in range(count):
				var off := (float(k) - float(count - 1) * 0.5) * 0.28
				_proj_mgr.spawn_player_projectile({
					"pos": anchor,
					"vel": aim_dir.rotated(off) * float(wdef["proj_speed"]),
					"speed": float(wdef["proj_speed"]),
					"damage": dmg,
					"is_crit": is_crit,
					"knockback": kb,
					"pierce": int(wdef["pierce"]) + extra_pierce,
					"homing": 8.5,
					"faction": faction,
					"weapon_id": wid,
					"awakening": awk,
				})

		"mortar_aoe":
			var count := 3 if awk == "awk_mortar_tri" else 1
			for k in range(count):
				var target := aim_pos + Vector2(randf_range(-55, 55), randf_range(-55, 55)) * (1.0 if k > 0 else 0.0)
				_proj_mgr.spawn_player_projectile({
					"pos": anchor,
					"vel": (target - anchor).normalized() * float(wdef["proj_speed"]),
					"speed": float(wdef["proj_speed"]),
					"damage": dmg,
					"is_crit": is_crit,
					"knockback": kb,
					"kind": "mortar",
					"target_pos": target,
					"aoe_radius": 125.0,
					"life": 1.6,
					"faction": faction,
					"weapon_id": wid,
					"awakening": awk,
				})

		"turret_deploy":
			# Totem deploys autonomous turret on arena; slot itself fires backup bolt
			_proj_mgr.spawn_player_projectile({
				"pos": anchor,
				"vel": aim_dir * float(wdef["proj_speed"]),
				"speed": float(wdef["proj_speed"]),
				"damage": dmg * 0.75,
				"is_crit": is_crit,
				"knockback": kb,
				"pierce": 1 + extra_pierce,
				"faction": faction,
				"weapon_id": wid,
				"awakening": awk,
			})


func _fire_chain_lightning(origin: Vector2, first_enemy: Dictionary, dmg: float, jumps: int, wid: String, awk: String) -> void:
	var pts := PackedVector2Array([origin])
	var visited := {}
	var cur: Dictionary = first_enemy
	var cur_dmg := dmg
	for j in range(jumps):
		if cur.is_empty() or not bool(cur["alive"]):
			break
		var uid := int(cur["uid"])
		visited[uid] = true
		var pos := Vector2(cur["pos"])
		pts.append(pos)
		_enemy_mgr.apply_hit_to_enemy(cur, cur_dmg, j == 0 and randf() * 100.0 < _run.stats.get_stat("crit_chance_pct"), Vector2.ZERO, "azure", wid, false, j == 0)
		if j == 0 and awk == "awk_arc_pillar":
			_vfx.spawn_burst(pos, Color(0.35, 0.85, 1.0), 120.0, 0.25)
			_enemy_mgr.damage_in_radius(pos, 120.0, dmg * 0.8, false, true, false, false, wid)
		if awk != "awk_arc_matrix":
			cur_dmg *= 0.88
		var nxt := _enemy_mgr.find_nearest_pos(pos, 240.0, visited)
		cur = nxt.get("enemy", {})
	_vfx.spawn_lightning_chain(pts, Color(0.32, 0.88, 1.0))


func _hit_along_line(a: Vector2, b: Vector2, half_w: float, dmg: float, is_crit: bool, kb_vec: Vector2, faction: String, wid: String, apply_break: bool = false) -> void:
	var mid := (a + b) * 0.5
	var rad := a.distance_to(b) * 0.5 + half_w + 30.0
	for e in _enemy_mgr.query_radius(mid, rad):
		var d := EnemyManager._dist_to_segment(Vector2(e["pos"]), a, b)
		if d <= half_w + float(e["radius"]):
			if apply_break:
				_enemy_mgr.apply_armor_break(e, 3.0)
			_enemy_mgr.apply_hit_to_enemy(e, dmg, is_crit, kb_vec, faction, wid, false, true)


func _spawn_turret(pos: Vector2, wdef: Dictionary, tier: int, awk: String) -> void:
	pos.x = clampf(pos.x, -500.0, 500.0)
	pos.y = clampf(pos.y, -580.0, 580.0)
	var sp := Sprite2D.new()
	sp.texture = load(String(wdef["sprite"]))
	sp.global_position = pos
	sp.scale = Vector2(0.45, 0.45)
	sp.z_index = 26
	add_child(sp)
	_turrets.append({
		"pos": pos,
		"sprite": sp,
		"wdef": wdef,
		"tier": tier,
		"awk": awk,
		"cooldown": 0.3,
	})


func _step_turrets(delta: float, dmg_pct_add: float, extra_pierce: int, flags: Dictionary) -> void:
	for t in _turrets:
		t["cooldown"] = float(t["cooldown"]) - delta
		if float(t["cooldown"]) > 0.0:
			continue
		var wdef: Dictionary = t["wdef"]
		var tier := int(t["tier"])
		var awk := String(t["awk"])
		var pos := Vector2(t["pos"])
		var rng := float(wdef["base_range"]) + _run.stats.get_stat("range_bonus")
		if awk == "awk_totem_dual":
			rng *= 1.4
		var near := _enemy_mgr.find_nearest_pos(pos, rng)
		if not near.has("found"):
			continue
		t["cooldown"] = CombatFormulas.calc_weapon_cooldown(wdef, tier, _run.stats, float(flags.get("summon_speed_pct", 0.0)))
		var dir := (Vector2(near["pos"]) - pos).normalized()
		var d_info := CombatFormulas.calc_weapon_damage(wdef, tier, _run.stats, _run.pacts, 1.0 + dmg_pct_add / 100.0)
		_proj_mgr.spawn_player_projectile({
			"pos": pos,
			"vel": dir * float(wdef["proj_speed"]),
			"speed": float(wdef["proj_speed"]),
			"damage": float(d_info["damage"]),
			"is_crit": bool(d_info["is_crit"]),
			"knockback": 45.0,
			"pierce": 2 + extra_pierce,
			"chill": awk == "awk_totem_field",
			"faction": "void",
			"weapon_id": String(wdef["id"]),
			"awakening": "awk_grim_nova" if awk == "awk_totem_field" else "",
		})
