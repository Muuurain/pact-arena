extends Node
## Global decoupled event bus connecting combat simulation, UI screens, and audio feedback.

signal sfx_requested(sfx_id: String, pitch_jitter: float)
signal bgm_requested(track_id: String)

signal screen_shake_requested(trauma: float)
signal hit_stop_requested(duration: float)
signal floating_text_requested(world_pos: Vector2, text: String, color: Color, scale_mult: float)

signal player_hp_changed(current_hp: float, max_hp: float)
signal player_xp_changed(xp: float, next_xp: float, level: int)
signal player_dash_changed(charges: int, max_charges: int, cooldown_ratio: float)
signal crystals_changed(amount: int)
signal wave_progress_changed(wave: int, time_left: float, total_time: float, kills: int)

signal boss_spawned(boss_name: String, max_hp: float)
signal boss_hp_changed(current_hp: float, max_hp: float)
signal boss_defeated(boss_id: String)

signal weapon_awakened(slot_index: int, weapon_id: String, awakening_id: String)
signal run_state_updated()
signal achievement_unlocked(hero_id: String, title: String)
