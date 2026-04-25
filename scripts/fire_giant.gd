class_name FireGiant
extends Enemy
# Act 4 mini-boss (floor 42). Armored behemoth with opposite-stance phases:
#   Phase 1 (HP > 50): pure melee brawler. DEF 5, doesn't close gaps with
#                      ranged fire - if you kite him he walks to you.
#   Phase 2 (HP <= 50): bursts into flame. Drops DEF to 3 but gains ranged
#                      fire attacks from up to 5 tiles away. Both melee AND
#                      ranged are on the table - the kite window closes.
# Distinct from earlier bosses: no summons, no regen, no lifesteal; the
# mechanical identity is the "melee-only -> melee + ranged" stance flip.

signal truly_died(final_pos: Vector2i)

const PHASE_2_THRESHOLD: int = 50
const BASE_ATK: int = 12
const BASE_DEF: int = 5
const PHASE_2_DEF: int = 3
const RANGED_RANGE: int = 5
const VISION: int = 14

var phase: int = 1
var previous_phase: int = 1

func _ready() -> void:
	name = "Fire Giant"
	hp = 100
	max_hp = 100
	atk = BASE_ATK
	def = BASE_DEF
	vision_range = VISION
	always_takes_turn = true
	ranged_projectile_texture = SpriteDB.effect("magic_bolt")
	super._ready()
	sprite_node.texture = SpriteDB.actor("fire_giant")

func take_turn() -> void:
	if turn_manager == null or not is_instance_valid(turn_manager.player):
		return

	_update_phase()

	var player := turn_manager.player
	var dist := _distance_to(player.grid_position)

	if dist == 1:
		Combat.attack(self, player)
		return

	# Ranged fire hurl only in phase 2. Uses LOS so walls still matter.
	if phase == 2 and dist <= RANGED_RANGE and FOV.has_line_of_sight(dungeon.grid, grid_position, player.grid_position):
		Combat.attack(self, player, true)  # ignore DEF - fire
		return

	if dist <= vision_range:
		var next_pos := _step_toward(player.grid_position)
		if next_pos != player.grid_position and dungeon.grid.is_walkable(next_pos):
			move_to(next_pos)

func _update_phase() -> void:
	previous_phase = phase
	if hp <= PHASE_2_THRESHOLD:
		phase = 2
	else:
		phase = 1
	if phase != previous_phase and phase == 2:
		def = PHASE_2_DEF
		print("Fire Giant ignites - def drops to %d, ranged fire available." % def)

func die() -> void:
	truly_died.emit(grid_position)
	super.die()
