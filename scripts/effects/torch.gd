class_name Torch
extends Node2D
# Animated decorative flame pinned to a grid tile. Used as a scripted prop
# (e.g. the floor-28 rosary shrine). Does not interact with combat, pickup,
# or the turn system — pure visual. FOV visibility is driven externally
# by main.gd._refresh_entity_visibility.

const FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/effects/torch/torch_0.png"),
	preload("res://assets/sprites/effects/torch/torch_1.png"),
	preload("res://assets/sprites/effects/torch/torch_2.png"),
	preload("res://assets/sprites/effects/torch/torch_3.png"),
	preload("res://assets/sprites/effects/torch/torch_4.png"),
]
const FRAME_DURATION: float = 0.12

var grid_position: Vector2i

var _sprite: Sprite2D
var _frame_index: int = 0
var _frame_timer: float = 0.0

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.texture = FRAMES[0]
	add_child(_sprite)
	position = Vector2(grid_position.x, grid_position.y) * Grid.TILE_SIZE

func _process(delta: float) -> void:
	if not visible:
		return
	_frame_timer += delta
	if _frame_timer >= FRAME_DURATION:
		_frame_timer -= FRAME_DURATION
		_frame_index = (_frame_index + 1) % FRAMES.size()
		_sprite.texture = FRAMES[_frame_index]
