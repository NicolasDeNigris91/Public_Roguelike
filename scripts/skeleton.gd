class_name Skeleton
extends Enemy

func _ready() -> void:
	name = "Skeleton"
	hp = 8
	max_hp = 8
	atk = 4
	def = 0
	super._ready()
	sprite_node.texture = SpriteDB.actor("skeleton")
