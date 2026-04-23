extends Node2D

const MAX_ENEMIES_PER_FLOOR: int = 5
const AltarScene: PackedScene = preload("res://scenes/altar.tscn")
const ITEMS_PER_FLOOR_MIN: int = 2
const ITEMS_PER_FLOOR_MAX: int = 3

@onready var dungeon: Dungeon = $World/Dungeon
@onready var items_layer: Node2D = $World/ItemsLayer
@onready var entity_layer: Node2D = $World/EntityLayer
@onready var player: Player = $World/EntityLayer/Player
@onready var turn_manager: TurnManager = $TurnManager
@onready var hotbar: CanvasLayer = $Hotbar
@onready var effects_layer: Node2D = $World/EffectsLayer
@onready var game_over_screen: CanvasLayer = $GameOverScreen
@onready var altars_layer: Node2D = $World/AltarsLayer
@onready var pause_menu: CanvasLayer = $PauseMenu

var current_floor: int = 1
var _altar_under_player: Altar = null
var _altar_sacrifice_made_this_visit: bool = false
var _restore_altars: Array = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

	var save_state: Dictionary = {}
	if SaveManager.pending_load:
		SaveManager.pending_load = false
		save_state = SaveManager.load_state()

	if save_state.is_empty():
		RunStats.reset()
	else:
		current_floor = save_state.get("floor", 1)
		RunStats.from_dict(save_state.get("run_stats", {}))
		player.restore_state(save_state.get("player", {}))
		_restore_altars = save_state.get("altars", [])

	player.dungeon = dungeon
	player.turn_manager = turn_manager
	player.died.connect(_on_player_died)
	player.moved.connect(_on_player_moved)
	player.item_dropped.connect(_on_player_item_dropped)
	turn_manager.dungeon = dungeon
	turn_manager.register_player(player)

	# Combat needs references to the effects layer (for damage numbers) and the World
	# node (for screen shake). These are static fields populated once at startup.
	Combat.effects_layer = effects_layer
	Combat.world_node = $World

	hotbar.player = player
	hotbar.consumable_used.connect(_on_hotbar_consumable_used)
	player.hotbar = hotbar
	player.stat_increased.connect(hotbar.on_stat_increased)

	dungeon.set_biome(ActConfig.biome_for_floor(current_floor))
	_populate_floor()
	dungeon.update_fov(player.grid_position, player.vision_range)
	_refresh_entity_visibility()
	if ActConfig.is_boss_floor(current_floor):
		AudioManager.play_music("boss", 1.0)
	else:
		AudioManager.play_music("explore", 1.0)
	hotbar.refresh()
	hotbar.set_sacrifice_mode(false)
	print("Roguelike booted — Sprint 4b OK | Floor %d, %d rooms" % [current_floor, dungeon.rooms.size()])

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_M:
		AudioManager.toggle_muted()
		get_viewport().set_input_as_handled()
		return
	if game_over_screen.visible:
		if event.keycode == KEY_R:
			get_viewport().set_input_as_handled()
			get_tree().reload_current_scene()
		elif event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			AudioManager.stop_music(0.3)
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		return
	if event.keycode == KEY_ESCAPE:
		if pause_menu.visible:
			pause_menu.close()
		else:
			pause_menu.open()
		get_viewport().set_input_as_handled()
		return
	if pause_menu.visible:
		return
	if not player.turn_active:
		return
	if event.keycode >= KEY_1 and event.keycode <= KEY_8:
		var slot: int = event.keycode - KEY_1
		if _altar_under_player != null and _altar_under_player.is_active():
			_try_sacrifice(slot)
		else:
			hotbar.use_consumable_slot(slot)
		get_viewport().set_input_as_handled()

func _populate_floor() -> void:
	if ActConfig.is_boss_floor(current_floor):
		_populate_boss_floor()
		return

	if dungeon.rooms.size() >= 1:
		player.move_to(dungeon.room_center(0), false)

	var enemy_count := mini(current_floor, MAX_ENEMIES_PER_FLOOR)
	var atk_bonus := (current_floor - 1) / 2
	for i in range(enemy_count):
		var room_index := i + 1
		if room_index < dungeon.rooms.size():
			_spawn_enemy(dungeon.room_center(room_index), atk_bonus)

	_spawn_items()
	if _restore_altars.is_empty():
		_spawn_altar()
	else:
		_restore_altars_from_data(_restore_altars)
		_restore_altars = []  # consume once, subsequent floors spawn fresh

func _populate_boss_floor() -> void:
	var spawns: Dictionary = dungeon.regenerate_as_boss_arena()
	player.move_to(spawns["player_spawn"], false)

	var boss: Enemy = ActConfig.spawn_boss(current_floor)
	if boss == null:
		push_warning("No boss configured for floor %d" % current_floor)
		return
	entity_layer.add_child(boss)
	boss.dungeon = dungeon
	boss.turn_manager = turn_manager
	boss.move_to(spawns["lich_spawn"], false)  # key reused for any boss spawn
	turn_manager.register_enemy(boss)
	# Lich, DeathKnight, and Abomination all emit truly_died(Vector2i).
	if boss is Lich:
		(boss as Lich).truly_died.connect(_on_boss_truly_died)
	elif boss is DeathKnight:
		(boss as DeathKnight).truly_died.connect(_on_boss_truly_died)
	elif boss is Abomination:
		(boss as Abomination).truly_died.connect(_on_boss_truly_died)
	AudioManager.play_music("boss", 1.5)

func _pick_enemy_type() -> Enemy:
	var roll := rng.randf()
	# Act 1 — Bastion
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
	# Act 2 — Catacombs (floors 7-17, boss on 18)
	if current_floor <= 9:
		if roll < 0.3:
			return Skeleton.new()
		if roll < 0.7:
			return Archer.new()
		return Wraith.new()
	if current_floor <= 13:
		if roll < 0.2:
			return Skeleton.new()
		if roll < 0.5:
			return Wraith.new()
		if roll < 0.8:
			return Necrophage.new()
		return Mage.new()
	if current_floor <= 17:
		# Late Act 2 (14-17)
		if roll < 0.3:
			return Wraith.new()
		if roll < 0.6:
			return Necrophage.new()
		if roll < 0.85:
			return Mage.new()
		return Archer.new()
	# Act 3 — Blood Sanctum (19-29, boss on 30)
	if current_floor <= 21:
		# Early Act 3: introduce Flayed Ghost alongside Wraith/Necrophage carryover.
		if roll < 0.3:
			return Wraith.new()
		if roll < 0.7:
			return FlayedGhost.new()
		return Necrophage.new()
	if current_floor <= 25:
		# Mid Act 3: FlayedGhost + RottingHulk main line, Necrophage filler.
		if roll < 0.25:
			return FlayedGhost.new()
		if roll < 0.6:
			return RottingHulk.new()
		if roll < 0.85:
			return Necrophage.new()
		return Mage.new()
	# Late Act 3 (26-29)
	if roll < 0.3:
		return RottingHulk.new()
	if roll < 0.6:
		return FlayedGhost.new()
	if roll < 0.85:
		return Mage.new()
	return Wraith.new()

func _spawn_enemy(at: Vector2i, atk_bonus: int) -> void:
	var enemy := _pick_enemy_type()
	entity_layer.add_child(enemy)
	enemy.dungeon = dungeon
	enemy.turn_manager = turn_manager
	enemy.atk += atk_bonus
	enemy.move_to(at, false)
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
		if _altar_at(pos) != null: continue

		var entity := ItemEntity.new()
		entity.item = ItemDB.random_item(rng)
		items_layer.add_child(entity)
		entity.grid_position = pos
		spawned += 1

func _descend() -> void:
	var was_boss_floor: bool = ActConfig.is_boss_floor(current_floor)
	var prev_act: int = ActConfig.act_for_floor(current_floor)
	current_floor += 1
	RunStats.record_floor(current_floor)

	# Crossing into a new act resets the altar stat cap, giving the player
	# a fresh +4/+4/+8 budget per act so altar engagement stays rewarding
	# without inflating stats into the oblivion tier.
	var new_act: int = ActConfig.act_for_floor(current_floor)
	if new_act != prev_act:
		player.reset_altar_cap()
		print("Entered Act %d — altar cap reset." % new_act)

	for enemy in turn_manager.enemies.duplicate():
		if is_instance_valid(enemy):
			enemy.queue_free()
	turn_manager.enemies.clear()

	for child in items_layer.get_children():
		child.queue_free()

	for child in altars_layer.get_children():
		child.queue_free()

	dungeon.set_biome(ActConfig.biome_for_floor(current_floor))
	if not ActConfig.is_boss_floor(current_floor):
		dungeon.regenerate()
	# Boss floors regenerate inside _populate_boss_floor; skip BSP pass.
	_populate_floor()
	dungeon.update_fov(player.grid_position, player.vision_range)
	_refresh_entity_visibility()

	# Save AFTER the new floor is populated so the serialized altar state
	# matches the floor the player is actually on. Saving before _populate_floor
	# would persist the previous floor's altars with the new floor number,
	# which on reload would place altars at coordinates that may be walls
	# on the regenerated dungeon.
	SaveManager.save(current_floor, player, altars_layer.get_children())

	if was_boss_floor:
		AudioManager.play_music("explore", 1.5)

	hotbar.refresh()
	print("Descended to Floor %d | %d rooms, %d enemies" % [
		current_floor, dungeon.rooms.size(), turn_manager.enemies.size()
	])

func _refresh_entity_visibility() -> void:
	for enemy in turn_manager.enemies:
		if is_instance_valid(enemy):
			enemy.visible = dungeon.is_tile_visible(enemy.grid_position)
	for item_entity in items_layer.get_children():
		item_entity.visible = dungeon.is_tile_visible(item_entity.grid_position)
	for altar in altars_layer.get_children():
		altar.visible = dungeon.is_tile_visible(altar.grid_position)

func _item_at(pos: Vector2i) -> ItemEntity:
	for child in items_layer.get_children():
		if child is ItemEntity and child.grid_position == pos:
			return child
	return null

func _altar_at(pos: Vector2i) -> Altar:
	for child in altars_layer.get_children():
		if child is Altar and child.grid_position == pos:
			return child
	return null

func _spawn_altar() -> void:
	if current_floor == 6:
		return  # Lich arena protected
	var attempts := 0
	while attempts < 30:
		attempts += 1
		var room := dungeon.rooms[rng.randi_range(0, dungeon.rooms.size() - 1)]
		var pos := Vector2i(
			rng.randi_range(room.position.x, room.position.x + room.size.x - 1),
			rng.randi_range(room.position.y, room.position.y + room.size.y - 1)
		)
		if pos == player.grid_position: continue
		if pos == dungeon.stairs_position: continue
		if _item_at(pos) != null: continue
		if _altar_at(pos) != null: continue
		var altar := AltarScene.instantiate() as Altar
		altar.grid_position = pos
		altars_layer.add_child(altar)
		return
	push_warning("Could not place altar on floor %d after 30 attempts" % current_floor)

func _restore_altars_from_data(data: Array) -> void:
	for entry in data:
		var pos := Vector2i(int(entry.get("x", 0)), int(entry.get("y", 0)))
		if not dungeon.grid.in_bounds(pos) or not dungeon.grid.is_walkable(pos):
			push_warning("Skipping restored altar at invalid pos %s" % pos)
			continue
		var altar := AltarScene.instantiate() as Altar
		altar.grid_position = pos
		altar.consumed = bool(entry.get("consumed", false))
		altars_layer.add_child(altar)

func _try_pickup(pos: Vector2i) -> void:
	var entity := _item_at(pos)
	if entity == null:
		return
	var taken: bool = player.pickup(entity.item)
	if taken:
		entity.queue_free()

func _on_player_moved(to_pos: Vector2i) -> void:
	var new_altar := _altar_at(to_pos)
	# Leaving an altar consumes it, but only if we actually sacrificed at
	# least once during this visit. Walking across an altar without using
	# it leaves it active for future visits.
	if _altar_under_player != null and _altar_under_player != new_altar:
		if _altar_sacrifice_made_this_visit and _altar_under_player.is_active():
			_altar_under_player.consume()
		_altar_sacrifice_made_this_visit = false
	_altar_under_player = new_altar
	hotbar.set_sacrifice_mode(new_altar != null and new_altar.is_active())
	if dungeon.grid.get_cell(to_pos) == Grid.CellType.STAIRS:
		AudioManager.play_sfx("descend")
		_descend()
		return
	_try_pickup(to_pos)
	dungeon.update_fov(to_pos, player.vision_range)
	_refresh_entity_visibility()

func _on_player_item_dropped(item: Item, pos: Vector2i) -> void:
	var entity := ItemEntity.new()
	entity.item = item
	items_layer.add_child(entity)
	entity.grid_position = pos
	_refresh_entity_visibility()

func _on_player_died() -> void:
	SaveManager.clear()
	print("You died on Floor %d" % current_floor)
	game_over_screen.show_result()

func _on_boss_truly_died(pos: Vector2i) -> void:
	# Act 1 milestone: Lich defeated. Still used as a stats flag.
	if current_floor == 6:
		RunStats.record_lich_defeated()
	# The final boss of the game (currently floor 18, future floor 48) clears
	# the save so the next run starts fresh. Mid-game bosses keep the save so
	# the player can quit-continue on the post-boss floor.
	if ActConfig.is_final_boss_floor(current_floor):
		SaveManager.clear()
	# Spawn stairs where the boss died so the player can descend to the next act.
	dungeon.grid.set_cell(pos, Grid.CellType.STAIRS)
	dungeon.stairs_position = pos
	# Clean up boss-summoned minions (both Lich and Death Knight summon Skeletons).
	for enemy in turn_manager.enemies.duplicate():
		if is_instance_valid(enemy) and enemy is Skeleton:
			enemy.queue_free()
	turn_manager.enemies = turn_manager.enemies.filter(func(e): return is_instance_valid(e))
	dungeon.redraw_cell(pos)
	print("Boss derrotado no andar %d. Uma escada aparece." % current_floor)

func _try_sacrifice(slot: int) -> void:
	if _altar_under_player == null or not _altar_under_player.is_active():
		return
	if slot < 0 or slot >= player.inventory.bag.size():
		hotbar.flash_slot_invalid(slot)
		return
	var item: Item = player.inventory.bag[slot]
	if item is Consumable:
		hotbar.flash_slot_invalid(slot)
		return
	var applied: bool = player.apply_altar_buff(item)
	if not applied:
		hotbar.flash_slot_invalid(slot)
		return
	player.inventory.bag.remove_at(slot)
	_altar_sacrifice_made_this_visit = true
	# Altar stays active while the player is standing on it — multiple
	# sacrifices per visit are allowed. It only consumes when the player
	# leaves the tile (see _on_player_moved). Sacrifice mode stays on.
	AudioManager.play_sfx("sacrifice")
	hotbar.refresh()
	player.turn_done.emit()

func _on_hotbar_consumable_used(slot_idx: int) -> void:
	if slot_idx >= player.inventory.bag.size():
		return
	var item: Item = player.inventory.bag[slot_idx]
	if not (item is Consumable):
		return
	var consumed: bool = item.use_on(player)
	if consumed:
		player.inventory.bag.remove_at(slot_idx)
		hotbar.refresh()
		player.turn_done.emit()
