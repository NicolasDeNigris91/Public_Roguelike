class_name Player
extends Actor

signal turn_done
signal item_dropped(item: Item, pos: Vector2i)
signal faith_changed(faith: int, max_faith: int)
signal stat_increased(stat: StringName, delta: int)

func _play_sfx(sfx: String) -> void:
	var am := Engine.get_singleton("AudioManager")
	if am != null:
		am.play_sfx(sfx)

func _stop_music(fade: float) -> void:
	var am := Engine.get_singleton("AudioManager")
	if am != null:
		am.stop_music(fade)

const BASE_ATK: int = 5
const BASE_DEF: int = 3
const BASE_MAX_HP: int = 20
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
		_play_sfx("step")
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
	turn_done.emit()

func apply_vision_debuff(new_range: int, turns: int) -> void:
	vision_range = new_range
	vision_debuff_turns = turns
	if dungeon != null:
		dungeon.update_fov(grid_position, vision_range)
	print("Player vision reduced to %d for %d turns" % [new_range, turns])

func pickup(item: Item) -> bool:
	_play_sfx("pickup")
	var result := pickup_item(item)
	match result:
		Inventory.PickupResult.EQUIPPED, Inventory.PickupResult.EQUIPPED_AND_BAGGED_OLD:
			if item is Weapon:
				RunStats.record_weapon_equipped(item as Weapon)
			_recalculate_stats()
			print("Picked up %s — equipped" % item.display_name)
		Inventory.PickupResult.BAGGED:
			print("Picked up %s — in bag" % item.display_name)
		Inventory.PickupResult.REJECTED_BAG_FULL:
			print("Bag full — left %s on the floor" % item.display_name)
	_notify_hotbar()
	return result != Inventory.PickupResult.REJECTED_BAG_FULL

func pickup_item(item: Item) -> Inventory.PickupResult:
	return inventory.try_pickup(item)

func die() -> void:
	_play_sfx("player_die")
	_stop_music(0.5)
	if Combat.world_node != null:
		Shake.apply(Combat.world_node, Combat.SHAKE_DEATH.x, Combat.SHAKE_DEATH.y)
		HitPause.freeze(get_tree(), 0.1)
	died.emit()
	turn_active = false
	_notify_hotbar()

func _recalculate_stats() -> void:
	atk = BASE_ATK + bonus_atk
	def = BASE_DEF + bonus_def
	if inventory.weapon != null:
		atk += inventory.weapon.atk_bonus
	if inventory.armor != null:
		def += inventory.armor.def_bonus

	var new_max_hp := BASE_MAX_HP + bonus_max_hp
	if inventory.ring != null:
		new_max_hp += inventory.ring.max_hp_bonus

	var delta := new_max_hp - max_hp
	max_hp = new_max_hp
	if delta > 0:
		hp += delta
	hp = mini(hp, max_hp)
	queue_redraw()
	_notify_hotbar()

func take_damage(amount: int) -> void:
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
	var ring_id: Variant = equipped.get("ring")
	if ring_id != null:
		inventory.ring = ItemDB.from_id(ring_id) as Ring
	for id in data.get("bag", []):
		var item: Item = ItemDB.from_id(id)
		if item != null:
			inventory.bag.append(item)

	bonus_atk = data.get("bonus_atk", 0)
	bonus_def = data.get("bonus_def", 0)
	bonus_max_hp = data.get("bonus_max_hp", 0)
	atk = BASE_ATK + bonus_atk
	if inventory.weapon != null:
		atk += inventory.weapon.atk_bonus
	def = BASE_DEF + bonus_def
	if inventory.armor != null:
		def += inventory.armor.def_bonus

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
