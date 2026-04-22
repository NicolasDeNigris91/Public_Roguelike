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
