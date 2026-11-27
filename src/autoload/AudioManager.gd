extends Node
## Centralized audio manager handling pooled SFX playback with pitch variance
## and seamless BGM track transitions.

const SFX_POOL_SIZE := 14

var _bgm_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_cursor: int = 0
var _stream_cache: Dictionary = {}
var _current_bgm: String = ""
var _sfx_cooldowns: Dictionary = {}


func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Master"
	add_child(_bgm_player)
	_bgm_player.finished.connect(_on_bgm_finished)

	for i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx_players.append(p)

	EventBus.sfx_requested.connect(play_sfx)
	EventBus.bgm_requested.connect(play_bgm)
	apply_volumes()


func _exit_tree() -> void:
	stop_all()


func stop_all_sfx() -> void:
	for p in _sfx_players:
		p.stop()
		p.stream = null
	_sfx_cooldowns.clear()


func stop_all() -> void:
	_current_bgm = ""
	if _bgm_player != null:
		_bgm_player.stop()
		_bgm_player.stream = null
	stop_all_sfx()
	_stream_cache.clear()


func apply_volumes() -> void:
	var bgm_v := float(SaveManager.get_setting("bgm_volume", 0.72))
	_bgm_player.volume_db = linear_to_db(maxf(0.0001, bgm_v * 0.55))


func play_sfx(sfx_id: String, pitch_jitter: float = 0.08) -> void:
	var sfx_vol := float(SaveManager.get_setting("sfx_volume", 0.85))
	if sfx_vol <= 0.01:
		return

	# Prevent audio overload when 20 projectiles hit in the same frame
	var now := Time.get_ticks_msec()
	var last_t := int(_sfx_cooldowns.get(sfx_id, 0))
	if now - last_t < 38:
		return
	_sfx_cooldowns[sfx_id] = now

	var stream := _get_stream("res://assets/audio/sfx/%s.ogg" % sfx_id)
	if stream == null:
		return

	var p := _sfx_players[_sfx_cursor]
	_sfx_cursor = (_sfx_cursor + 1) % SFX_POOL_SIZE
	p.stream = stream
	p.volume_db = linear_to_db(clampf(sfx_vol, 0.001, 1.0))
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter) if pitch_jitter > 0.0 else 1.0
	p.play()


func play_bgm(track_id: String) -> void:
	if _current_bgm == track_id and _bgm_player.playing:
		return
	_current_bgm = track_id
	var stream := _get_stream("res://assets/audio/bgm/%s.ogg" % track_id)
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	apply_volumes()
	_bgm_player.stream = stream
	_bgm_player.play()


func _on_bgm_finished() -> void:
	if not _current_bgm.is_empty():
		_bgm_player.play()


func _get_stream(path: String) -> AudioStream:
	if _stream_cache.has(path):
		return _stream_cache[path]
	if ResourceLoader.exists(path):
		var res := load(path) as AudioStream
		_stream_cache[path] = res
		return res
	return null
