class_name ItemEntity
extends Node2D

var item: Item
var grid_position: Vector2i:
	set(value):
		grid_position = value
		position = Vector2(value.x, value.y) * Grid.TILE_SIZE
		queue_redraw()

func _draw() -> void:
	if item == null:
		return
	var tile := float(Grid.TILE_SIZE)
	var center := Vector2(tile / 2.0, tile / 2.0)
	var radius := tile * 0.28
	var points := PackedVector2Array([
		center + Vector2(0, -radius),
		center + Vector2(radius, 0),
		center + Vector2(0, radius),
		center + Vector2(-radius, 0),
	])
	draw_colored_polygon(points, item.color)
	draw_polyline(points + PackedVector2Array([points[0]]), Color.BLACK, 1.0)
