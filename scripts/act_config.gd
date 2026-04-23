class_name ActConfig
# Central source of truth for floor → act/biome/boss mapping.
# Extended per act as the game expands (Act 1 → 2 → ... → 5).

const MAX_FLOOR: int = 30  # Act 3 scope. Will grow to 48 as Acts 4-5 ship.

# Floors that end an act with a boss fight. Must stay sorted ascending.
const BOSS_FLOORS: Array[int] = [6, 18, 30]

# Biome keys — resolved to tile textures via SpriteDB.tile("floor_<biome>"), etc.
const BIOME_BASTION: StringName = &"bastion"
const BIOME_CATACOMBS: StringName = &"catacombs"
const BIOME_BLOOD_SANCTUM: StringName = &"blood_sanctum"

# Per-act soft cap on altar stat gains. Once the player hits these totals
# within a single act, further sacrifices still consume the item and the
# altar, but grant 0 stat. Resets when crossing into the next act.
# Keys match AltarBuff.STAT_* constants.
const ALTAR_CAP_PER_ACT := {
	&"atk": 4,
	&"def": 4,
	&"max_hp": 8,
}

static func is_boss_floor(floor: int) -> bool:
	return floor in BOSS_FLOORS

# Returns a fresh enemy instance for the boss of this floor, or null if none.
static func spawn_boss(floor: int) -> Enemy:
	match floor:
		6:
			return Lich.new()
		18:
			return DeathKnight.new()
		30:
			return Abomination.new()
	return null

# Returns the biome key for a floor. Acts 4+ will extend this.
static func biome_for_floor(floor: int) -> StringName:
	if floor <= 6:
		return BIOME_BASTION
	if floor <= 18:
		return BIOME_CATACOMBS
	if floor <= 30:
		return BIOME_BLOOD_SANCTUM
	return BIOME_BASTION

# Returns true if this is the FINAL boss floor of the game (closes the run).
# Today that's the end of Act 2 (18). When Acts 3-5 ship, this becomes floor 48.
static func is_final_boss_floor(floor: int) -> bool:
	return floor == MAX_FLOOR and is_boss_floor(floor)

# Returns the act number (1-5) that contains this floor.
static func act_for_floor(floor: int) -> int:
	if floor <= 6:
		return 1
	if floor <= 18:
		return 2
	if floor <= 30:
		return 3
	if floor <= 42:
		return 4
	return 5
