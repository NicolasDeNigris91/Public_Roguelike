class_name Slime
extends Enemy

func _ready() -> void:
	name = "Slime"
	hp = 5
	max_hp = 5
	atk = 2
	def = 0
	super._ready()
	sprite_node.texture = SpriteDB.actor("slime")
