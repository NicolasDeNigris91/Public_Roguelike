class_name BossArenaGenerator

const ANTECHAMBER := Rect2i(2, 7, 3, 3)
const CORRIDOR := Rect2i(5, 8, 2, 1)
const ARENA := Rect2i(7, 5, 14, 10)

const PLAYER_SPAWN := Vector2i(3, 8)
const LICH_SPAWN := Vector2i(13, 9)

static func generate(grid: Grid) -> Dictionary:
	_carve(grid, ANTECHAMBER)
	_carve(grid, CORRIDOR)
	_carve(grid, ARENA)
	return {
		"player_spawn": PLAYER_SPAWN,
		"lich_spawn": LICH_SPAWN
	}

static func _carve(grid: Grid, rect: Rect2i) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			grid.set_cell(Vector2i(x, y), Grid.CellType.FLOOR)
