class_name Dungeon
extends Node2D

const FLOOR_COLOR := Color("#3a2c24")
const WALL_COLOR := Color("#6e625a")
const GRID_LINE_COLOR := Color(0, 0, 0, 0.2)

var grid: Grid

func _ready() -> void:
	grid = Grid.new(20, 15)
	_carve_room(Rect2i(1, 1, grid.width - 2, grid.height - 2))
	queue_redraw()

func grid_to_world(pos: Vector2i) -> Vector2:
	return Vector2(pos.x, pos.y) * Grid.TILE_SIZE

func _carve_room(rect: Rect2i) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			grid.set_cell(Vector2i(x, y), Grid.CellType.FLOOR)

func _draw() -> void:
	var tile := float(Grid.TILE_SIZE)
	for y in range(grid.height):
		for x in range(grid.width):
			var pos := Vector2i(x, y)
			var cell := grid.get_cell(pos)
			var fill: Color = FLOOR_COLOR if cell == Grid.CellType.FLOOR else WALL_COLOR
			var rect := Rect2(x * tile, y * tile, tile, tile)
			draw_rect(rect, fill)
			draw_rect(rect, GRID_LINE_COLOR, false, 1.0)
