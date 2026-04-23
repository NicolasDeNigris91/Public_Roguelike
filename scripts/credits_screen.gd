extends Control
# Credits screen — attribution panel for CC-BY music and all other assets.
# Emits `closed` when dismissed.

signal closed

@onready var _back_button: Button = $Panel/VBox/BackButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_back_button.pressed.connect(_on_back)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_on_back()

func _on_back() -> void:
	visible = false
	closed.emit()
