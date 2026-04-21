class_name Player
extends Actor

var dungeon: Dungeon

func _ready() -> void:
	color = Color("#4a90e2")
	hp = 20
	max_hp = 20
	atk = 5
	def = 3
	super._ready()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	var direction := Vector2i.ZERO
	match event.keycode:
		KEY_UP, KEY_W:
			direction = Vector2i(0, -1)
		KEY_DOWN, KEY_S:
			direction = Vector2i(0, 1)
		KEY_LEFT, KEY_A:
			direction = Vector2i(-1, 0)
		KEY_RIGHT, KEY_D:
			direction = Vector2i(1, 0)
		_:
			return

	get_viewport().set_input_as_handled()

	var target := grid_position + direction
	if dungeon and dungeon.grid.is_walkable(target):
		move_to(target)
