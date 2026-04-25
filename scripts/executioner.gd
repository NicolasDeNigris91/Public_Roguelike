class_name Executioner
extends Enemy
# Act 5 elite demon (floors 45-47). Heavy melee brute with high ATK and
# decent armor - the "tank that also hits hard" threat leading up to the
# Demon Lord.

func _ready() -> void:
	EnemyStats.apply(self, "executioner")
	super._ready()
	sprite_node.texture = SpriteDB.actor("executioner")
