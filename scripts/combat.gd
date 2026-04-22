class_name Combat

const CRIT_CHANCE: float = 0.1
const CRIT_MULTIPLIER: int = 2

static func calculate_damage(attacker: Actor, target: Actor) -> int:
	var variance := randi_range(-1, 1)
	var base := attacker.atk - target.def + variance
	var dmg := maxi(1, base)
	if randf() < CRIT_CHANCE:
		dmg *= CRIT_MULTIPLIER
	return dmg

static func attack(attacker: Actor, target: Actor) -> void:
	var dmg := calculate_damage(attacker, target)
	target.take_damage(dmg)
	print("%s attacks %s for %d (target HP: %d/%d)" % [
		attacker.name, target.name, dmg, target.hp, target.max_hp
	])
