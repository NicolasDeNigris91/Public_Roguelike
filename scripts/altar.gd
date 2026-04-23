class_name Altar
extends Node2D
# Sacrificial altar. Walk on top, press a hotbar slot (1-8) to sacrifice a
# weapon/armor/ring from the bag for a permanent stat bonus. Once consumed,
# its sprite changes and it no longer accepts sacrifices.

signal consumed_changed(is_consumed: bool)

const SPRITE_ACTIVE: Texture2D = preload("res://assets/sprites/dungeon/altar_active.png")
const SPRITE_CONSUMED: Texture2D = preload("res://assets/sprites/dungeon/altar_consumed.png")

@export var grid_position: Vector2i = Vector2i.ZERO
@export var consumed: bool = false

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_sync_position()
	_sync_sprite()

func _sync_position() -> void:
	# Grid.TILE_SIZE = 32, verified in scripts/grid.gd line 6
	position = Vector2(grid_position.x, grid_position.y) * Grid.TILE_SIZE

func _sync_sprite() -> void:
	if _sprite == null:
		return
	_sprite.texture = SPRITE_CONSUMED if consumed else SPRITE_ACTIVE

func is_active() -> bool:
	return not consumed

func consume() -> void:
	if consumed:
		return
	consumed = true
	_sync_sprite()
	consumed_changed.emit(true)
