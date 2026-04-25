class_name FloorPopulator
extends Node
# Owns every "put things on the floor" decision: enemies, items, altars,
# torches, the floor-28 rosary shrine, and the special boss / ascension
# layouts. main.gd stays the orchestrator — it asks the populator to
# populate and wires signals on whatever the populator hands back.

signal boss_spawned(boss: Enemy)

const MAX_ENEMIES_PER_FLOOR: int = 5
const ITEMS_PER_FLOOR_MIN: int = 2
const ITEMS_PER_FLOOR_MAX: int = 3
const AltarScene: PackedScene = preload("res://scenes/altar.tscn")

# Wired from main._ready(). None of these are held with strong ownership —
# the populator does not control lifecycle, it only reads and appends.
var dungeon: Dungeon
var player: Player
var turn_manager: TurnManager
var entity_layer: Node2D
var items_layer: Node2D
var altars_layer: Node2D
var decorations_layer: Node2D
var rng: RandomNumberGenerator

# Entry point. Branches by game state and returns the boss node if one
# was spawned so main can hook its truly_died signal.
func populate(floor_num: int, ascending: bool, restore_altars: Array) -> Enemy:
	if ascending:
		_populate_ascension_floor(floor_num)
		return null
	if ActConfig.is_boss_floor(floor_num):
		return _populate_boss_floor(floor_num)
	_populate_normal_floor(floor_num, restore_altars)
	return null

# Helpers main needs for player interaction (pickup, altar step detection,
# drop-on-floor signal from the rosary swap).

func item_at(pos: Vector2i) -> ItemEntity:
	for child in items_layer.get_children():
		if child is ItemEntity and child.grid_position == pos:
			return child
	return null

func altar_at(pos: Vector2i) -> Altar:
	for child in altars_layer.get_children():
		if child is Altar and child.grid_position == pos:
			return child
	return null

func spawn_dropped_item(item: Item, pos: Vector2i) -> void:
	var entity := ItemEntity.new()
	entity.item = item
	items_layer.add_child(entity)
	entity.grid_position = pos

# Called after every move + every descent. Hides actors/items/altars/torches
# outside the player's FOV. The victory portal Sprite2D in altars_layer is
# filtered out because it has no grid_position.
func refresh_entity_visibility() -> void:
	for enemy in turn_manager.enemies:
		if is_instance_valid(enemy):
			enemy.visible = dungeon.is_tile_visible(enemy.grid_position)
	for item_entity in items_layer.get_children():
		item_entity.visible = dungeon.is_tile_visible(item_entity.grid_position)
	for altar in altars_layer.get_children():
		if altar is Altar:
			altar.visible = dungeon.is_tile_visible(altar.grid_position)
	for decor in decorations_layer.get_children():
		if decor is Torch:
			decor.visible = dungeon.is_tile_visible(decor.grid_position)

func ascension_biome(floor_num: int) -> StringName:
	# Reverse descent order: Benedict climbs from the Throne back to the Bastion.
	match floor_num:
		31:
			return ActConfig.BIOME_INFERNAL_THRONE
		32:
			return ActConfig.BIOME_BURNING_HALLS
		33:
			return ActConfig.BIOME_BLOOD_SANCTUM
		34:
			return ActConfig.BIOME_CATACOMBS
		_:
			return ActConfig.BIOME_BASTION

# ----- normal floor -----

func _populate_normal_floor(floor_num: int, restore_altars: Array) -> void:
	if dungeon.rooms.size() >= 1:
		player.move_to(dungeon.room_center(0), false)

	var enemy_count := mini(floor_num, MAX_ENEMIES_PER_FLOOR)
	for i in range(enemy_count):
		var room_index := i + 1
		if room_index < dungeon.rooms.size():
			_spawn_enemy(dungeon.room_center(room_index), floor_num)

	_spawn_items(floor_num)
	if restore_altars.is_empty():
		_spawn_altar(floor_num)
	else:
		_restore_altars_from_data(restore_altars)

	# Scripted narrative prop: Benedict's own rosary in the Infernal Throne,
	# flanked by two torches against a wall. Discoverable on floor 28.
	if floor_num == 28:
		_spawn_floor_28_shrine()

# ----- boss floor -----

func _populate_boss_floor(floor_num: int) -> Enemy:
	print("[BOSS] Populating boss arena on floor %d" % floor_num)
	var spawns: Dictionary = dungeon.regenerate_as_boss_arena()
	player.move_to(spawns["player_spawn"], false)

	var boss: Enemy = ActConfig.spawn_boss(floor_num)
	if boss == null:
		push_warning("No boss configured for floor %d" % floor_num)
		return null
	entity_layer.add_child(boss)
	boss.dungeon = dungeon
	boss.turn_manager = turn_manager
	boss.move_to(spawns["lich_spawn"], false)  # key reused for any boss spawn
	turn_manager.register_enemy(boss)
	print("[BOSS] %s spawned on floor %d (HP %d, ATK %d)" % [boss.name, floor_num, boss.hp, boss.atk])
	AudioManager.play_music("boss", 1.5)
	boss_spawned.emit(boss)
	return boss

# ----- ascension floor (Lich ending) -----

# Lich-ending ascension floors (31-35). Empty dungeons in reverse biome
# order; each spawns an "IT CAN'T BE" whisper instantly, and floor 35
# also spawns the Redeemer Paladin.
func _populate_ascension_floor(floor_num: int) -> void:
	if dungeon.rooms.size() >= 1:
		player.move_to(dungeon.room_center(0), false)
	_spawn_ascension_whisper("IT CAN'T BE")
	if floor_num == 35:
		_spawn_redeemer_paladin()

func _spawn_ascension_whisper(text: String) -> void:
	if Combat.effects_layer == null:
		return
	var world_pos: Vector2 = Vector2(player.grid_position.x, player.grid_position.y) * Grid.TILE_SIZE + Vector2(Grid.TILE_SIZE * 0.5, 0)
	BossWhisper.spawn(Combat.effects_layer, world_pos, text)

func _spawn_redeemer_paladin() -> void:
	# Final confrontation of the Lich ending: a new paladin descends into
	# the Bastion wearing Benedict's exact appearance. Scripted lethality —
	# the fight is not meant to be won.
	if dungeon.rooms.size() < 1:
		return
	var paladin_pos: Vector2i = dungeon.room_center(dungeon.rooms.size() - 1)
	# Don't stack the paladin on top of the Lich-Benedict.
	if paladin_pos == player.grid_position and dungeon.rooms.size() > 1:
		paladin_pos = dungeon.room_center(dungeon.rooms.size() - 2)
	var paladin := RedeemerPaladin.new()
	entity_layer.add_child(paladin)
	paladin.dungeon = dungeon
	paladin.turn_manager = turn_manager
	paladin.move_to(paladin_pos, false)
	turn_manager.register_enemy(paladin)
	print("[LICH ENDING] The Redeemer has arrived.")

# ----- spawn primitives -----

func _spawn_enemy(at: Vector2i, floor_num: int) -> void:
	var enemy := _pick_enemy_type(floor_num)
	entity_layer.add_child(enemy)
	enemy.dungeon = dungeon
	enemy.turn_manager = turn_manager
	# Per-enemy scaling curve (EnemyStats.STATS[sprite_key].atk_per_act)
	# replaces the old blanket (floor-1)/2 that forced four balance passes
	# on the Wraith alone.
	enemy.atk += EnemyStats.atk_bonus_for(enemy.sprite_key, floor_num)
	enemy.move_to(at, false)
	turn_manager.register_enemy(enemy)

func _spawn_items(floor_num: int) -> void:
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
		if item_at(pos) != null: continue
		if altar_at(pos) != null: continue

		var entity := ItemEntity.new()
		entity.item = ItemDB.random_item(rng, floor_num)
		items_layer.add_child(entity)
		entity.grid_position = pos
		spawned += 1

func _spawn_altar(floor_num: int) -> void:
	if floor_num == 6:
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
		if item_at(pos) != null: continue
		if altar_at(pos) != null: continue
		var altar := AltarScene.instantiate() as Altar
		altar.grid_position = pos
		altars_layer.add_child(altar)
		return
	push_warning("Could not place altar on floor %d after 30 attempts" % floor_num)

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

# ----- shrine + torches (floor 28) -----

func _spawn_floor_28_shrine() -> void:
	# Find a room with enough space for a centered shrine: 3 adjacent
	# walkable tiles with a wall immediately north, and none occupied.
	var attempts := 0
	while attempts < 40:
		attempts += 1
		var room: Rect2i = dungeon.rooms[rng.randi_range(0, dungeon.rooms.size() - 1)]
		# Pick a point along the room's top row - y = room.position.y.
		# The tile immediately north (y - 1) is a wall in BSP rooms.
		var x: int = rng.randi_range(room.position.x + 1, room.position.x + room.size.x - 2)
		var y: int = room.position.y
		var center := Vector2i(x, y)
		var left := center + Vector2i(-1, 0)
		var right := center + Vector2i(1, 0)
		# All three must be walkable and free of existing props.
		if not (dungeon.grid.is_walkable(center) and dungeon.grid.is_walkable(left) and dungeon.grid.is_walkable(right)):
			continue
		if center == player.grid_position or left == player.grid_position or right == player.grid_position:
			continue
		if center == dungeon.stairs_position or left == dungeon.stairs_position or right == dungeon.stairs_position:
			continue
		if item_at(center) != null or altar_at(center) != null:
			continue
		# Place rosary on center tile via normal item pipeline (player can pick up).
		var rosary_entity := ItemEntity.new()
		rosary_entity.item = ItemDB.rosary()
		items_layer.add_child(rosary_entity)
		rosary_entity.grid_position = center
		# Torches flanking - decorative, no interaction.
		_spawn_torch(left)
		_spawn_torch(right)
		print("[SHRINE] Rosary + torches placed at %s on floor 28" % center)
		return
	push_warning("Could not place floor-28 shrine after 40 attempts")

func _spawn_torch(pos: Vector2i) -> void:
	var t := Torch.new()
	t.grid_position = pos
	decorations_layer.add_child(t)

# ----- enemy spawn pool (per floor / act) -----

func _pick_enemy_type(floor_num: int) -> Enemy:
	var roll := rng.randf()
	# Act 1 - Bastion (1-5, Lich on 6)
	if floor_num <= 2:
		return Slime.new()
	if floor_num <= 4:
		if roll < 0.5:
			return Skeleton.new()
		return Slime.new()
	if floor_num <= 5:
		if roll < 0.3:
			return Slime.new()
		if roll < 0.7:
			return Skeleton.new()
		return Archer.new()
	# Act 2 - Catacombs (7-11, Death Knight on 12)
	if floor_num <= 8:
		# Early Act 2: intro Wraith alongside Skeleton/Archer carryover.
		if roll < 0.3:
			return Skeleton.new()
		if roll < 0.6:
			return Archer.new()
		return Wraith.new()
	if floor_num <= 11:
		# Late Act 2: Wraith + Necrophage lead, Mage filler.
		if roll < 0.35:
			return Wraith.new()
		if roll < 0.65:
			return Necrophage.new()
		if roll < 0.85:
			return Mage.new()
		return Archer.new()
	# Act 3 - Blood Sanctum (13-17, Abomination on 18)
	if floor_num <= 14:
		# Early Act 3: intro Flayed Ghost.
		if roll < 0.4:
			return FlayedGhost.new()
		if roll < 0.7:
			return Wraith.new()
		return Necrophage.new()
	if floor_num <= 17:
		# Late Act 3: Rotting Hulk joins the line.
		if roll < 0.3:
			return RottingHulk.new()
		if roll < 0.55:
			return FlayedGhost.new()
		if roll < 0.8:
			return Necrophage.new()
		return Mage.new()
	# Act 4 - Burning Halls (19-23, Fire Giant on 24)
	if floor_num <= 20:
		# Early Act 4: first demons appear. Rotting Hulk carryover.
		if roll < 0.4:
			return Imp.new()
		if roll < 0.7:
			return RottingHulk.new()
		return FlayedGhost.new()
	if floor_num <= 23:
		# Late Act 4: add Hell Hound + Salamander.
		if roll < 0.25:
			return Imp.new()
		if roll < 0.55:
			return HellHound.new()
		if roll < 0.8:
			return Salamander.new()
		return RottingHulk.new()
	# Act 5 - Infernal Throne (25-29, Demon Lord on 30)
	if floor_num <= 26:
		# Early Act 5: Hellwing intro.
		if roll < 0.4:
			return Hellwing.new()
		if roll < 0.7:
			return HellHound.new()
		return Salamander.new()
	# Late Act 5 (27-29) - Executioner elites.
	if roll < 0.35:
		return Executioner.new()
	if roll < 0.65:
		return Hellwing.new()
	if roll < 0.85:
		return Salamander.new()
	return HellHound.new()
