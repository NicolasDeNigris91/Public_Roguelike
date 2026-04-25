class_name Skeleton
extends Enemy

func _ready() -> void:
	EnemyStats.apply(self, "skeleton")
	super._ready()
	sprite_node.texture = SpriteDB.actor("skeleton")
