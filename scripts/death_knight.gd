class_name DeathKnight
extends Enemy
# Act 2 mini-boss (floor 18). Corrupted paladin — dark mirror of Benedict.
# Two HP-driven phases:
#   Phase 1 (HP > 30): melee aggressive + summon a Skeleton on cooldown
#   Phase 2 (HP <= 30): enraged — +2 ATK and lifesteal attacks
# No mini-revive (simpler than the Lich).

signal truly_died(final_pos: Vector2i)

const PHASE_2_THRESHOLD: int = 30
const BASE_ATK: int = 10
const RAGE_ATK_BONUS: int = 2
const LIFESTEAL_RATIO: float = 0.4
const LIFESTEAL_CAP: int = 30
const SUMMON_COOLDOWN_MAX: int = 5
const SUMMON_CAP: int = 2
const VISION: int = 14

var phase: int = 1
var previous_phase: int = 1
var summon_cooldown: int = 0
var summoned_skeletons: Array[Skeleton] = []

func _ready() -> void:
	name = "Death Knight"
	hp = 60
	max_hp = 60
	atk = BASE_ATK
	def = 3
	vision_range = VISION
	always_takes_turn = true
	super._ready()
	sprite_node.texture = SpriteDB.actor("death_knight")

func take_turn() -> void:
	if turn_manager == null or not is_instance_valid(turn_manager.player):
		return

	_update_phase()

	var player := turn_manager.player
	var dist := _distance_to(player.grid_position)

	# Phase 1: try to summon if cooldown ready and cap not reached
	if phase == 1:
		_prune_dead_summons()
		if summon_cooldown == 0 and summoned_skeletons.size() < SUMMON_CAP:
			var tile := _find_summon_tile()
			if tile != Vector2i(-1, -1):
				_summon_skeleton(tile)
				summon_cooldown = SUMMON_COOLDOWN_MAX
				return
		if summon_cooldown > 0:
			summon_cooldown -= 1

	# Melee attack if adjacent
	if dist == 1:
		if phase == 2:
			Combat.attack(self, player, false, LIFESTEAL_RATIO, LIFESTEAL_CAP)
		else:
			Combat.attack(self, player)
		return

	# Step toward player
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
		print("Death Knight enters phase 2 (hp %d/%d) — atk raised to %d" % [hp, max_hp, atk])

func die() -> void:
	truly_died.emit(grid_position)
	super.die()

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
	AudioManager.play_sfx("summon")
	if Combat.effects_layer != null:
		var world_pos := Vector2(at.x, at.y) * Grid.TILE_SIZE + Vector2(Grid.TILE_SIZE, Grid.TILE_SIZE) * 0.5
		Projectile.spawn_burst(Combat.effects_layer, world_pos, SpriteDB.effect("necro_bolt"), 0.35)
	var skel := Skeleton.new()
	get_parent().add_child(skel)
	skel.dungeon = dungeon
	skel.turn_manager = turn_manager
	skel.move_to(at, false)
	turn_manager.register_enemy(skel)
	summoned_skeletons.append(skel)
	print("Death Knight summons a Skeleton at %s" % [at])
