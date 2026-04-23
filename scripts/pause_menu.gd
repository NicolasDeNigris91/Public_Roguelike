extends CanvasLayer
# Pause menu — overlay shown during gameplay when player presses Esc.
# Pauses the scene tree. Offers Continue / Settings / Back to Main Menu.

@onready var _continue_button: Button = $Control/Panel/VBox/ContinueButton
@onready var _settings_button: Button = $Control/Panel/VBox/SettingsButton
@onready var _menu_button: Button = $Control/Panel/VBox/MenuButton
@onready var _settings_menu: Control = $SettingsOverlay/SettingsMenu
@onready var _settings_overlay: CanvasLayer = $SettingsOverlay

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_continue_button.pressed.connect(_on_continue)
	_settings_button.pressed.connect(_on_settings)
	_menu_button.pressed.connect(_on_back_to_menu)
	_settings_menu.closed.connect(_on_settings_closed)

func open() -> void:
	visible = true
	get_tree().paused = true
	_continue_button.grab_focus()

func close() -> void:
	visible = false
	get_tree().paused = false

func _on_continue() -> void:
	close()

func _on_settings() -> void:
	_settings_overlay.visible = true
	_settings_menu.visible = true

func _on_settings_closed() -> void:
	_settings_overlay.visible = false

func _on_back_to_menu() -> void:
	get_tree().paused = false
	AudioManager.stop_music(0.3)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
