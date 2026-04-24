class_name AltarBuff
# Maps an item to the permanent stat deltas gained when it's sacrificed at an altar.
# Pure logic — no Player/autoload dependencies, testable in headless mode.

const STAT_ATK: StringName = &"atk"
const STAT_DEF: StringName = &"def"
const STAT_MAX_HP: StringName = &"max_hp"

# Returns a dictionary of the form:
#   {
#     applicable: true,
#     stat: StringName,       # primary stat (drives the flash tween + SFX)
#     delta: int,             # primary delta
#     secondary: Dictionary,  # {StringName -> int} small bonuses to other stats
#   }
# or {applicable: false} when the item can't be sacrificed.
#
# Secondary bonuses encode the "every sacrifice helps the other pillars too"
# fantasy: a weapon gives mostly ATK plus a sliver of HP, etc. All deltas
# (primary + each secondary) still respect the per-act soft cap.
static func compute(item: Item) -> Dictionary:
	if item is Weapon:
		return {
			"applicable": true,
			"stat": STAT_ATK,
			"delta": 2,
			"secondary": {STAT_MAX_HP: 1},
		}
	if item is Armor:
		return {
			"applicable": true,
			"stat": STAT_DEF,
			"delta": 2,
			"secondary": {STAT_MAX_HP: 1},
		}
	if item is Shield:
		return {
			"applicable": true,
			"stat": STAT_DEF,
			"delta": 2,
			"secondary": {STAT_MAX_HP: 1},
		}
	if item is Ring:
		return {
			"applicable": true,
			"stat": STAT_MAX_HP,
			"delta": 4,
			"secondary": {},
		}
	return {"applicable": false}
