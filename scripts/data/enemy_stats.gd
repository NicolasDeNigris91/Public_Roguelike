class_name EnemyStats
# Single source of truth for every non-boss enemy's base numbers + its
# per-floor scaling behaviour. Behaviour (take_turn, special abilities)
# stays in the individual .gd; this file owns *what* the enemy is, not
# *how* it acts. Balance passes become one-file diffs.
#
# STATS["<sprite_key>"] fields:
#   display_name (str)       - shown in game logs / run stats
#   hp (int)                 - base hp (max_hp mirrors on spawn)
#   atk (int)                - base ATK, before per-act scaling
#   def (int)                - flat DEF
#   vision (int)             - aggro / LOS range for movement, 0 keeps default
#   atk_per_act (float)      - ATK bonus per act past act 1. 0 means fixed.
#                              e.g. a value of 1.0 gives +1 in act 2, +2 in
#                              act 3, etc. Lets a Wraith stay spicy without
#                              scaling as hard as a Rotting Hulk.

const STATS := {
	"slime":        {"display_name": "Slime",        "hp": 5,  "atk": 2,  "def": 0, "vision": 0,  "atk_per_act": 0.0},
	"skeleton":     {"display_name": "Skeleton",     "hp": 8,  "atk": 4,  "def": 0, "vision": 0,  "atk_per_act": 1.0},
	"archer":       {"display_name": "Archer",       "hp": 6,  "atk": 5,  "def": 0, "vision": 0,  "atk_per_act": 1.0},
	"mage":         {"display_name": "Mage",         "hp": 10, "atk": 6,  "def": 0, "vision": 0,  "atk_per_act": 1.0},
	"wraith":       {"display_name": "Wraith",       "hp": 4,  "atk": 1,  "def": 0, "vision": 0,  "atk_per_act": 0.5},
	"necrophage":   {"display_name": "Necrophage",   "hp": 14, "atk": 6,  "def": 1, "vision": 0,  "atk_per_act": 1.0},
	"flayed_ghost": {"display_name": "Flayed Ghost", "hp": 10, "atk": 7,  "def": 0, "vision": 0,  "atk_per_act": 0.5},
	"rotting_hulk": {"display_name": "Rotting Hulk", "hp": 22, "atk": 8,  "def": 3, "vision": 0,  "atk_per_act": 1.5},
	"hell_hound":   {"display_name": "Hell Hound",   "hp": 14, "atk": 10, "def": 1, "vision": 0,  "atk_per_act": 1.0},
	"salamander":   {"display_name": "Salamander",   "hp": 16, "atk": 8,  "def": 1, "vision": 0,  "atk_per_act": 1.0},
	"hellwing":     {"display_name": "Hellwing",     "hp": 12, "atk": 9,  "def": 0, "vision": 0,  "atk_per_act": 1.0},
	"executioner":  {"display_name": "Executioner",  "hp": 24, "atk": 12, "def": 3, "vision": 0,  "atk_per_act": 1.5},
	"imp":          {"display_name": "Imp",          "hp": 8,  "atk": 9,  "def": 0, "vision": 0,  "atk_per_act": 0.5},
}

# Copies the STATS row into the Enemy node. Call from each subclass' _ready
# before super._ready(). sprite_key doubles as the STATS dict key and the
# SpriteDB.actor() key so lookups stay aligned.
static func apply(enemy: Enemy, sprite_key: String) -> void:
	var row: Dictionary = STATS[sprite_key]
	enemy.sprite_key = sprite_key
	enemy.name = row["display_name"]
	enemy.hp = row["hp"]
	enemy.max_hp = row["hp"]
	enemy.atk = row["atk"]
	enemy.def = row["def"]
	if int(row["vision"]) > 0:
		enemy.vision_range = int(row["vision"])

# Per-enemy scaling: returns the ATK bonus the given enemy should receive
# on the given floor. Replaces the blanket (floor-1)/2 that was applied to
# every enemy uniformly and forced 4 balance passes to tame the Wraith.
static func atk_bonus_for(sprite_key: String, floor_num: int) -> int:
	var row: Dictionary = STATS[sprite_key]
	var act: int = ActConfig.act_for_floor(floor_num)
	return int(floor(float(row["atk_per_act"]) * float(act - 1)))
