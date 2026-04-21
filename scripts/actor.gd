class_name Actor
extends Node2D

var grid_position: Vector2i
var hp: int = 10
var max_hp: int = 10
var atk: int = 3
var def: int = 1
var color: Color = Color.WHITE

func _ready() -> void:
	_sync_position()

func move_to(new_grid_pos: Vector2i) -> void:
	grid_position = new_grid_pos
	_sync_position()

func _sync_position() -> void:
	position = Vector2(grid_position.x, grid_position.y) * Grid.TILE_SIZE
	queue_redraw()

func take_turn() -> void:
	pass

func _draw() -> void:
	var margin := 4.0
	var size := float(Grid.TILE_SIZE) - margin * 2.0
	draw_rect(Rect2(margin, margin, size, size), color)
