class_name Slime
extends Enemy

const VISION_RANGE: int = 8

func _ready() -> void:
	name = "Slime"
	color = Color("#7fb069")
	hp = 5
	max_hp = 5
	atk = 2
	def = 0
	super._ready()

func take_turn() -> void:
	if turn_manager == null or not is_instance_valid(turn_manager.player):
		return

	var player := turn_manager.player
	var dist := _distance_to(player.grid_position)

	if dist == 1:
		Combat.attack(self, player)
		return

	if dist <= VISION_RANGE:
		var next_pos := _step_toward(player.grid_position)
		if next_pos != player.grid_position and dungeon.grid.is_walkable(next_pos):
			move_to(next_pos)
