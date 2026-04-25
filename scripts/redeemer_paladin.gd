class_name RedeemerPaladin
extends Enemy
# Lich-ending final confrontation. A new paladin descends into the Bastion
# wearing Benedict's own appearance (shares the "player" actor sprite). Its
# purpose is narrative, not mechanical - the fight is not meant to be won.
# Overwhelming stats end the encounter within a turn or two.

func _ready() -> void:
	name = "Redeemer"
	hp = 200
	max_hp = 200
	atk = 80
	def = 20
	vision_range = 20
	always_takes_turn = true
	super._ready()
	sprite_node.texture = SpriteDB.actor("player")
