class_name Combat

const CRIT_CHANCE: float = 0.1
const CRIT_MULTIPLIER: int = 2

const DMG_COLOR_NORMAL := Color("#ff5555")
const DMG_COLOR_CRIT := Color("#ffaa00")
const DMG_COLOR_HEAL := Color("#55ff55")
const CRIT_SCALE: float = 1.3

const HIT_PAUSE_NORMAL: float = 0.05
const HIT_PAUSE_CRIT: float = 0.1

const SHAKE_HIT_NORMAL := Vector2(3.0, 0.1)
const SHAKE_HIT_CRIT := Vector2(6.0, 0.2)
const SHAKE_DEATH := Vector2(10.0, 0.4)

static var effects_layer: Node2D = null
static var world_node: Node2D = null

static func calculate_damage(attacker: Actor, target: Actor, ignore_def: bool = false) -> Dictionary:
	var def_val: int
	if ignore_def:
		def_val = 0
	else:
		def_val = target.def
	var variance := randi_range(-1, 1)
	var base := attacker.atk - def_val + variance
	var dmg := maxi(1, base)
	var is_crit := randf() < CRIT_CHANCE
	if is_crit:
		dmg *= CRIT_MULTIPLIER
	return {"dmg": dmg, "is_crit": is_crit}

static func attack(
	attacker: Actor,
	target: Actor,
	ignore_def: bool = false,
	lifesteal_ratio: float = 0.0,
	lifesteal_cap: int = -1
) -> void:
	var dmg_info := calculate_damage(attacker, target, ignore_def)
	var dmg: int = dmg_info["dmg"]
	var is_crit: bool = dmg_info["is_crit"]

	if _is_adjacent(attacker, target):
		await attacker.nudge_toward(target.grid_position)

	# SFX: hit sound (melee or ranged) + crit overlay
	if _is_adjacent(attacker, target):
		AudioManager.play_sfx("melee_hit")
	else:
		AudioManager.play_sfx("ranged_hit")
	if is_crit:
		AudioManager.play_sfx("crit")

	target.flash_white()
	_spawn_damage_number(target, dmg, is_crit, false)

	target.take_damage(dmg)

	if attacker is Player:
		RunStats.record_damage_dealt(dmg)

	# SFX: target-specific post-hit sounds
	if target.hp <= 0:
		if not (target is Player):
			AudioManager.play_sfx("enemy_die")
			RunStats.record_kill()
			if attacker is Player:
				(attacker as Player).gain_faith()
		# Player death SFX is handled by Player.die() in Task 3.
	elif target is Player:
		AudioManager.play_sfx("player_hurt")

	var healed := _apply_lifesteal(attacker, dmg, lifesteal_ratio, lifesteal_cap)
	if healed > 0:
		_spawn_damage_number(attacker, healed, false, true)

	if target is Player:
		_apply_shake(target, is_crit)

	var suffix: String = " (ignores DEF)" if ignore_def else ""
	if healed > 0:
		print("%s attacks %s for %d%s (target HP: %d/%d, healed %d → %d/%d)" % [
			attacker.name, target.name, dmg, suffix,
			target.hp, target.max_hp,
			healed, attacker.hp, attacker.max_hp
		])
	else:
		print("%s attacks %s for %d%s (target HP: %d/%d)" % [
			attacker.name, target.name, dmg, suffix, target.hp, target.max_hp
		])

	var pause: float = HIT_PAUSE_CRIT if is_crit else HIT_PAUSE_NORMAL
	HitPause.freeze(target.get_tree(), pause)

static func smite(attacker: Player, target: Enemy) -> void:
	var dmg: int = attacker.atk + Player.SMITE_DAMAGE_BONUS
	target.flash_white()
	AudioManager.play_sfx("smite")
	if effects_layer != null:
		var world_pos: Vector2 = target.position - Vector2(0, 8)
		DamageNumber.spawn(effects_layer, world_pos, "%d!" % dmg, DMG_COLOR_CRIT, 1.2)
	target.take_damage(dmg)
	RunStats.record_damage_dealt(dmg)
	if target.hp <= 0:
		AudioManager.play_sfx("enemy_die")
		RunStats.record_kill()
		attacker.gain_faith()
	print("%s smites %s for %d (target HP: %d/%d)" % [
		attacker.name, target.name, dmg, target.hp, target.max_hp
	])
	HitPause.freeze(attacker.get_tree(), HIT_PAUSE_CRIT)

static func _is_adjacent(a: Actor, b: Actor) -> bool:
	var dx: int = absi(a.grid_position.x - b.grid_position.x)
	var dy: int = absi(a.grid_position.y - b.grid_position.y)
	return (dx + dy) == 1

static func _apply_lifesteal(attacker: Actor, dmg: int, ratio: float, cap: int) -> int:
	if ratio <= 0.0 or attacker.hp <= 0:
		return 0
	var effective_cap: int = cap if cap >= 0 else attacker.max_hp
	var raw_heal := int(floor(dmg * ratio))
	var new_hp: int = mini(effective_cap, attacker.hp + raw_heal)
	var healed: int = new_hp - attacker.hp
	attacker.hp = new_hp
	attacker.queue_redraw()
	return healed

static func _spawn_damage_number(target: Actor, amount: int, is_crit: bool, is_heal: bool) -> void:
	if effects_layer == null:
		return
	var text: String
	var color: Color
	var scale: float
	if is_heal:
		text = "+%d" % amount
		color = DMG_COLOR_HEAL
		scale = 1.0
	elif is_crit:
		text = "%d!" % amount
		color = DMG_COLOR_CRIT
		scale = CRIT_SCALE
	else:
		text = "%d" % amount
		color = DMG_COLOR_NORMAL
		scale = 1.0
	var world_pos: Vector2 = target.position - Vector2(0, 8)
	DamageNumber.spawn(effects_layer, world_pos, text, color, scale)

static func _apply_shake(target: Actor, is_crit: bool) -> void:
	# Skip when the target died on this hit — Player.die fires its own bigger
	# death shake stinger, and we don't want the smaller hit shake to kill its tween.
	if world_node == null or target.hp <= 0:
		return
	var shake: Vector2 = SHAKE_HIT_CRIT if is_crit else SHAKE_HIT_NORMAL
	Shake.apply(world_node, shake.x, shake.y)
