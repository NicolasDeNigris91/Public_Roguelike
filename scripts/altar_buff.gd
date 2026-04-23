class_name AltarBuff
# Maps an item to the permanent stat delta gained when it's sacrificed at an altar.
# Pure logic — no Player/autoload dependencies, testable in headless mode.

const STAT_ATK: StringName = &"atk"
const STAT_DEF: StringName = &"def"
const STAT_MAX_HP: StringName = &"max_hp"

# Returns a dictionary of the form:
#   {applicable: true, stat: StringName, delta: int}   — valid sacrifice
#   {applicable: false}                                — item cannot be sacrificed
static func compute(item: Item) -> Dictionary:
	if item is Weapon:
		return {"applicable": true, "stat": STAT_ATK, "delta": 2}
	if item is Armor:
		return {"applicable": true, "stat": STAT_DEF, "delta": 2}
	if item is Ring:
		return {"applicable": true, "stat": STAT_MAX_HP, "delta": 4}
	return {"applicable": false}
