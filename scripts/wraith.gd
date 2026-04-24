class_name Wraith
extends Enemy
# Act 2 ranged undead (floors 7-14). Shadow spirit that fires dark bolts.
# Similar to Archer but ignores DEF (spectral attacks pass through armor).

const ATTACK_RANGE: int = 2

func _ready() -> void:
	name = "Wraith"
	hp = 4
	max_hp = 4
	atk = 1
	def = 0
	ranged_projectile_texture = SpriteDB.effect("necro_bolt")
	super._ready()
	sprite_node.texture = SpriteDB.actor("wraith")

func take_turn() -> void:
	if turn_manager == null or not is_instance_valid(turn_manager.player):
		return

	var player := turn_manager.player
	var dist := _distance_to(player.grid_position)

	if dist == 1:
		# Melee is a physical claw: armor works. Only the spectral bolt
		# at range still bypasses DEF (matches Lich phase-3 principle —
		# magical attacks ignore armor, physical ones do not).
		Combat.attack(self, player)
		return

	if dist <= ATTACK_RANGE and FOV.has_line_of_sight(dungeon.grid, grid_position, player.grid_position):
		Combat.attack(self, player, true)
		return

	if dist <= vision_range:
		var next_pos := _step_toward(player.grid_position)
		if next_pos != player.grid_position and dungeon.grid.is_walkable(next_pos):
			move_to(next_pos)
