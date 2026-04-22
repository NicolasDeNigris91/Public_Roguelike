class_name Lich
extends Enemy

signal truly_died(final_pos: Vector2i)

const LICH_VISION_RANGE: int = 14

func _ready() -> void:
	name = "Lich"
	color = Color("#b4185a")
	hp = 40
	max_hp = 40
	atk = 8
	def = 0
	vision_range = LICH_VISION_RANGE
	super._ready()

func take_turn() -> void:
	if turn_manager == null or not is_instance_valid(turn_manager.player):
		return

	var player := turn_manager.player
	var dist := _distance_to(player.grid_position)

	if dist == 1:
		Combat.attack(self, player)
		return

	if dist <= 4 and FOV.has_line_of_sight(dungeon.grid, grid_position, player.grid_position):
		Combat.attack(self, player, true)
		return
