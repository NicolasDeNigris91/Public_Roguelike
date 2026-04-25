class_name RottingHulk
extends Enemy
# Act 3 melee tank (floors 22-29). Huge rotting mass of flesh that lumbers
# slowly but hits hard and soaks damage. Pure melee, no tricks - just a wall.

func _ready() -> void:
	name = "Rotting Hulk"
	hp = 22
	max_hp = 22
	atk = 8
	def = 3
	super._ready()
	sprite_node.texture = SpriteDB.actor("rotting_hulk")
