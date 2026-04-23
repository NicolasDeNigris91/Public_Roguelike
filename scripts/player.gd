class_name Player
extends Actor

signal turn_done
signal item_dropped(item: Item, pos: Vector2i)
signal faith_changed(faith: int, max_faith: int)

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
	if not turn_active or is_tweening:
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

func pickup(item: Item) -> void:
	AudioManager.play_sfx("pickup")
	if item is Weapon:
		var old := inventory.equip_weapon(item)
		if old != null:
			item_dropped.emit(old, grid_position)
		_recalculate_stats()
		print("Picked up %s — equipped (ATK %d)" % [item.display_name, atk])
	elif item is Armor:
		var old := inventory.equip_armor(item)
		if old != null:
			item_dropped.emit(old, grid_position)
		_recalculate_stats()
		print("Picked up %s — equipped (DEF %d)" % [item.display_name, def])
	elif item is Ring:
		var old := inventory.equip_ring(item)
		if old != null:
			item_dropped.emit(old, grid_position)
		_recalculate_stats()
		print("Picked up %s — equipped (max HP %d)" % [item.display_name, max_hp])
	else:
		if inventory.add_to_bag(item):
			print("Picked up %s — in bag" % item.display_name)
		else:
			print("Bag full, could not pick up %s" % item.display_name)
	_notify_hotbar()

func die() -> void:
	AudioManager.play_sfx("player_die")
	AudioManager.stop_music(0.5)
	if Combat.world_node != null:
		Shake.apply(Combat.world_node, Combat.SHAKE_DEATH.x, Combat.SHAKE_DEATH.y)
		HitPause.freeze(get_tree(), 0.1)
	died.emit()
	turn_active = false
	_notify_hotbar()

func _recalculate_stats() -> void:
	atk = BASE_ATK
	def = BASE_DEF
	if inventory.weapon != null:
		atk += inventory.weapon.atk_bonus
	if inventory.armor != null:
		def += inventory.armor.def_bonus

	var new_max_hp := BASE_MAX_HP
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
	hp = maxi(0, hp - amount)
	queue_redraw()
	_notify_hotbar()
	if hp <= 0:
		die()

func _notify_hotbar() -> void:
	if hotbar != null:
		hotbar.refresh()

func _enemy_at(pos: Vector2i) -> Enemy:
	if turn_manager == null:
		return null
	for e in turn_manager.enemies:
		if is_instance_valid(e) and e.grid_position == pos:
			return e
	return null
