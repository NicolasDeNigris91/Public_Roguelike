extends Node2D

const MAX_ENEMIES_PER_FLOOR: int = 5
const ITEMS_PER_FLOOR_MIN: int = 2
const ITEMS_PER_FLOOR_MAX: int = 3

@onready var dungeon: Dungeon = $World/Dungeon
@onready var items_layer: Node2D = $World/ItemsLayer
@onready var entity_layer: Node2D = $World/EntityLayer
@onready var player: Player = $World/EntityLayer/Player
@onready var turn_manager: TurnManager = $TurnManager
@onready var inventory_ui: InventoryUI = $InventoryUI

var current_floor: int = 1
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

	player.dungeon = dungeon
	player.turn_manager = turn_manager
	player.died.connect(_on_player_died)
	player.moved.connect(_on_player_moved)
	turn_manager.dungeon = dungeon
	turn_manager.register_player(player)

	inventory_ui.player = player
	inventory_ui.item_used.connect(_on_inventory_item_used)
	inventory_ui.closed.connect(_on_inventory_closed)

	_populate_floor()
	dungeon.update_fov(player.grid_position, player.vision_range)
	_refresh_entity_visibility()
	print("Roguelike booted — Sprint 4b OK | Floor %d, %d rooms" % [current_floor, dungeon.rooms.size()])

func _unhandled_input(event: InputEvent) -> void:
	if inventory_ui.visible:
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_I:
		_open_inventory()
		get_viewport().set_input_as_handled()

func _open_inventory() -> void:
	player.turn_active = false
	inventory_ui.open()

func _populate_floor() -> void:
	if current_floor == 6:
		_populate_boss_floor()
		return

	if dungeon.rooms.size() >= 1:
		player.move_to(dungeon.room_center(0))

	var enemy_count := mini(current_floor, MAX_ENEMIES_PER_FLOOR)
	var atk_bonus := (current_floor - 1) / 2
	for i in range(enemy_count):
		var room_index := i + 1
		if room_index < dungeon.rooms.size():
			_spawn_enemy(dungeon.room_center(room_index), atk_bonus)

	_spawn_items()

func _populate_boss_floor() -> void:
	var spawns: Dictionary = dungeon.regenerate_as_boss_arena()
	player.move_to(spawns["player_spawn"])

	var lich := Lich.new()
	entity_layer.add_child(lich)
	lich.dungeon = dungeon
	lich.turn_manager = turn_manager
	lich.move_to(spawns["lich_spawn"])
	turn_manager.register_enemy(lich)
	lich.truly_died.connect(_on_lich_truly_died)

func _pick_enemy_type() -> Enemy:
	var roll := rng.randf()
	if current_floor <= 2:
		return Slime.new()
	if current_floor <= 4:
		if roll < 0.5:
			return Skeleton.new()
		return Slime.new()
	if current_floor <= 6:
		if roll < 0.3:
			return Slime.new()
		if roll < 0.7:
			return Skeleton.new()
		return Archer.new()
	if current_floor <= 8:
		if roll < 0.2:
			return Slime.new()
		if roll < 0.5:
			return Skeleton.new()
		if roll < 0.8:
			return Archer.new()
		return Mage.new()
	if roll < 0.2:
		return Slime.new()
	if roll < 0.4:
		return Skeleton.new()
	if roll < 0.7:
		return Archer.new()
	return Mage.new()

func _spawn_enemy(at: Vector2i, atk_bonus: int) -> void:
	var enemy := _pick_enemy_type()
	entity_layer.add_child(enemy)
	enemy.dungeon = dungeon
	enemy.turn_manager = turn_manager
	enemy.atk += atk_bonus
	enemy.move_to(at)
	turn_manager.register_enemy(enemy)

func _spawn_items() -> void:
	var item_count := rng.randi_range(ITEMS_PER_FLOOR_MIN, ITEMS_PER_FLOOR_MAX)
	var attempts := 0
	var spawned := 0
	while spawned < item_count and attempts < item_count * 5:
		attempts += 1
		var room := dungeon.rooms[rng.randi_range(0, dungeon.rooms.size() - 1)]
		var pos := Vector2i(
			rng.randi_range(room.position.x, room.position.x + room.size.x - 1),
			rng.randi_range(room.position.y, room.position.y + room.size.y - 1)
		)
		if pos == player.grid_position: continue
		if pos == dungeon.stairs_position: continue
		if _item_at(pos) != null: continue

		var entity := ItemEntity.new()
		entity.item = ItemDB.random_item(rng)
		items_layer.add_child(entity)
		entity.grid_position = pos
		spawned += 1

func _descend() -> void:
	current_floor += 1

	for enemy in turn_manager.enemies.duplicate():
		if is_instance_valid(enemy):
			enemy.queue_free()
	turn_manager.enemies.clear()

	for child in items_layer.get_children():
		child.queue_free()

	if current_floor != 6:
		dungeon.regenerate()
	# Floor 6 regenerates inside _populate_boss_floor; skip BSP pass.
	_populate_floor()
	dungeon.update_fov(player.grid_position, player.vision_range)
	_refresh_entity_visibility()
	print("Descended to Floor %d | %d rooms, %d enemies" % [
		current_floor, dungeon.rooms.size(), turn_manager.enemies.size()
	])

func _refresh_entity_visibility() -> void:
	for enemy in turn_manager.enemies:
		if is_instance_valid(enemy):
			enemy.visible = dungeon.is_tile_visible(enemy.grid_position)
	for item_entity in items_layer.get_children():
		item_entity.visible = dungeon.is_tile_visible(item_entity.grid_position)

func _item_at(pos: Vector2i) -> ItemEntity:
	for child in items_layer.get_children():
		if child is ItemEntity and child.grid_position == pos:
			return child
	return null

func _try_pickup(pos: Vector2i) -> void:
	var entity := _item_at(pos)
	if entity != null:
		player.pickup(entity.item)
		entity.queue_free()

func _on_player_moved(to_pos: Vector2i) -> void:
	if dungeon.grid.get_cell(to_pos) == Grid.CellType.STAIRS:
		_descend()
		return
	_try_pickup(to_pos)
	dungeon.update_fov(to_pos, player.vision_range)
	_refresh_entity_visibility()

func _on_player_died() -> void:
	print("You died on Floor %d" % current_floor)

func _on_lich_truly_died(lich_pos: Vector2i) -> void:
	dungeon.grid.set_cell(lich_pos, Grid.CellType.STAIRS)
	dungeon.stairs_position = lich_pos
	for enemy in turn_manager.enemies.duplicate():
		if is_instance_valid(enemy) and enemy is Skeleton:
			enemy.queue_free()
	turn_manager.enemies = turn_manager.enemies.filter(func(e): return is_instance_valid(e))
	dungeon.queue_redraw()
	print("O Lich foi derrotado. Uma escada aparece.")

func _on_inventory_closed() -> void:
	player.turn_active = true

func _on_inventory_item_used(slot_index: int) -> void:
	if slot_index >= player.inventory.bag.size():
		return
	var item := player.inventory.bag[slot_index]
	if item is Consumable:
		var consumed: bool = item.use_on(player)
		if consumed:
			player.inventory.bag.remove_at(slot_index)
			inventory_ui.close()
			player.turn_done.emit()
		else:
			inventory_ui.refresh()
	else:
		print("%s cannot be used — equip automatic only" % item.display_name)
