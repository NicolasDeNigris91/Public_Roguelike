class_name Actor
extends Node2D

signal died
signal moved(to_pos: Vector2i)

var grid_position: Vector2i
var hp: int = 10
var max_hp: int = 10
var atk: int = 3
var def: int = 1
var sprite_node: Sprite2D

func _ready() -> void:
	sprite_node = Sprite2D.new()
	sprite_node.centered = false
	add_child(sprite_node)
	_sync_position()

func move_to(new_grid_pos: Vector2i) -> void:
	grid_position = new_grid_pos
	_sync_position()
	moved.emit(new_grid_pos)

func take_damage(amount: int) -> void:
	hp = maxi(0, hp - amount)
	queue_redraw()
	if hp <= 0:
		die()

func die() -> void:
	died.emit()
	queue_free()

func take_turn() -> void:
	pass

func _sync_position() -> void:
	position = Vector2(grid_position.x, grid_position.y) * Grid.TILE_SIZE
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var font_size := 10
	var text := str(hp)
	var text_pos := Vector2(2, -2)
	draw_string_outline(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 2, Color.BLACK)
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
