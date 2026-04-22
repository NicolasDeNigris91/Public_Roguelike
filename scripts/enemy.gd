class_name Enemy
extends Actor

var dungeon: Dungeon
var turn_manager: TurnManager

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
