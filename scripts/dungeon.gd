class_name Dungeon
extends Node2D

const WIDTH: int = 30
const HEIGHT: int = 20

const FLOOR_COLOR := Color("#3a2c24")
const WALL_COLOR := Color("#6e625a")
const GRID_LINE_COLOR := Color(0, 0, 0, 0.2)

var grid: Grid
var rooms: Array[Rect2i] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	grid = Grid.new(WIDTH, HEIGHT)
	rooms = DungeonGenerator.generate(grid, rng)
	queue_redraw()

func grid_to_world(pos: Vector2i) -> Vector2:
	return Vector2(pos.x, pos.y) * Grid.TILE_SIZE

func room_center(index: int) -> Vector2i:
	var r := rooms[index]
	return Vector2i(r.position.x + r.size.x / 2, r.position.y + r.size.y / 2)

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
