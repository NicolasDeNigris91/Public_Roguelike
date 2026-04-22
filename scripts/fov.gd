class_name FOV

const RADIUS: int = 8
const NUM_RAYS: int = 360

static func compute(grid: Grid, origin: Vector2i, radius: int = RADIUS) -> Dictionary:
	var visible := {}
	visible[origin] = true

	for i in range(NUM_RAYS):
		var angle := i * TAU / NUM_RAYS
		_cast_ray(grid, origin, angle, radius, visible)

	return visible

static func has_line_of_sight(grid: Grid, from_pos: Vector2i, to_pos: Vector2i) -> bool:
	if from_pos == to_pos:
		return true
	var dx := to_pos.x - from_pos.x
	var dy := to_pos.y - from_pos.y
	var steps := maxi(absi(dx), absi(dy))
	if steps == 0:
		return true
	var step_x := float(dx) / float(steps)
	var step_y := float(dy) / float(steps)
	var x := float(from_pos.x) + 0.5
	var y := float(from_pos.y) + 0.5
	for i in range(steps):
		x += step_x
		y += step_y
		var pos := Vector2i(floori(x), floori(y))
		if pos == to_pos:
			return true
		if grid.get_cell(pos) == Grid.CellType.WALL:
			return false
	return true

static func _cast_ray(grid: Grid, origin: Vector2i, angle: float, radius: int, visible: Dictionary) -> void:
	var dx := cos(angle)
	var dy := sin(angle)
	var x := float(origin.x) + 0.5
	var y := float(origin.y) + 0.5

	for step in range(radius):
		x += dx
		y += dy
		var pos := Vector2i(floori(x), floori(y))

		if not grid.in_bounds(pos):
			return

		visible[pos] = true

		if grid.get_cell(pos) == Grid.CellType.WALL:
			return
