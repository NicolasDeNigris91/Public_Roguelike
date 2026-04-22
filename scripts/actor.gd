class_name Actor
extends Node2D

signal died
signal moved(to_pos: Vector2i)

const MOVE_TWEEN_DURATION: float = 0.1

var grid_position: Vector2i
var hp: int = 10
var max_hp: int = 10
var atk: int = 3
var def: int = 1
var sprite_node: Sprite2D
var is_tweening: bool = false

func _ready() -> void:
	sprite_node = Sprite2D.new()
	sprite_node.centered = false
	add_child(sprite_node)
	_sync_position_instant()

func move_to(new_grid_pos: Vector2i, animate: bool = true) -> void:
	grid_position = new_grid_pos
	if animate:
		_tween_to(grid_position)
	else:
		_sync_position_instant()
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

func _tween_to(target_grid_pos: Vector2i) -> void:
	var target_world := Vector2(target_grid_pos.x, target_grid_pos.y) * Grid.TILE_SIZE
	is_tweening = true
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "position", target_world, MOVE_TWEEN_DURATION)
	tw.tween_callback(func() -> void:
		is_tweening = false
		moved.emit(target_grid_pos)
	)

func _sync_position_instant() -> void:
	position = Vector2(grid_position.x, grid_position.y) * Grid.TILE_SIZE
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var font_size := 10
	var text := str(hp)
	var text_pos := Vector2(2, -2)
	draw_string_outline(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 2, Color.BLACK)
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
