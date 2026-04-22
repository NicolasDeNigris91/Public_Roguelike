class_name ItemEntity
extends Node2D

var item: Item
var grid_position: Vector2i:
	set(value):
		grid_position = value
		position = Vector2(value.x, value.y) * Grid.TILE_SIZE

var sprite_node: Sprite2D

func _ready() -> void:
	sprite_node = Sprite2D.new()
	sprite_node.centered = false
	add_child(sprite_node)
	if item != null:
		sprite_node.texture = item.texture
