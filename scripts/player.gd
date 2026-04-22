class_name Player
extends Actor

signal turn_done

var dungeon: Dungeon
var turn_manager: TurnManager
var turn_active: bool = true

func _ready() -> void:
	color = Color("#4a90e2")
	hp = 20
	max_hp = 20
	atk = 5
	def = 3
	super._ready()

func _unhandled_input(event: InputEvent) -> void:
	if not turn_active:
		return
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

	var target_pos := grid_position + direction
	var target_enemy := _enemy_at(target_pos)

	if target_enemy != null:
		Combat.attack(self, target_enemy)
		turn_done.emit()
	elif dungeon and dungeon.grid.is_walkable(target_pos):
		move_to(target_pos)
		turn_done.emit()

func _enemy_at(pos: Vector2i) -> Enemy:
	if turn_manager == null:
		return null
	for e in turn_manager.enemies:
		if is_instance_valid(e) and e.grid_position == pos:
			return e
	return null

func die() -> void:
	died.emit()
	turn_active = false
