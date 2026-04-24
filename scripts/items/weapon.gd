class_name Weapon
extends Item

# Active ability fired with E. NONE = no special, else dispatched by Combat.
# Each act's signature weapon picks up a distinct ability (see ItemDB).
enum Ability { NONE, CLEAVE, QUAKE, DRAIN, HARVEST, FIREBOLT, CHAOS }

@export var atk_bonus: int = 0
# Optional impact burst spawned at the target on a successful melee hit.
# null means the weapon hits with no extra VFX (basic steel feel for early gear).
var melee_vfx: Texture2D = null

var ability: Ability = Ability.NONE
var ability_name: String = ""
var ability_description: String = ""
var ability_icon: Texture2D = null
