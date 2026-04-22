class_name Enemy
extends Actor

const DEFAULT_VISION_RANGE: int = 8

var dungeon: Dungeon
var turn_manager: TurnManager
var vision_range: int = DEFAULT_VISION_RANGE

func take_turn() -> void:
	if turn_manager == null or not is_instance_valid(turn_manager.player):
		return

	var player := turn_manager.player
	var dist := _distance_to(player.grid_position)

	if dist == 1:
		Combat.attack(self, player)
		return

	if dist <= vision_range:
		var next_pos := _step_toward(player.grid_position)
		if next_pos != player.grid_position and dungeon.grid.is_walkable(next_pos):
			move_to(next_pos)

func _distance_to(target: Vector2i) -> int:
	return absi(grid_position.x - target.x) + absi(grid_position.y - target.y)

func _step_toward(target: Vector2i) -> Vector2i:
	var dx := signi(target.x - grid_position.x)
	var dy := signi(target.y - grid_position.y)
	if absi(target.x - grid_position.x) >= absi(target.y - grid_position.y):
		if dx != 0:
			return grid_position + Vector2i(dx, 0)
	if dy != 0:
		return grid_position + Vector2i(0, dy)
	return grid_position
