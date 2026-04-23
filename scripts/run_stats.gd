extends Node
# RunStats autoload. Tracks metrics for the current run. reset() is called
# from main.gd._ready at game start; recording methods are called from
# combat.gd, player.gd, and main.gd throughout gameplay. The death screen
# reads these fields when shown.

var floor_reached: int = 1
var enemies_killed: int = 0
var damage_dealt: int = 0
var damage_taken: int = 0
var turns_played: int = 0
var best_weapon_name: String = "(nenhuma)"
var best_weapon_atk: int = 0
var total_faith_gained: int = 0
var lich_defeated: bool = false

func reset() -> void:
	floor_reached = 1
	enemies_killed = 0
	damage_dealt = 0
	damage_taken = 0
	turns_played = 0
	best_weapon_name = "(nenhuma)"
	best_weapon_atk = 0
	total_faith_gained = 0
	lich_defeated = false

func record_kill() -> void:
	enemies_killed += 1

func record_damage_dealt(amount: int) -> void:
	damage_dealt += amount

func record_damage_taken(amount: int) -> void:
	damage_taken += amount

func record_turn() -> void:
	turns_played += 1

func record_floor(floor_num: int) -> void:
	floor_reached = maxi(floor_reached, floor_num)

func record_faith_gained() -> void:
	total_faith_gained += 1

func record_weapon_equipped(weapon: Weapon) -> void:
	if weapon.atk_bonus > best_weapon_atk:
		best_weapon_atk = weapon.atk_bonus
		best_weapon_name = weapon.display_name

func record_lich_defeated() -> void:
	lich_defeated = true
