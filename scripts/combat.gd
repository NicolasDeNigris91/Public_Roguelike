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

static func attack(attacker: Actor, target: Actor, ignore_def: bool = false) -> void:
	var dmg := calculate_damage(attacker, target, ignore_def)
	target.take_damage(dmg)
	var suffix: String
	if ignore_def:
		suffix = " (ignores DEF)"
	else:
		suffix = ""
	print("%s attacks %s for %d%s (target HP: %d/%d)" % [
		attacker.name, target.name, dmg, suffix, target.hp, target.max_hp
	])
