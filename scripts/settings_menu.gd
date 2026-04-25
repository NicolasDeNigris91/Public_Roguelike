extends Control
# Settings menu - volume sliders + mute checkbox. Used as overlay inside
# MainMenu and PauseMenu. Emits `closed` when user dismisses.

signal closed

const MIN_DB: float = -60.0
const MAX_DB: float = 0.0

@onready var _master_slider: HSlider = $Panel/VBox/MasterRow/Slider
@onready var _master_value: Label = $Panel/VBox/MasterRow/Value
@onready var _music_slider: HSlider = $Panel/VBox/MusicRow/Slider
@onready var _music_value: Label = $Panel/VBox/MusicRow/Value
@onready var _sfx_slider: HSlider = $Panel/VBox/SFXRow/Slider
@onready var _sfx_value: Label = $Panel/VBox/SFXRow/Value
@onready var _mute_checkbox: CheckBox = $Panel/VBox/MuteCheckbox
@onready var _back_button: Button = $Panel/VBox/BackButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sync_from_audio()
	_master_slider.value_changed.connect(_on_master_changed)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_mute_checkbox.toggled.connect(_on_mute_toggled)
	_back_button.pressed.connect(_on_back)
	AudioManager.mute_changed.connect(_on_audio_mute_changed)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_on_back()

func _sync_from_audio() -> void:
	_master_slider.value = _db_to_slider(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	_music_slider.value = _db_to_slider(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))
	_sfx_slider.value = _db_to_slider(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))
	_update_value_labels()
	_mute_checkbox.button_pressed = AudioManager.is_muted()

func _db_to_slider(db: float) -> float:
	if db <= MIN_DB:
		return 0.0
	return clampf((db - MIN_DB) / (MAX_DB - MIN_DB) * 100.0, 0.0, 100.0)

func _slider_to_db(value: float) -> float:
	return lerpf(MIN_DB, MAX_DB, value / 100.0)

func _update_value_labels() -> void:
	_master_value.text = "%d%%" % int(_master_slider.value)
	_music_value.text = "%d%%" % int(_music_slider.value)
	_sfx_value.text = "%d%%" % int(_sfx_slider.value)

func _on_master_changed(value: float) -> void:
	AudioManager.set_bus_volume_db("Master", _slider_to_db(value))
	_update_value_labels()

func _on_music_changed(value: float) -> void:
	AudioManager.set_bus_volume_db("Music", _slider_to_db(value))
	_update_value_labels()

func _on_sfx_changed(value: float) -> void:
	AudioManager.set_bus_volume_db("SFX", _slider_to_db(value))
	_update_value_labels()

func _on_mute_toggled(checked: bool) -> void:
	if AudioManager.is_muted() != checked:
		AudioManager.toggle_muted()

func _on_audio_mute_changed(muted: bool) -> void:
	if _mute_checkbox.button_pressed != muted:
		_mute_checkbox.set_pressed_no_signal(muted)

func _on_back() -> void:
	visible = false
	closed.emit()
