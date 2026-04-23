class_name HellHound
extends Enemy
# Act 4 rabid melee (floors 34-38). Higher damage than Imp, moderate HP —
# the pack enemy that pressures Benedict while imps and salamanders flank.

func _ready() -> void:
	name = "Hell Hound"
	hp = 14
	max_hp = 14
	atk = 10
	def = 1
	super._ready()
	sprite_node.texture = SpriteDB.actor("hell_hound")
