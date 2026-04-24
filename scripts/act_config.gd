class_name ActConfig
# Central source of truth for floor → act/biome/boss mapping.
# Extended per act as the game expands (Act 1 → 2 → ... → 5).

const MAX_FLOOR: int = 30  # 5 acts x 6 floors. Boss every 6 — tighter pacing.

# Floors that end an act with a boss fight. Must stay sorted ascending.
const BOSS_FLOORS: Array[int] = [6, 12, 18, 24, 30]

# Biome keys — resolved to tile textures via SpriteDB.tile("floor_<biome>"), etc.
const BIOME_BASTION: StringName = &"bastion"
const BIOME_CATACOMBS: StringName = &"catacombs"
const BIOME_BLOOD_SANCTUM: StringName = &"blood_sanctum"
const BIOME_BURNING_HALLS: StringName = &"burning_halls"
const BIOME_INFERNAL_THRONE: StringName = &"infernal_throne"

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
		12:
			return DeathKnight.new()
		18:
			return Abomination.new()
		24:
			return FireGiant.new()
		30:
			return DemonLord.new()
	return null

static func biome_for_floor(floor: int) -> StringName:
	if floor <= 6:
		return BIOME_BASTION
	if floor <= 12:
		return BIOME_CATACOMBS
	if floor <= 18:
		return BIOME_BLOOD_SANCTUM
	if floor <= 24:
		return BIOME_BURNING_HALLS
	return BIOME_INFERNAL_THRONE

# Returns true if this is the FINAL boss floor of the game (closes the run).
# Today that's the end of Act 2 (18). When Acts 3-5 ship, this becomes floor 48.
static func is_final_boss_floor(floor: int) -> bool:
	return floor == MAX_FLOOR and is_boss_floor(floor)

# Returns the act number (1-5) that contains this floor.
static func act_for_floor(floor: int) -> int:
	if floor <= 6:
		return 1
	if floor <= 12:
		return 2
	if floor <= 18:
		return 3
	if floor <= 24:
		return 4
	return 5
