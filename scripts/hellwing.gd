class_name Hellwing
extends Enemy
# Act 5 flying lesser demon (floors 43-47). Ranged fire caster at range 4,
# ignores DEF. Lighter than Salamander but appears in larger groups.

const ATTACK_RANGE: int = 4

func _ready() -> void:
	name = "Hellwing"
	hp = 12
	max_hp = 12
	atk = 9
	def = 0
	ranged_projectile_texture = SpriteDB.effect("magic_bolt")
	super._ready()
	sprite_node.texture = SpriteDB.actor("hellwing")

func take_turn() -> void:
	if turn_manager == null or not is_instance_valid(turn_manager.player):
		return

	var player := turn_manager.player
	var dist := _distance_to(player.grid_position)

	if dist == 1:
		# Talon swipe — physical, armor works. Only the fire bolt at range
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
