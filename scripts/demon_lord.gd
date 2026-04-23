class_name DemonLord
extends Enemy
# Floor 48 FINAL BOSS. The Balrug — lord of the Infernal Throne, source of
# the profanation that corrupted the Bastion, the Catacombs, the Blood
# Sanctum, and the Burning Halls.
#
# Three HP-driven phases — each echoing a prior act boss so the fight reads
# as the culmination of everything Benedict learned:
#   Phase 1 (HP > 100): Lich-style — melee + summon Imps (cooldown 4, cap 2)
#   Phase 2 (HP 100-40): Fire Giant — stops summoning, gains ranged fire
#                        hurl at up to 5 tiles with LOS
#   Phase 3 (HP <= 40): Death Knight — enraged, +4 ATK, lifesteal 40%,
#                       melee only (ranged drops). Kite no more.
# Also has a Lich-style MINI-REVIVE: dies once, comes back at 30 HP and
# drops straight into phase 3. The Demon Lord does not go quietly.

signal truly_died(final_pos: Vector2i)

const PHASE_2_THRESHOLD: int = 100
const PHASE_3_THRESHOLD: int = 40
const BASE_ATK: int = 14
const RAGE_ATK_BONUS: int = 4
const LIFESTEAL_RATIO: float = 0.4
const LIFESTEAL_CAP: int = 40
const RANGED_RANGE: int = 5
const SUMMON_COOLDOWN_MAX: int = 4
const SUMMON_CAP: int = 2
const VISION: int = 16
const REVIVE_HP: int = 30

var phase: int = 1
var previous_phase: int = 1
var summon_cooldown: int = 0
var summoned_imps: Array[Imp] = []
var has_revived: bool = false

func _ready() -> void:
	name = "Demon Lord"
	hp = 150
	max_hp = 150
	atk = BASE_ATK
	def = 4
	vision_range = VISION
	always_takes_turn = true
	ranged_projectile_texture = SpriteDB.effect("magic_bolt")
	super._ready()
	sprite_node.texture = SpriteDB.actor("demon_lord")

func take_turn() -> void:
	if turn_manager == null or not is_instance_valid(turn_manager.player):
		return

	_update_phase()

	var player := turn_manager.player
	var dist := _distance_to(player.grid_position)

	# Phase 1: prioritize summoning Imps to flood the throne room.
	if phase == 1:
		_prune_dead_summons()
		if summon_cooldown == 0 and summoned_imps.size() < SUMMON_CAP:
			var tile := _find_summon_tile()
			if tile != Vector2i(-1, -1):
				_summon_imp(tile)
				summon_cooldown = SUMMON_COOLDOWN_MAX
				return
		if summon_cooldown > 0:
			summon_cooldown -= 1

	# Adjacent melee always available.
	if dist == 1:
		if phase == 3:
			Combat.attack(self, player, false, LIFESTEAL_RATIO, LIFESTEAL_CAP)
		else:
			Combat.attack(self, player)
		return

	# Phase 2: ranged fire hurl at range, LOS required.
	if phase == 2 and dist <= RANGED_RANGE and FOV.has_line_of_sight(dungeon.grid, grid_position, player.grid_position):
		Combat.attack(self, player, true)  # ignore DEF — infernal fire
		return

	if dist <= vision_range:
		var next_pos := _step_toward(player.grid_position)
		if next_pos != player.grid_position and dungeon.grid.is_walkable(next_pos):
			move_to(next_pos)

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
		if phase == 3:
			atk = BASE_ATK + RAGE_ATK_BONUS
		else:
			atk = BASE_ATK
		print("Demon Lord enters phase %d (hp %d/%d, atk %d)" % [phase, hp, max_hp, atk])

func die() -> void:
	if not has_revived:
		has_revived = true
		hp = REVIVE_HP
		atk = BASE_ATK + RAGE_ATK_BONUS
		summon_cooldown = 0
		queue_redraw()
		flash_white()
		AudioManager.play_sfx("lich_revive")
		if Combat.world_node != null:
			Shake.apply(Combat.world_node, 8.0, 0.5)
			HitPause.freeze(get_tree(), 0.3)
		print("The Demon Lord rises from the lava! (hp %d/%d)" % [REVIVE_HP, max_hp])
		return
	truly_died.emit(grid_position)
	super.die()

func _prune_dead_summons() -> void:
	var alive: Array[Imp] = []
	for s in summoned_imps:
		if is_instance_valid(s):
			alive.append(s)
	summoned_imps = alive

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

func _summon_imp(at: Vector2i) -> void:
	AudioManager.play_sfx("summon")
	if Combat.effects_layer != null:
		var world_pos := Vector2(at.x, at.y) * Grid.TILE_SIZE + Vector2(Grid.TILE_SIZE, Grid.TILE_SIZE) * 0.5
		Projectile.spawn_burst(Combat.effects_layer, world_pos, SpriteDB.effect("searing_burst"), 0.35)
	var imp := Imp.new()
	get_parent().add_child(imp)
	imp.dungeon = dungeon
	imp.turn_manager = turn_manager
	imp.move_to(at, false)
	turn_manager.register_enemy(imp)
	summoned_imps.append(imp)
	print("Demon Lord summons an Imp at %s" % [at])
