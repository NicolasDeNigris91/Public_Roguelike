extends CanvasLayer
# DialogueOverlay — full-screen Benedict portrait + quote, shown between acts
# after each boss kill. Pauses gameplay input; dismisses on X / Space / Enter.

signal closed

@onready var _quote_label: Label = $Control/PanelContainer/MarginContainer/HBox/TextVBox/QuoteLabel

func show_dialogue(quote: String) -> void:
	_quote_label.text = quote
	visible = true

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_X or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
		get_viewport().set_input_as_handled()
		visible = false
		closed.emit()
