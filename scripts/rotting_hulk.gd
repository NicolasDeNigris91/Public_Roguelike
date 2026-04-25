class_name RottingHulk
extends Enemy
# Act 3 melee tank (floors 22-29). Huge rotting mass of flesh that lumbers
# slowly but hits hard and soaks damage. Pure melee, no tricks - just a wall.

func _ready() -> void:
	EnemyStats.apply(self, "rotting_hulk")
	super._ready()
	sprite_node.texture = SpriteDB.actor("rotting_hulk")
