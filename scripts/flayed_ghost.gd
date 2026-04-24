class_name FlayedGhost
extends Enemy
# Act 3 ranged horror (floors 19-25). A flayed spirit that hurls bolts of
# raw nerve-energy. Ignores DEF (like the Wraith) but hits harder.

const ATTACK_RANGE: int = 5

func _ready() -> void:
	name = "Flayed Ghost"
	hp = 10
	max_hp = 10
	atk = 7
	def = 0
	ranged_projectile_texture = SpriteDB.effect("necro_bolt")
	super._ready()
	sprite_node.texture = SpriteDB.actor("flayed_ghost")

func take_turn() -> void:
	if turn_manager == null or not is_instance_valid(turn_manager.player):
		return

	var player := turn_manager.player
	var dist := _distance_to(player.grid_position)

	if dist == 1:
		# Spectral claw is still physical contact — armor works up close.
		# The signature nerve-bolt at range keeps the DEF bypass.
		Combat.attack(self, player)
		return

	if dist <= ATTACK_RANGE and FOV.has_line_of_sight(dungeon.grid, grid_position, player.grid_position):
		Combat.attack(self, player, true)
		return

	if dist <= vision_range:
		var next_pos := _step_toward(player.grid_position)
		if next_pos != player.grid_position and dungeon.grid.is_walkable(next_pos):
			move_to(next_pos)
