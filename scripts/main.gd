extends Node2D

const MAX_ENEMIES_PER_FLOOR: int = 5
const ITEMS_PER_FLOOR_MIN: int = 2
const ITEMS_PER_FLOOR_MAX: int = 3

@onready var dungeon: Dungeon = $World/Dungeon
@onready var items_layer: Node2D = $World/ItemsLayer
@onready var entity_layer: Node2D = $World/EntityLayer
@onready var player: Player = $World/EntityLayer/Player
@onready var turn_manager: TurnManager = $TurnManager

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

	_populate_floor()
	dungeon.update_fov(player.grid_position)
	_refresh_entity_visibility()
	print("Roguelike booted — Sprint 4a OK | Floor %d, %d rooms" % [current_floor, dungeon.rooms.size()])

func _populate_floor() -> void:
	if dungeon.rooms.size() >= 1:
		player.move_to(dungeon.room_center(0))

	var enemy_count := mini(current_floor, MAX_ENEMIES_PER_FLOOR)
	var atk_bonus := (current_floor - 1) / 2
	for i in range(enemy_count):
		var room_index := i + 1
		if room_index < dungeon.rooms.size():
			_spawn_slime(dungeon.room_center(room_index), atk_bonus)

	_spawn_items()

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

func _spawn_slime(at: Vector2i, atk_bonus: int = 0) -> void:
	var slime := Slime.new()
	entity_layer.add_child(slime)
	slime.dungeon = dungeon
	slime.turn_manager = turn_manager
	slime.atk += atk_bonus
	slime.move_to(at)
	turn_manager.register_enemy(slime)

func _descend() -> void:
	current_floor += 1

	for enemy in turn_manager.enemies.duplicate():
		if is_instance_valid(enemy):
			enemy.queue_free()
	turn_manager.enemies.clear()

	for child in items_layer.get_children():
		child.queue_free()

	dungeon.regenerate()
	_populate_floor()
	dungeon.update_fov(player.grid_position)
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
	dungeon.update_fov(to_pos)
	_refresh_entity_visibility()

func _on_player_died() -> void:
	print("You died on Floor %d" % current_floor)
