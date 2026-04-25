class_name Archer
extends Enemy

const ATTACK_RANGE: int = 4

func _ready() -> void:
	EnemyStats.apply(self, "archer")
	ranged_projectile_frames = SpriteDB.arrow_frames()
	super._ready()
	sprite_node.texture = SpriteDB.actor("archer")

func take_turn() -> void:
	if turn_manager == null or not is_instance_valid(turn_manager.player):
		return

	var player := turn_manager.player
	var dist := _distance_to(player.grid_position)

	if dist == 1:
		Combat.attack(self, player)
		return

	if dist <= ATTACK_RANGE and FOV.has_line_of_sight(dungeon.grid, grid_position, player.grid_position):
		Combat.attack(self, player)
		return

	if dist <= vision_range:
		var next_pos := _step_toward(player.grid_position)
		if next_pos != player.grid_position and dungeon.grid.is_walkable(next_pos):
			move_to(next_pos)
