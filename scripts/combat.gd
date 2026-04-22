class_name Combat

const CRIT_CHANCE: float = 0.1
const CRIT_MULTIPLIER: int = 2

static func calculate_damage(attacker: Actor, target: Actor, ignore_def: bool = false) -> int:
	var def_val: int
	if ignore_def:
		def_val = 0
	else:
		def_val = target.def
	var variance := randi_range(-1, 1)
	var base := attacker.atk - def_val + variance
	var dmg := maxi(1, base)
	if randf() < CRIT_CHANCE:
		dmg *= CRIT_MULTIPLIER
	return dmg

static func attack(
	attacker: Actor,
	target: Actor,
	ignore_def: bool = false,
	lifesteal_ratio: float = 0.0,
	lifesteal_cap: int = -1
) -> void:
	var dmg := calculate_damage(attacker, target, ignore_def)
	target.take_damage(dmg)

	var healed := 0
	if lifesteal_ratio > 0.0 and attacker.hp > 0:
		var cap: int
		if lifesteal_cap >= 0:
			cap = lifesteal_cap
		else:
			cap = attacker.max_hp
		var raw_heal := int(floor(dmg * lifesteal_ratio))
		var new_hp := mini(cap, attacker.hp + raw_heal)
		healed = new_hp - attacker.hp
		attacker.hp = new_hp
		attacker.queue_redraw()

	var suffix: String
	if ignore_def:
		suffix = " (ignores DEF)"
	else:
		suffix = ""
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
