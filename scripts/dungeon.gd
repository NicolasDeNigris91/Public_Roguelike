class_name Dungeon
extends Node2D

const WIDTH: int = 30
const HEIGHT: int = 20
const MEMORY_DIM: float = 0.35

const TILESET_PATH := "res://assets/tileset_dungeon.tres"

# Source IDs as configured in assets/tileset_dungeon.tres (alphabetical order used by the editor).
const SOURCE_FLOOR: int = 0
const SOURCE_STAIRS: int = 9
const SOURCE_WALL: int = 10

const ATLAS_COORDS := Vector2i(0, 0)

var grid: Grid
var rooms: Array[Rect2i] = []
var stairs_position: Vector2i = Vector2i(-1, -1)
var visible_tiles: Dictionary = {}
var explored_tiles: Dictionary = {}
var rng := RandomNumberGenerator.new()

var visible_layer: TileMapLayer
var memory_layer: TileMapLayer

var _bastion_tileset: TileSet
var _catacombs_tileset: TileSet
var _blood_sanctum_tileset: TileSet

func _ready() -> void:
	rng.randomize()

	_bastion_tileset = load(TILESET_PATH)
	# Each biome reuses the same source IDs but swaps the floor + wall textures.
	# Duplicate (deep) so editing the clone does not mutate the loaded resource.
	_catacombs_tileset = _build_biome_tileset("floor_catacombs", "wall_catacombs")
	_blood_sanctum_tileset = _build_biome_tileset("floor_blood_sanctum", "wall_blood_sanctum")

	memory_layer = TileMapLayer.new()
	memory_layer.tile_set = _bastion_tileset
	memory_layer.self_modulate = Color(MEMORY_DIM, MEMORY_DIM, MEMORY_DIM, 1.0)
	add_child(memory_layer)

	visible_layer = TileMapLayer.new()
	visible_layer.tile_set = _bastion_tileset
	add_child(visible_layer)

	_generate_floor()

# Called by main.gd whenever current_floor changes. Picks the biome's tileset.
func set_biome(biome: StringName) -> void:
	var target: TileSet = _bastion_tileset
	match biome:
		ActConfig.BIOME_CATACOMBS:
			target = _catacombs_tileset
		ActConfig.BIOME_BLOOD_SANCTUM:
			target = _blood_sanctum_tileset
	visible_layer.tile_set = target
	memory_layer.tile_set = target

# Builds a biome variant of the base tileset with floor+wall textures swapped.
func _build_biome_tileset(floor_key: String, wall_key: String) -> TileSet:
	var ts: TileSet = _bastion_tileset.duplicate(true)
	var floor_src := ts.get_source(SOURCE_FLOOR) as TileSetAtlasSource
	if floor_src != null:
		floor_src.texture = SpriteDB.tile(floor_key)
	var wall_src := ts.get_source(SOURCE_WALL) as TileSetAtlasSource
	if wall_src != null:
		wall_src.texture = SpriteDB.tile(wall_key)
	return ts

func regenerate() -> void:
	visible_tiles.clear()
	explored_tiles.clear()
	visible_layer.clear()
	memory_layer.clear()
	_generate_floor()

func regenerate_as_boss_arena() -> Dictionary:
	visible_tiles.clear()
	explored_tiles.clear()
	visible_layer.clear()
	memory_layer.clear()
	grid = Grid.new(WIDTH, HEIGHT)
	rooms.clear()
	stairs_position = Vector2i(-1, -1)
	var spawns: Dictionary = BossArenaGenerator.generate(grid)
	return spawns

func update_fov(origin: Vector2i, radius: int = FOV.RADIUS) -> void:
	visible_tiles = FOV.compute(grid, origin, radius)
	for pos in visible_tiles:
		explored_tiles[pos] = true
	_repaint()

func is_tile_visible(pos: Vector2i) -> bool:
	return visible_tiles.has(pos)

func room_center(index: int) -> Vector2i:
	var r := rooms[index]
	return Vector2i(r.position.x + r.size.x / 2, r.position.y + r.size.y / 2)

func grid_to_world(pos: Vector2i) -> Vector2:
	return Vector2(pos.x, pos.y) * Grid.TILE_SIZE

func redraw_cell(pos: Vector2i) -> void:
	var source_id := _source_for_cell(pos)
	if source_id < 0:
		visible_layer.erase_cell(pos)
		memory_layer.erase_cell(pos)
		return
	if explored_tiles.has(pos):
		memory_layer.set_cell(pos, source_id, ATLAS_COORDS)
	if visible_tiles.has(pos):
		visible_layer.set_cell(pos, source_id, ATLAS_COORDS)

func _generate_floor() -> void:
	grid = Grid.new(WIDTH, HEIGHT)
	rooms = DungeonGenerator.generate(grid, rng)
	if rooms.size() > 1:
		stairs_position = room_center(rooms.size() - 1)
		grid.set_cell(stairs_position, Grid.CellType.STAIRS)
	else:
		stairs_position = Vector2i(-1, -1)

func _repaint() -> void:
	visible_layer.clear()
	for pos in explored_tiles:
		var source_id := _source_for_cell(pos)
		if source_id < 0:
			continue
		memory_layer.set_cell(pos, source_id, ATLAS_COORDS)
	for pos in visible_tiles:
		var source_id := _source_for_cell(pos)
		if source_id < 0:
			continue
		visible_layer.set_cell(pos, source_id, ATLAS_COORDS)

func _source_for_cell(pos: Vector2i) -> int:
	match grid.get_cell(pos):
		Grid.CellType.FLOOR:
			return SOURCE_FLOOR
		Grid.CellType.STAIRS:
			return SOURCE_STAIRS
		Grid.CellType.WALL:
			return SOURCE_WALL
		_:
			return -1
