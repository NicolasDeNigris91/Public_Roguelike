class_name Slime
extends Enemy

func _ready() -> void:
	EnemyStats.apply(self, "slime")
	super._ready()
	sprite_node.texture = SpriteDB.actor("slime")
