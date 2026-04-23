extends Control
# Main menu — boot scene. Transitions to game.tscn via Play button, shows
# settings / credits overlays, or quits.

@onready var _play_button: Button = $CenterContainer/VBoxContainer/ButtonsVBox/PlayButton
@onready var _settings_button: Button = $CenterContainer/VBoxContainer/ButtonsVBox/SettingsButton
@onready var _credits_button: Button = $CenterContainer/VBoxContainer/ButtonsVBox/CreditsButton
@onready var _quit_button: Button = $CenterContainer/VBoxContainer/ButtonsVBox/QuitButton
@onready var _settings_overlay: CanvasLayer = $SettingsOverlay
@onready var _credits_overlay: CanvasLayer = $CreditsOverlay

func _ready() -> void:
	_play_button.pressed.connect(_on_play)
	_settings_button.pressed.connect(_on_settings)
	_credits_button.pressed.connect(_on_credits)
	_quit_button.pressed.connect(_on_quit)
	_play_button.grab_focus()

func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_settings() -> void:
	_settings_overlay.visible = true

func _on_credits() -> void:
	_credits_overlay.visible = true

func _on_quit() -> void:
	get_tree().quit()
