class_name Executioner
extends Enemy
# Act 5 elite demon (floors 45-47). Heavy melee brute with high ATK and
# decent armor - the "tank that also hits hard" threat leading up to the
# Demon Lord.

func _ready() -> void:
	name = "Executioner"
	hp = 24
	max_hp = 24
	atk = 12
	def = 3
	super._ready()
	sprite_node.texture = SpriteDB.actor("executioner")
