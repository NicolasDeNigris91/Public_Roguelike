class_name Salamander
extends Enemy
# Act 4 ranged fire serpent (floors 36-41). Similar pattern to Mage — hurls
# fire bolts at range 4 with LOS, ignores DEF (fire bypasses armor).

const ATTACK_RANGE: int = 4

func _ready() -> void:
	name = "Salamander"
	hp = 16
	max_hp = 16
	atk = 8
	def = 1
	ranged_projectile_texture = SpriteDB.effect("magic_bolt")
	super._ready()
	sprite_node.texture = SpriteDB.actor("salamander")

func take_turn() -> void:
	if turn_manager == null or not is_instance_valid(turn_manager.player):
		return

	var player := turn_manager.player
	var dist := _distance_to(player.grid_position)

	if dist == 1:
		# Bite/claw — physical, armor works. Only the fire bolt at range
		# bypasses DEF.
		Combat.attack(self, player)
		return

	if dist <= ATTACK_RANGE and FOV.has_line_of_sight(dungeon.grid, grid_position, player.grid_position):
		Combat.attack(self, player, true)
		return

	if dist <= vision_range:
		var next_pos := _step_toward(player.grid_position)
		if next_pos != player.grid_position and dungeon.grid.is_walkable(next_pos):
			move_to(next_pos)
