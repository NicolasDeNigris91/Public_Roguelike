extends Node
# SaveManager autoload. Single-slot persistence at user://savegame.json.
# Save is written on floor descent; cleared on player death or Lich victory.
# Mid-floor state (dungeon, enemies, FOV, items-on-floor) is intentionally NOT
# serialized — the next floor regenerates fresh on load.

const SAVE_PATH: String = "user://savegame.json"
const CURRENT_VERSION: int = 2

var pending_load: bool = false

func has_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	# Load once to validate: corrupt / stale saves auto-clear and return false.
	return not load_state().is_empty()

func save(floor: int, player: Player, altars: Array = []) -> void:
	var state := {
		"version": CURRENT_VERSION,
		"floor": floor,
		"player": _serialize_player(player),
		"run_stats": _serialize_run_stats(),
		"altars": _serialize_altars(altars),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: failed to open save file for writing")
		return
	file.store_string(JSON.stringify(state))
	file.close()

func load_state() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_warning("SaveManager: JSON parse error, clearing save")
		clear()
		return {}

	var state: Variant = json.data
	if typeof(state) != TYPE_DICTIONARY:
		push_warning("SaveManager: save not a dictionary, clearing")
		clear()
		return {}

	if state.get("version") != CURRENT_VERSION:
		push_warning("SaveManager: version mismatch, clearing")
		clear()
		return {}

	for key in ["floor", "player", "run_stats"]:
		if not state.has(key):
			push_warning("SaveManager: missing key '%s', clearing" % key)
			clear()
			return {}
	if not state.has("altars"):
		state["altars"] = []

	if not _validate_item_paths(state["player"]):
		push_warning("SaveManager: invalid item path in save, clearing")
		clear()
		return {}

	return state

func clear() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

func _serialize_player(player: Player) -> Dictionary:
	var equipped := {
		"weapon": _id_or_null(player.inventory.weapon),
		"armor": _id_or_null(player.inventory.armor),
		"ring": _id_or_null(player.inventory.ring),
	}
	var bag: Array = []
	for item in player.inventory.bag:
		bag.append(item.id)
	return {
		"hp": player.hp,
		"max_hp": player.max_hp,
		"faith": player.faith,
		"vision_range": player.vision_range,
		"vision_debuff_turns": player.vision_debuff_turns,
		"bonus_atk": player.bonus_atk,
		"bonus_def": player.bonus_def,
		"bonus_max_hp": player.bonus_max_hp,
		"equipped": equipped,
		"bag": bag,
	}

func _id_or_null(item: Item) -> Variant:
	if item == null:
		return null
	return item.id

func _serialize_run_stats() -> Dictionary:
	return {
		"floor_reached": RunStats.floor_reached,
		"enemies_killed": RunStats.enemies_killed,
		"damage_dealt": RunStats.damage_dealt,
		"damage_taken": RunStats.damage_taken,
		"turns_played": RunStats.turns_played,
		"best_weapon_name": RunStats.best_weapon_name,
		"best_weapon_atk": RunStats.best_weapon_atk,
		"total_faith_gained": RunStats.total_faith_gained,
		"lich_defeated": RunStats.lich_defeated,
	}

func _serialize_altars(altars: Array) -> Array:
	var out: Array = []
	for a in altars:
		if not (a is Altar):
			continue
		out.append({
			"x": a.grid_position.x,
			"y": a.grid_position.y,
			"consumed": a.consumed,
		})
	return out

func _validate_item_paths(player_dict: Dictionary) -> bool:
	var equipped: Dictionary = player_dict.get("equipped", {})
	for slot in ["weapon", "armor", "ring"]:
		var id: Variant = equipped.get(slot)
		if id != null and ItemDB.from_id(id) == null:
			return false
	var bag: Array = player_dict.get("bag", [])
	for id in bag:
		if ItemDB.from_id(id) == null:
			return false
	return true
