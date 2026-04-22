class_name DungeonGenerator

const MAX_ROOMS: int = 10
const ROOM_MIN_SIZE: int = 4
const ROOM_MAX_SIZE: int = 8

static func generate(grid: Grid, rng: RandomNumberGenerator) -> Array[Rect2i]:
	var rooms: Array[Rect2i] = []

	for i in range(MAX_ROOMS):
		var w := rng.randi_range(ROOM_MIN_SIZE, ROOM_MAX_SIZE)
		var h := rng.randi_range(ROOM_MIN_SIZE, ROOM_MAX_SIZE)
		var x := rng.randi_range(1, grid.width - w - 1)
		var y := rng.randi_range(1, grid.height - h - 1)
		var new_room := Rect2i(x, y, w, h)

		var overlaps := false
		for existing in rooms:
			if new_room.intersects(existing.grow(1)):
				overlaps = true
				break
		if overlaps:
			continue

		_carve_room(grid, new_room)

		if rooms.size() > 0:
			var prev_center := _center_of(rooms[rooms.size() - 1])
			var new_center := _center_of(new_room)
			_carve_corridor(grid, prev_center, new_center, rng)

		rooms.append(new_room)

	return rooms

static func _carve_room(grid: Grid, rect: Rect2i) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			grid.set_cell(Vector2i(x, y), Grid.CellType.FLOOR)

static func _carve_corridor(grid: Grid, from_pos: Vector2i, to_pos: Vector2i, rng: RandomNumberGenerator) -> void:
	var corner: Vector2i
	if rng.randi() % 2 == 0:
		corner = Vector2i(to_pos.x, from_pos.y)
	else:
		corner = Vector2i(from_pos.x, to_pos.y)
	_carve_line(grid, from_pos, corner)
	_carve_line(grid, corner, to_pos)

static func _carve_line(grid: Grid, from_pos: Vector2i, to_pos: Vector2i) -> void:
	var x0 := mini(from_pos.x, to_pos.x)
	var x1 := maxi(from_pos.x, to_pos.x)
	var y0 := mini(from_pos.y, to_pos.y)
	var y1 := maxi(from_pos.y, to_pos.y)
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			grid.set_cell(Vector2i(x, y), Grid.CellType.FLOOR)

static func _center_of(rect: Rect2i) -> Vector2i:
	return Vector2i(
		rect.position.x + rect.size.x / 2,
		rect.position.y + rect.size.y / 2
	)
