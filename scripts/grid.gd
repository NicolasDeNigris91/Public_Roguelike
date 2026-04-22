class_name Grid
extends RefCounted

enum CellType { FLOOR, WALL, STAIRS }

const TILE_SIZE: int = 32

var width: int
var height: int
var cells: Array[Array] = []

func _init(w: int, h: int) -> void:
	width = w
	height = h
	for y in range(height):
		var row: Array[int] = []
		row.resize(width)
		row.fill(CellType.WALL)
		cells.append(row)

func in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height

func get_cell(pos: Vector2i) -> int:
	if not in_bounds(pos):
		return CellType.WALL
	return cells[pos.y][pos.x]

func set_cell(pos: Vector2i, cell_type: int) -> void:
	if in_bounds(pos):
		cells[pos.y][pos.x] = cell_type

func is_walkable(pos: Vector2i) -> bool:
	var cell := get_cell(pos)
	return cell == CellType.FLOOR or cell == CellType.STAIRS
