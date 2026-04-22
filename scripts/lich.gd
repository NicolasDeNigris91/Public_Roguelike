class_name Lich
extends Enemy

signal truly_died(final_pos: Vector2i)

const LICH_VISION_RANGE: int = 14
const PHASE_2_THRESHOLD: int = 24
const PHASE_3_THRESHOLD: int = 10
const LIFESTEAL_CAP: int = 24
const SUMMON_COOLDOWN_MAX: int = 4
const SUMMON_CAP: int = 3
const BREU_COOLDOWN_MAX: int = 3
const BREU_DURATION: int = 4
const BREU_VISION_RANGE: int = 3

var phase: int = 1
var previous_phase: int = 1
var summon_cooldown: int = 0
var breu_cooldown: int = 0
var summoned_skeletons: Array[Skeleton] = []

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

	_update_phase()

	var player := turn_manager.player
	var dist := _distance_to(player.grid_position)

	if dist == 1:
		Combat.attack(self, player)
		return

	match phase:
		1:
			_phase_1_turn(player, dist)
		2:
			_phase_2_turn(player, dist)
		3:
			_cast_shadow_bolt_or_idle(player, dist)

func _update_phase() -> void:
	previous_phase = phase
	if hp <= PHASE_3_THRESHOLD:
		phase = 3
	elif hp <= PHASE_2_THRESHOLD:
		phase = 2
	else:
		phase = 1
	if phase != previous_phase:
		summon_cooldown = 0
		breu_cooldown = 0
		print("Lich enters phase %d (hp %d/%d)" % [phase, hp, max_hp])

func _phase_1_turn(player: Player, dist: int) -> void:
	_prune_dead_summons()
	if summon_cooldown == 0 and summoned_skeletons.size() < SUMMON_CAP:
		var tile := _find_summon_tile()
		if tile != Vector2i(-1, -1):
			_summon_skeleton(tile)
			summon_cooldown = SUMMON_COOLDOWN_MAX
			return
	_cast_shadow_bolt_or_idle(player, dist)
	if summon_cooldown > 0:
		summon_cooldown -= 1

func _phase_2_turn(player: Player, dist: int) -> void:
	if dist <= 4 and FOV.has_line_of_sight(dungeon.grid, grid_position, player.grid_position):
		Combat.attack(self, player, true, 0.5, LIFESTEAL_CAP)

func _cast_shadow_bolt_or_idle(player: Player, dist: int) -> void:
	if dist <= 3 and FOV.has_line_of_sight(dungeon.grid, grid_position, player.grid_position):
		Combat.attack(self, player, true)

func _prune_dead_summons() -> void:
	var alive: Array[Skeleton] = []
	for s in summoned_skeletons:
		if is_instance_valid(s):
			alive.append(s)
	summoned_skeletons = alive

func _find_summon_tile() -> Vector2i:
	for radius in [1, 2, 3]:
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				if dx == 0 and dy == 0:
					continue
				if maxi(absi(dx), absi(dy)) != radius:
					continue
				var pos := grid_position + Vector2i(dx, dy)
				if _is_valid_summon_tile(pos):
					return pos
	return Vector2i(-1, -1)

func _is_valid_summon_tile(pos: Vector2i) -> bool:
	if not dungeon.grid.is_walkable(pos):
		return false
	if turn_manager.player.grid_position == pos:
		return false
	for e in turn_manager.enemies:
		if is_instance_valid(e) and e.grid_position == pos:
			return false
	return true

func _summon_skeleton(at: Vector2i) -> void:
	var skel := Skeleton.new()
	get_parent().add_child(skel)
	skel.dungeon = dungeon
	skel.turn_manager = turn_manager
	skel.move_to(at)
	turn_manager.register_enemy(skel)
	summoned_skeletons.append(skel)
	print("Lich summons a Skeleton at %s" % [at])
