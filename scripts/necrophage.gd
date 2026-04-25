class_name Necrophage
extends Enemy
# Act 2 melee undead (floors 10-17). Corpse-eater that heals off the player's flesh.
# Adjacent attacks only, with 33% lifesteal (capped at its own max_hp).

const LIFESTEAL_RATIO: float = 0.33

func _ready() -> void:
	EnemyStats.apply(self, "necrophage")
	super._ready()
	sprite_node.texture = SpriteDB.actor("necrophage")

func take_turn() -> void:
	if turn_manager == null or not is_instance_valid(turn_manager.player):
		return

	var player := turn_manager.player
	var dist := _distance_to(player.grid_position)

	if dist == 1:
		Combat.attack(self, player, false, LIFESTEAL_RATIO, max_hp)
		return

	if dist <= vision_range:
		var next_pos := _step_toward(player.grid_position)
		if next_pos != player.grid_position and dungeon.grid.is_walkable(next_pos):
			move_to(next_pos)
