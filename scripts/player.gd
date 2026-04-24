class_name Player
extends Actor

signal turn_done
signal item_dropped(item: Item, pos: Vector2i)
signal faith_changed(faith: int, max_faith: int)
signal stat_increased(stat: StringName, delta: int)

const BASE_ATK: int = 6
const BASE_DEF: int = 3
const BASE_MAX_HP: int = 25
const BASE_VISION_RANGE: int = 8
const MAX_FAITH: int = 3
const SMITE_RANGE: int = 5
const SMITE_DAMAGE_BONUS: int = 3

var dungeon: Dungeon
var turn_manager: TurnManager
var hotbar: CanvasLayer = null
var bonus_atk: int = 0
var bonus_def: int = 0
var bonus_max_hp: int = 0
# Debug / playtest flag. Toggled by F1 in main.gd — take_damage no-ops when on.
# Not serialized; resets on restart.
var godmode: bool = false
# Per-act running totals of altar-granted stats. Reset by main.gd.reset_altar_cap
# when the player descends into a new act (ActConfig.act_for_floor changes).
# Sacrifices that would push gain past the per-act cap still consume the item
# and altar but grant 0 stat.
var altar_gains_this_act: Dictionary = {
	&"atk": 0,
	&"def": 0,
	&"max_hp": 0,
}
# Timed buffs from consumables. Key: StringName stat ("atk" / "def").
# Value: {bonus: int, turns_left: int}. Ticks down each turn; at 0 the buff
# expires. Cleared on death, serialized across saves.
var timed_buffs: Dictionary = {}
var turn_active: bool = true
var inventory: Inventory
var vision_range: int = BASE_VISION_RANGE
var vision_debuff_turns: int = 0
var faith: int = 0
var _last_direction: Vector2i = Vector2i(0, -1)

func _ready() -> void:
	max_hp = BASE_MAX_HP
	hp = BASE_MAX_HP
	inventory = Inventory.new()
	_recalculate_stats()
	super._ready()
	sprite_node.texture = SpriteDB.actor("player")

func _unhandled_input(event: InputEvent) -> void:
	if hp <= 0 or not turn_active or is_tweening:
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	if event.keycode == KEY_Q:
		get_viewport().set_input_as_handled()
		if await try_smite():
			_end_turn()
		return

	var direction := Vector2i.ZERO
	match event.keycode:
		KEY_UP, KEY_W:
			direction = Vector2i(0, -1)
		KEY_DOWN, KEY_S:
			direction = Vector2i(0, 1)
		KEY_LEFT, KEY_A:
			direction = Vector2i(-1, 0)
		KEY_RIGHT, KEY_D:
			direction = Vector2i(1, 0)
		_:
			return

	get_viewport().set_input_as_handled()
	_last_direction = direction

	var target_pos := grid_position + direction
	var target_enemy := _enemy_at(target_pos)

	if target_enemy != null:
		await Combat.attack(self, target_enemy)
		_end_turn()
	elif dungeon and dungeon.grid.is_walkable(target_pos):
		AudioManager.play_sfx("step")
		move_to(target_pos)
		await moved
		_end_turn()

func try_smite() -> bool:
	if faith <= 0:
		return false
	var target := _find_smite_target(_last_direction)
	if target == null:
		return false
	faith -= 1
	faith_changed.emit(faith, MAX_FAITH)
	_notify_hotbar()
	await Combat.smite(self, target)
	return true

func gain_faith() -> void:
	if faith >= MAX_FAITH:
		return
	faith += 1
	RunStats.record_faith_gained()
	faith_changed.emit(faith, MAX_FAITH)
	_notify_hotbar()

func _find_smite_target(direction: Vector2i) -> Enemy:
	if dungeon == null or direction == Vector2i.ZERO:
		return null
	for i in range(1, SMITE_RANGE + 1):
		var check_pos: Vector2i = grid_position + direction * i
		if not dungeon.grid.in_bounds(check_pos):
			return null
		if dungeon.grid.get_cell(check_pos) == Grid.CellType.WALL:
			return null
		var enemy := _enemy_at(check_pos)
		if enemy != null:
			return enemy
	return null

func _end_turn() -> void:
	RunStats.record_turn()
	if vision_debuff_turns > 0:
		vision_debuff_turns -= 1
		if vision_debuff_turns == 0:
			vision_range = BASE_VISION_RANGE
			if dungeon != null:
				dungeon.update_fov(grid_position, vision_range)
			print("Player vision restored")
	_tick_timed_buffs()
	turn_done.emit()

# Adds or refreshes a timed buff. If already active, refreshes the duration
# (taking the longer of current and new) and replaces the bonus with whichever
# is stronger. This avoids exploits from stacking multiple potions.
func apply_timed_buff(stat: StringName, bonus: int, duration: int) -> void:
	var existing: Dictionary = timed_buffs.get(stat, {})
	var new_bonus: int = maxi(int(existing.get("bonus", 0)), bonus)
	var new_turns: int = maxi(int(existing.get("turns_left", 0)), duration)
	timed_buffs[stat] = {"bonus": new_bonus, "turns_left": new_turns}
	_recalculate_stats()
	stat_increased.emit(stat, bonus)

func _tick_timed_buffs() -> void:
	var expired: Array = []
	for stat in timed_buffs.keys():
		var entry: Dictionary = timed_buffs[stat]
		entry["turns_left"] = int(entry["turns_left"]) - 1
		if entry["turns_left"] <= 0:
			expired.append(stat)
		else:
			timed_buffs[stat] = entry
	for stat in expired:
		timed_buffs.erase(stat)
		print("Buff expired: %s" % stat)
	if not expired.is_empty():
		_recalculate_stats()
		_notify_hotbar()

func apply_vision_debuff(new_range: int, turns: int) -> void:
	vision_range = new_range
	vision_debuff_turns = turns
	if dungeon != null:
		dungeon.update_fov(grid_position, vision_range)
	print("Player vision reduced to %d for %d turns" % [new_range, turns])

func pickup(item: Item) -> bool:
	AudioManager.play_sfx("pickup")
	var result := pickup_item(item)
	match result:
		Inventory.PickupResult.EQUIPPED, Inventory.PickupResult.EQUIPPED_AND_BAGGED_OLD:
			if item is Weapon:
				RunStats.record_weapon_equipped(item as Weapon)
			_recalculate_stats()
			print("Picked up %s — equipped" % item.display_name)
		Inventory.PickupResult.EQUIPPED_AND_DROPPED_OLD:
			# Rosary swap: the displaced shield falls at Benedict's feet so
			# the swap is reversible. item_dropped is wired up in main.gd
			# to spawn an ItemEntity at the given position.
			_recalculate_stats()
			if inventory.pending_floor_drop != null:
				var dropped: Item = inventory.pending_floor_drop
				inventory.pending_floor_drop = null
				item_dropped.emit(dropped, grid_position)
				print("Picked up %s — %s falls to the floor" % [item.display_name, dropped.display_name])
			else:
				print("Picked up %s" % item.display_name)
		Inventory.PickupResult.BAGGED:
			print("Picked up %s — in bag" % item.display_name)
		Inventory.PickupResult.REJECTED_BAG_FULL:
			print("Bag full — left %s on the floor" % item.display_name)
	_notify_hotbar()
	return result != Inventory.PickupResult.REJECTED_BAG_FULL

func pickup_item(item: Item) -> Inventory.PickupResult:
	return inventory.try_pickup(item)

func die() -> void:
	AudioManager.play_sfx("player_die")
	AudioManager.stop_music(0.5)
	if Combat.world_node != null:
		Shake.apply(Combat.world_node, Combat.SHAKE_DEATH.x, Combat.SHAKE_DEATH.y)
		HitPause.freeze(get_tree(), 0.1)
	died.emit()
	turn_active = false
	_notify_hotbar()

func apply_altar_buff(item: Item) -> bool:
	var buff := AltarBuff.compute(item)
	if not buff["applicable"]:
		return false
	var primary_stat: StringName = buff["stat"]
	var primary_delta: int = buff["delta"]
	var primary_applied := _apply_altar_delta(primary_stat, primary_delta)
	# Secondary bonuses (e.g. weapon -> +1 HP as well) go through the same
	# per-act cap but do NOT flash the hotbar; only the primary stat gets the
	# gold-pulse feedback so the player reads the sacrifice at a glance.
	var secondary: Dictionary = buff.get("secondary", {})
	var any_secondary_applied := false
	for stat: StringName in secondary.keys():
		if _apply_altar_delta(stat, int(secondary[stat])) > 0:
			any_secondary_applied = true
	if primary_applied > 0:
		stat_increased.emit(primary_stat, primary_applied)
	elif any_secondary_applied:
		# Primary was capped but some secondary still landed — no primary
		# flash. Nothing else to do: the secondaries mutated stats silently.
		pass
	else:
		# Nothing landed: the dark god takes the offering but grants nothing
		# because every relevant stat is capped for this act.
		print("Altar accepts the offering, but the darkness is sated for this act.")
	# Return true so the caller consumes the item + altar visuals regardless.
	return true

# Applies a single stat delta respecting the per-act cap. Returns how much
# actually landed (0 if the cap was already reached).
func _apply_altar_delta(stat: StringName, raw_delta: int) -> int:
	if raw_delta <= 0:
		return 0
	var cap: int = int(ActConfig.ALTAR_CAP_PER_ACT.get(stat, 0))
	var current_gain: int = int(altar_gains_this_act.get(stat, 0))
	var effective: int = maxi(0, mini(raw_delta, cap - current_gain))
	if effective <= 0:
		return 0
	altar_gains_this_act[stat] = current_gain + effective
	match stat:
		AltarBuff.STAT_ATK:
			bonus_atk += effective
		AltarBuff.STAT_DEF:
			bonus_def += effective
		AltarBuff.STAT_MAX_HP:
			bonus_max_hp += effective
	_recalculate_stats()
	return effective

func reset_altar_cap() -> void:
	altar_gains_this_act = {&"atk": 0, &"def": 0, &"max_hp": 0}

func _recalculate_stats() -> void:
	atk = BASE_ATK + bonus_atk
	def = BASE_DEF + bonus_def
	if inventory.weapon != null:
		atk += inventory.weapon.atk_bonus
	if inventory.armor != null:
		def += inventory.armor.def_bonus
	if inventory.shield != null:
		def += inventory.shield.def_bonus
	if inventory.ring != null:
		atk += inventory.ring.atk_bonus
		def += inventory.ring.def_bonus
	if inventory.amulet != null:
		atk += inventory.amulet.atk_bonus
		def += inventory.amulet.def_bonus
	# Timed buffs from consumables — transient, top-up on everything else.
	if timed_buffs.has(&"atk"):
		atk += int(timed_buffs[&"atk"]["bonus"])
	if timed_buffs.has(&"def"):
		def += int(timed_buffs[&"def"]["bonus"])

	var new_max_hp := BASE_MAX_HP + bonus_max_hp
	if inventory.ring != null:
		new_max_hp += inventory.ring.max_hp_bonus
	if inventory.amulet != null:
		new_max_hp += inventory.amulet.max_hp_bonus

	var delta := new_max_hp - max_hp
	max_hp = new_max_hp
	if delta > 0:
		hp += delta
	hp = mini(hp, max_hp)
	queue_redraw()
	_notify_hotbar()

func take_damage(amount: int) -> void:
	if godmode:
		print("(godmode) ignored %d damage" % amount)
		return
	var effective: int = mini(amount, hp)
	RunStats.record_damage_taken(effective)
	hp = maxi(0, hp - amount)
	queue_redraw()
	_notify_hotbar()
	if hp <= 0:
		die()

func _notify_hotbar() -> void:
	if hotbar != null:
		hotbar.refresh()

func restore_state(data: Dictionary) -> void:
	var equipped: Dictionary = data.get("equipped", {})
	var weapon_id: Variant = equipped.get("weapon")
	if weapon_id != null:
		inventory.weapon = ItemDB.from_id(weapon_id) as Weapon
	var armor_id: Variant = equipped.get("armor")
	if armor_id != null:
		inventory.armor = ItemDB.from_id(armor_id) as Armor
	var shield_id: Variant = equipped.get("shield")
	if shield_id != null:
		inventory.shield = ItemDB.from_id(shield_id) as Shield
	var ring_id: Variant = equipped.get("ring")
	if ring_id != null:
		inventory.ring = ItemDB.from_id(ring_id) as Ring
	var amulet_id: Variant = equipped.get("amulet")
	if amulet_id != null:
		inventory.amulet = ItemDB.from_id(amulet_id) as Amulet
	for id in data.get("bag", []):
		var item: Item = ItemDB.from_id(id)
		if item != null:
			inventory.bag.append(item)

	bonus_atk = data.get("bonus_atk", 0)
	bonus_def = data.get("bonus_def", 0)
	bonus_max_hp = data.get("bonus_max_hp", 0)
	var saved_gains: Dictionary = data.get("altar_gains_this_act", {})
	altar_gains_this_act = {
		&"atk": int(saved_gains.get("atk", 0)),
		&"def": int(saved_gains.get("def", 0)),
		&"max_hp": int(saved_gains.get("max_hp", 0)),
	}
	timed_buffs = {}
	var saved_buffs: Dictionary = data.get("timed_buffs", {})
	for key_str in saved_buffs.keys():
		var entry: Dictionary = saved_buffs[key_str]
		timed_buffs[StringName(key_str)] = {
			"bonus": int(entry.get("bonus", 0)),
			"turns_left": int(entry.get("turns_left", 0)),
		}
	atk = BASE_ATK + bonus_atk
	if inventory.weapon != null:
		atk += inventory.weapon.atk_bonus
	def = BASE_DEF + bonus_def
	if inventory.armor != null:
		def += inventory.armor.def_bonus
	if inventory.shield != null:
		def += inventory.shield.def_bonus
	if inventory.ring != null:
		atk += inventory.ring.atk_bonus
		def += inventory.ring.def_bonus
	if inventory.amulet != null:
		atk += inventory.amulet.atk_bonus
		def += inventory.amulet.def_bonus

	max_hp = data.get("max_hp", BASE_MAX_HP)
	hp = data.get("hp", max_hp)
	faith = data.get("faith", 0)
	vision_range = data.get("vision_range", BASE_VISION_RANGE)
	vision_debuff_turns = data.get("vision_debuff_turns", 0)

	queue_redraw()
	faith_changed.emit(faith, MAX_FAITH)
	_notify_hotbar()

func _enemy_at(pos: Vector2i) -> Enemy:
	if turn_manager == null:
		return null
	for e in turn_manager.enemies:
		if is_instance_valid(e) and e.grid_position == pos:
			return e
	return null
