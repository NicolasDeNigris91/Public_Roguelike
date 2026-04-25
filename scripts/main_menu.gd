extends Control
# Main menu - boot scene. Transitions to game.tscn via Play button, shows
# settings / credits overlays, or quits. Also gates save/load: Continue button
# is visible only when a save exists; Play prompts for confirmation in that case.

@onready var _continue_button: Button = $ButtonsVBox/ContinueButton
@onready var _play_button: Button = $ButtonsVBox/PlayButton
@onready var _settings_button: Button = $ButtonsVBox/SettingsButton
@onready var _credits_button: Button = $ButtonsVBox/CreditsButton
@onready var _quit_button: Button = $ButtonsVBox/QuitButton
@onready var _settings_overlay: CanvasLayer = $SettingsOverlay
@onready var _credits_overlay: CanvasLayer = $CreditsOverlay
@onready var _settings_menu: Control = $SettingsOverlay/SettingsMenu
@onready var _credits_screen: Control = $CreditsOverlay/CreditsScreen
@onready var _confirm_new_run: ConfirmationDialog = $ConfirmNewRunDialog

func _ready() -> void:
	_continue_button.pressed.connect(_on_continue)
	_play_button.pressed.connect(_on_play)
	_settings_button.pressed.connect(_on_settings)
	_credits_button.pressed.connect(_on_credits)
	_quit_button.pressed.connect(_on_quit)
	_settings_menu.closed.connect(_on_settings_closed)
	_credits_screen.closed.connect(_on_credits_closed)
	_confirm_new_run.confirmed.connect(_on_new_run_confirmed)

	var has_save: bool = SaveManager.has_save()
	_continue_button.visible = has_save
	if has_save:
		_continue_button.grab_focus()
	else:
		_play_button.grab_focus()

func _on_continue() -> void:
	SaveManager.pending_load = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_play() -> void:
	if SaveManager.has_save():
		_confirm_new_run.popup_centered()
	else:
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_new_run_confirmed() -> void:
	SaveManager.clear()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_settings() -> void:
	_settings_overlay.visible = true
	_settings_menu.visible = true

func _on_settings_closed() -> void:
	_settings_overlay.visible = false

func _on_credits() -> void:
	_credits_overlay.visible = true
	_credits_screen.visible = true

func _on_credits_closed() -> void:
	_credits_overlay.visible = false

func _on_quit() -> void:
	get_tree().quit()
