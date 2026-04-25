extends Node
# NOTE: intentionally no `class_name AudioManager` - it collides with the
# autoload singleton of the same name (project.godot). Autoload is accessed
# globally as `AudioManager`; no class_name registration needed.

const _SFX_POOL_SIZE: int = 8

const _SFX := {
	"melee_hit":    preload("res://assets/audio/sfx/melee_hit.ogg"),
	"ranged_hit":   preload("res://assets/audio/sfx/ranged_hit.ogg"),
	"crit":         preload("res://assets/audio/sfx/crit.ogg"),
	"player_hurt":  preload("res://assets/audio/sfx/player_hurt.ogg"),
	"enemy_die":    preload("res://assets/audio/sfx/enemy_die.ogg"),
	"player_die":   preload("res://assets/audio/sfx/player_die.ogg"),
	"step":         preload("res://assets/audio/sfx/step.ogg"),
	"pickup":       preload("res://assets/audio/sfx/pickup.ogg"),
	"use_potion":   preload("res://assets/audio/sfx/use_potion.ogg"),
	"use_scroll":   preload("res://assets/audio/sfx/use_scroll.ogg"),
	"descend":      preload("res://assets/audio/sfx/descend.ogg"),
	"ui_open":      preload("res://assets/audio/sfx/ui_open.ogg"),
	"ui_close":     preload("res://assets/audio/sfx/ui_close.ogg"),
	"summon":       preload("res://assets/audio/sfx/summon.ogg"),
	"breu_cast":    preload("res://assets/audio/sfx/breu_cast.ogg"),
	"lich_revive":  preload("res://assets/audio/sfx/lich_revive.ogg"),
	"smite":        preload("res://assets/audio/sfx/smite.ogg"),
	"sacrifice":    preload("res://assets/audio/sfx/sacrifice.ogg"),
}

const _MUSIC := {
	"explore": preload("res://assets/audio/music/explore.ogg"),
	"boss":    preload("res://assets/audio/music/boss.ogg"),
}

signal mute_changed(muted: bool)

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_next_idx: int = 0
var _music_player: AudioStreamPlayer
var _current_music_key: String = ""
var _music_tween: Tween = null
var _muted: bool = false

func _enter_tree() -> void:
	_ensure_buses()

func _ready() -> void:
	for i in range(_SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)

func _ensure_buses() -> void:
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		var idx: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, "Music")
		AudioServer.set_bus_send(idx, "Master")
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		var idx: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, "SFX")
		AudioServer.set_bus_send(idx, "Master")
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), -6.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), 0.0)

func play_sfx(key: String) -> void:
	if not _SFX.has(key):
		push_warning("AudioManager: unknown SFX key '%s'" % key)
		return
	var p: AudioStreamPlayer = _sfx_players[_sfx_next_idx]
	_sfx_next_idx = (_sfx_next_idx + 1) % _SFX_POOL_SIZE
	p.stream = _SFX[key]
	p.play()

func play_music(key: String, fade_duration: float = 1.5) -> void:
	if not _MUSIC.has(key):
		push_warning("AudioManager: unknown music key '%s'" % key)
		return
	if _current_music_key == key and _music_player.playing:
		return

	var new_stream: AudioStream = _MUSIC[key]
	if new_stream is AudioStreamOggVorbis:
		(new_stream as AudioStreamOggVorbis).loop = true

	_current_music_key = key
	_kill_music_tween()

	if _music_player.playing:
		_music_tween = create_tween()
		var half: float = fade_duration / 2.0
		_music_tween.tween_property(_music_player, "volume_db", -80.0, half)
		_music_tween.tween_callback(func() -> void:
			_music_player.stream = new_stream
			_music_player.volume_db = -80.0
			_music_player.play()
		)
		_music_tween.tween_property(_music_player, "volume_db", 0.0, half)
	else:
		_music_player.stream = new_stream
		_music_player.volume_db = -80.0
		_music_player.play()
		_music_tween = create_tween()
		_music_tween.tween_property(_music_player, "volume_db", 0.0, fade_duration)

func stop_music(fade_duration: float = 0.5) -> void:
	_kill_music_tween()
	# Clear the key immediately (not in the callback) so a play_music() call
	# during the fade-out - e.g. scene reload after player death - isn't
	# falsely treated as a no-op by the "already playing this key" guard.
	_current_music_key = ""
	if not _music_player.playing:
		return
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", -80.0, fade_duration)
	_music_tween.tween_callback(func() -> void:
		_music_player.stop()
	)

func _kill_music_tween() -> void:
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = null

func is_muted() -> bool:
	return _muted

func toggle_muted() -> void:
	_muted = not _muted
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), _muted)
	mute_changed.emit(_muted)

func set_bus_volume_db(bus_name: String, db: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, db)
