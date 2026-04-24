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
	# Cache adjacency BEFORE the animation await — an actor can be freed
	# during the await (e.g. dying to a counterattack), and re-querying
	# _is_adjacent on a freed Node crashes with "previously freed".
	var is_melee: bool = _is_adjacent(attacker, target)

	if is_melee:
		await attacker.nudge_toward(target.grid_position)
	else:
		await _await_ranged_vfx(attacker, target)

	# If either side got freed during the animation, bail out — the damage
	# number and SFX for this hit become meaningless.
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return

	# SFX: hit sound (melee or ranged) + crit overlay
	if is_melee:
		AudioManager.play_sfx("melee_hit")
	else:
		AudioManager.play_sfx("ranged_hit")
	if is_crit:
		AudioManager.play_sfx("crit")

	target.flash_white()
	_spawn_melee_vfx(attacker, target, is_melee)
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

# Enemy-side mirror of Player.smite — used by Death Knight's Unholy Smite.
# Distinct from Combat.attack because it uses the crystal_spear VFX + searing
# burst and ignores DEF with a flat damage bonus, mirroring the player's smite.
static func enemy_smite(attacker: Actor, target: Actor, damage_bonus: int) -> void:
	var dmg: int = attacker.atk + damage_bonus
	AudioManager.play_sfx("smite")
	if effects_layer != null:
		var from := _tile_center(attacker.position)
		var to := _tile_center(target.position)
		await Projectile.spawn_directional(effects_layer, from, to, SpriteDB.crystal_spear_frames())
		Projectile.spawn_burst(effects_layer, to, SpriteDB.effect("searing_burst"), 0.25)
	# Actor may have been freed during the projectile travel.
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return
	target.flash_white()
	if effects_layer != null:
		var dmg_pos: Vector2 = target.position - Vector2(0, 8)
		DamageNumber.spawn(effects_layer, dmg_pos, "%d!" % dmg, DMG_COLOR_CRIT, 1.2)
	target.take_damage(dmg)
	if target is Player:
		AudioManager.play_sfx("player_hurt")
	print("%s unleashes Unholy Smite on %s for %d." % [attacker.name, target.name, dmg])
	HitPause.freeze(attacker.get_tree(), HIT_PAUSE_CRIT)

static func smite(attacker: Player, target: Enemy) -> void:
	var dmg: int = attacker.atk + Player.SMITE_DAMAGE_BONUS
	AudioManager.play_sfx("smite")
	if effects_layer != null:
		var from := _tile_center(attacker.position)
		var to := _tile_center(target.position)
		await Projectile.spawn_directional(effects_layer, from, to, SpriteDB.crystal_spear_frames())
		Projectile.spawn_burst(effects_layer, to, SpriteDB.effect("searing_burst"), 0.25)
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return
	target.flash_white()
	if effects_layer != null:
		var dmg_pos: Vector2 = target.position - Vector2(0, 8)
		DamageNumber.spawn(effects_layer, dmg_pos, "%d!" % dmg, DMG_COLOR_CRIT, 1.2)
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

# Weapon abilities (key E). Entry point — dispatches by kind so all ability
# logic stays in one file. Each ability handles its own SFX, VFX, damage, and
# post-effect (lifesteal, heal, AoE). Target nullability is already guarded
# by Player._find_ability_target; we trust the target here.
static func weapon_ability(attacker: Player, target: Enemy, ability: Weapon.Ability) -> void:
	match ability:
		Weapon.Ability.CLEAVE:
			await _ability_cleave(attacker, target)
		Weapon.Ability.QUAKE:
			await _ability_quake(attacker, target)
		Weapon.Ability.DRAIN:
			await _ability_drain(attacker, target)
		Weapon.Ability.HARVEST:
			await _ability_harvest(attacker, target)
		Weapon.Ability.FIREBOLT:
			await _ability_firebolt(attacker, target)
		Weapon.Ability.CHAOS:
			await _ability_chaos(attacker, target)

# Hits the primary target plus every enemy orthogonally adjacent to it.
static func _ability_cleave(attacker: Player, target: Enemy) -> void:
	AudioManager.play_sfx("melee_hit")
	await attacker.nudge_toward(target.grid_position)
	if not is_instance_valid(target):
		return
	_resolve_ability_hit(attacker, target, false, 0, 0.0, false, SpriteDB.effect("melee_cleave"))
	# Collect other enemies adjacent to the primary target, then strike.
	if attacker.turn_manager != null:
		var victims: Array = []
		for e in attacker.turn_manager.enemies:
			if not is_instance_valid(e) or e == target:
				continue
			var dx: int = absi(e.grid_position.x - target.grid_position.x)
			var dy: int = absi(e.grid_position.y - target.grid_position.y)
			if dx + dy == 1:
				victims.append(e)
		for v in victims:
			if is_instance_valid(v):
				_resolve_ability_hit(attacker, v, false, 0, 0.0, false, SpriteDB.effect("melee_cleave"))
	HitPause.freeze(attacker.get_tree(), HIT_PAUSE_CRIT)

# Heavy melee strike that ignores DEF entirely and adds +5 flat damage.
static func _ability_quake(attacker: Player, target: Enemy) -> void:
	AudioManager.play_sfx("melee_hit")
	await attacker.nudge_toward(target.grid_position)
	if not is_instance_valid(target):
		return
	_resolve_ability_hit(attacker, target, true, 5, 0.0, false, SpriteDB.effect("melee_sandblast"))
	HitPause.freeze(attacker.get_tree(), HIT_PAUSE_CRIT)

# Ranged necrotic bolt that heals the attacker for 100% of damage dealt.
static func _ability_drain(attacker: Player, target: Enemy) -> void:
	AudioManager.play_sfx("ranged_hit")
	if effects_layer != null:
		var from := _tile_center(attacker.position)
		var to := _tile_center(target.position)
		await Projectile.spawn(effects_layer, from, to, SpriteDB.effect("necro_bolt"))
	if not is_instance_valid(target):
		return
	_resolve_ability_hit(attacker, target, false, 0, 1.0, false, SpriteDB.effect("melee_necrotic"))
	HitPause.freeze(attacker.get_tree(), HIT_PAUSE_CRIT)

# Double-damage melee strike that also heals the attacker for a flat 5 HP.
static func _ability_harvest(attacker: Player, target: Enemy) -> void:
	AudioManager.play_sfx("melee_hit")
	await attacker.nudge_toward(target.grid_position)
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return
	_resolve_ability_hit(attacker, target, false, 0, 0.0, true, SpriteDB.effect("melee_blood"))
	# Flat heal on cast, separate from per-hit lifesteal.
	var new_hp: int = mini(attacker.max_hp, attacker.hp + 5)
	var healed: int = new_hp - attacker.hp
	attacker.hp = new_hp
	attacker.queue_redraw()
	if healed > 0:
		_spawn_damage_number(attacker, healed, false, true)
	HitPause.freeze(attacker.get_tree(), HIT_PAUSE_CRIT)

# Ranged fire projectile with +5 flat damage.
static func _ability_firebolt(attacker: Player, target: Enemy) -> void:
	AudioManager.play_sfx("ranged_hit")
	if effects_layer != null:
		var from := _tile_center(attacker.position)
		var to := _tile_center(target.position)
		await Projectile.spawn(effects_layer, from, to, SpriteDB.effect("melee_flame"))
	if not is_instance_valid(target):
		return
	_resolve_ability_hit(attacker, target, false, 5, 0.0, false, SpriteDB.effect("melee_flame"))
	HitPause.freeze(attacker.get_tree(), HIT_PAUSE_CRIT)

# Ranged chaos orb with a guaranteed critical hit (forced 2× damage).
static func _ability_chaos(attacker: Player, target: Enemy) -> void:
	AudioManager.play_sfx("ranged_hit")
	if effects_layer != null:
		var from := _tile_center(attacker.position)
		var to := _tile_center(target.position)
		await Projectile.spawn(effects_layer, from, to, SpriteDB.effect("melee_chaos"))
	if not is_instance_valid(target):
		return
	_resolve_ability_hit(attacker, target, false, 0, 0.0, false, SpriteDB.effect("melee_chaos"), true)
	HitPause.freeze(attacker.get_tree(), HIT_PAUSE_CRIT)

# Shared damage application for weapon abilities. Computes damage with the
# requested modifiers, applies lifesteal/heal/crit flags, spawns damage number
# and impact burst, and records stats.
static func _resolve_ability_hit(
	attacker: Player,
	target: Enemy,
	ignore_def: bool,
	bonus_damage: int,
	lifesteal_ratio: float,
	double_damage: bool,
	burst_texture: Texture2D,
	force_crit: bool = false
) -> void:
	if not is_instance_valid(target):
		return
	var dmg_info := calculate_damage(attacker, target, ignore_def)
	var dmg: int = dmg_info["dmg"] + bonus_damage
	var is_crit: bool = dmg_info["is_crit"] or force_crit
	if force_crit and not dmg_info["is_crit"]:
		dmg *= CRIT_MULTIPLIER
	if double_damage:
		dmg *= 2
	if is_crit:
		AudioManager.play_sfx("crit")
	target.flash_white()
	if effects_layer != null and burst_texture != null:
		Projectile.spawn_burst(effects_layer, _tile_center(target.position), burst_texture, 0.22)
	_spawn_damage_number(target, dmg, is_crit, false)
	target.take_damage(dmg)
	RunStats.record_damage_dealt(dmg)
	if target.hp <= 0:
		AudioManager.play_sfx("enemy_die")
		RunStats.record_kill()
		attacker.gain_faith()
	var healed := _apply_lifesteal(attacker, dmg, lifesteal_ratio, -1)
	if healed > 0:
		_spawn_damage_number(attacker, healed, false, true)

static func _await_ranged_vfx(attacker: Actor, target: Actor) -> void:
	if effects_layer == null:
		return
	var from := _tile_center(attacker.position)
	var to := _tile_center(target.position)
	if attacker.ranged_projectile_frames.size() >= 8:
		await Projectile.spawn_directional(effects_layer, from, to, attacker.ranged_projectile_frames)
	elif attacker.ranged_projectile_texture != null:
		await Projectile.spawn(effects_layer, from, to, attacker.ranged_projectile_texture)

static func _tile_center(world_pos: Vector2) -> Vector2:
	return world_pos + Vector2(Grid.TILE_SIZE, Grid.TILE_SIZE) * 0.5

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

# Per-weapon impact burst, player-only. Each late-game weapon has its own vfx
# so the player feels the difference (cleave/sandblast/necro/blood/flame/chaos).
static func _spawn_melee_vfx(attacker: Actor, target: Actor, is_melee: bool) -> void:
	if not is_melee or effects_layer == null or not (attacker is Player):
		return
	var weapon: Weapon = (attacker as Player).inventory.weapon
	if weapon == null or weapon.melee_vfx == null:
		return
	Projectile.spawn_burst(effects_layer, _tile_center(target.position), weapon.melee_vfx, 0.22)

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
