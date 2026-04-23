class_name Abomination
extends Enemy
# Act 3 mini-boss (floor 30). A towering flesh-horror knitted together from
# the temple's sacrificed. Two HP-driven phases with contrasting mechanics:
#   Phase 1 (HP > 40): heavy armor (DEF 4) + regenerates 2 HP per turn.
#                      Grinding, durable, punishes long fights.
#   Phase 2 (HP <= 40): armor sloughs off (DEF 0) and the thing enters a
#                      blood frenzy (+4 ATK). Fast kill window, but each
#                      hit it lands hurts a lot more.
# No summons, no ranged — pure melee brawler. Mechanical identity is regen
# and the DEF inversion on phase flip.

signal truly_died(final_pos: Vector2i)

const PHASE_2_THRESHOLD: int = 40
const BASE_ATK: int = 9
const RAGE_ATK_BONUS: int = 4
const BASE_DEF: int = 4
const REGEN_PER_TURN: int = 2
const VISION: int = 12

var phase: int = 1
var previous_phase: int = 1

func _ready() -> void:
	name = "Abomination"
	hp = 80
	max_hp = 80
	atk = BASE_ATK
	def = BASE_DEF
	vision_range = VISION
	always_takes_turn = true
	super._ready()
	sprite_node.texture = SpriteDB.actor("abomination")

func take_turn() -> void:
	if turn_manager == null or not is_instance_valid(turn_manager.player):
		return

	_update_phase()

	# Phase 1: regenerate while intact. Stops once phase 2 triggers so the
	# kill is committable once you break through the armor.
	if phase == 1 and hp < max_hp:
		hp = mini(max_hp, hp + REGEN_PER_TURN)
		queue_redraw()

	var player := turn_manager.player
	var dist := _distance_to(player.grid_position)

	if dist == 1:
		Combat.attack(self, player)
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
		atk = BASE_ATK + RAGE_ATK_BONUS
		def = 0
		print("Abomination enters phase 2 (hp %d/%d) — armor sloughs, fury rises (atk %d, def %d)." % [hp, max_hp, atk, def])

func die() -> void:
	truly_died.emit(grid_position)
	super.die()
