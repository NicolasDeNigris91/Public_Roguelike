class_name Imp
extends Enemy
# Act 4 introductory demon (floors 31-35). Small, fast-feeling, low HP but
# sharp ATK — the first real "demon" Benedict meets. Pure melee.

func _ready() -> void:
	name = "Imp"
	hp = 8
	max_hp = 8
	atk = 9
	def = 0
	super._ready()
	sprite_node.texture = SpriteDB.actor("imp")
