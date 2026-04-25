extends Node2D

const MAX_ENEMIES_PER_FLOOR: int = 5
const AltarScene: PackedScene = preload("res://scenes/altar.tscn")
const ITEMS_PER_FLOOR_MIN: int = 2
const ITEMS_PER_FLOOR_MAX: int = 3

# Benedict's narration after each boss fight - fires once when the player
# descends from the boss floor. Quote 5 is the Demon Lord / final-victory
# quote, shown by the game-over screen instead of via the dialogue overlay
# since there's no descent after floor 30.
const BOSS_QUOTES := {
	6: "The demon is a master of concealment. He feeds on our fatigue.",
	12: "Evil's first tactic is to convince us it does not exist. But I feel the cold in the stones.",
	18: "Where faith falters, the structure crumbles. I tread on ground that no longer belongs to God.",
	24: "One cannot fight hell without burning one's own skin. Sacrifice demands the loss of purity.",
}
const DEMON_LORD_FINAL_QUOTE: String = "The final exorcism is wrought not with words, but with blood. I am the prison and the prisoner."

# Whisper that floats above each boss as it dies - flavor line the player
# reads but Benedict supposedly cannot hear. Short and cryptic by design.
const BOSS_WHISPERS := {
	6: "Y'KRETH IT-SUL...",
	12: "I wore that gold, once.",
	18: "The sanctum feeds... always.",
	24: "Below, he waits. Always.",
	30: "You and I... both shadows now.",
}

@onready var dungeon: Dungeon = $World/Dungeon
@onready var items_layer: Node2D = $World/ItemsLayer
@onready var entity_layer: Node2D = $World/EntityLayer
@onready var player: Player = $World/EntityLayer/Player
@onready var turn_manager: TurnManager = $TurnManager
@onready var hotbar: CanvasLayer = $Hotbar
@onready var effects_layer: Node2D = $World/EffectsLayer
@onready var game_over_screen: CanvasLayer = $GameOverScreen
@onready var altars_layer: Node2D = $World/AltarsLayer
@onready var decorations_layer: Node2D = $World/DecorationsLayer
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var dialogue_overlay: CanvasLayer = $DialogueOverlay

var current_floor: int = 1
var _altar_under_player: Altar = null
var _altar_sacrifice_made_this_visit: bool = false
var _restore_altars: Array = []
var rng := RandomNumberGenerator.new()
# Lich ending: true once Benedict falls the Demon Lord without the rosary
# equipped. Flips _descend / _populate_floor into the ascension mode where
# Benedict-as-Lich climbs 5 empty biome floors before the final confrontation.
var _ascending: bool = false
# Scripted end-of-game sequences (rosary cinematic, lich-ending whisper hold)
# live in CinematicsController; main keeps signal wiring and asks the
# controller to play. Rosary-victory state (portal pos / awaiting flag) is
# owned by the controller too.
var cinematics: CinematicsController = null

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

	dialogue_overlay.closed.connect(_on_dialogue_closed)

	cinematics = CinematicsController.new()
	cinematics.player = player
	cinematics.game_over_screen = game_over_screen
	add_child(cinematics)

	dungeon.set_biome(ActConfig.biome_for_floor(current_floor))
	_populate_floor()
	dungeon.update_fov(player.grid_position, player.vision_range)
	_refresh_entity_visibility()
	if ActConfig.is_boss_floor(current_floor):
		AudioManager.play_music("boss", 1.0)
	else:
		AudioManager.play_music("explore", 1.0)
	hotbar.current_floor = current_floor
	hotbar.refresh()
	hotbar.set_sacrifice_mode(false)
	print("Roguelike booted - Sprint 4b OK | Floor %d, %d rooms" % [current_floor, dungeon.rooms.size()])

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	# Dialogue overlay claims input first - it handles X/Space/Enter to dismiss.
	if dialogue_overlay.visible:
		return
	if event.keycode == KEY_M:
		AudioManager.toggle_muted()
		get_viewport().set_input_as_handled()
		return
	# Debug / playtest shortcuts. Remove or gate behind a dev flag before shipping.
	if event.keycode == KEY_F1:
		player.godmode = not player.godmode
		print("[DEBUG] GODMODE: %s" % ("ON" if player.godmode else "OFF"))
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_F2:
		print("[DEBUG] warping from floor %d to %d" % [current_floor, current_floor + 1])
		_descend()
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_F3:
		player.hp = player.max_hp
		player.faith = Player.MAX_FAITH
		player.faith_changed.emit(player.faith, Player.MAX_FAITH)
		hotbar.refresh()
		print("[DEBUG] healed to full + faith maxed")
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
	# Keys 1-3: potion stacks. Keys 4-8: bag (equipables / altar sacrifices).
	if event.keycode >= KEY_1 and event.keycode <= KEY_3:
		var stack_idx: int = event.keycode - KEY_1
		if _altar_under_player != null and _altar_under_player.is_active():
			# Consumables can't be sacrificed - surface the rejection.
			hotbar.flash_slot_invalid(stack_idx)
		else:
			hotbar.use_potion_slot(stack_idx)
		get_viewport().set_input_as_handled()
		return
	if event.keycode >= KEY_4 and event.keycode <= KEY_8:
		var bag_idx: int = event.keycode - KEY_4
		if _altar_under_player != null and _altar_under_player.is_active():
			_try_sacrifice(bag_idx)
		# Outside an altar, bag keys are reserved for sacrifice only -
		# equipables don't have a "use" action.
		get_viewport().set_input_as_handled()
		return

func _populate_floor() -> void:
	if _ascending:
		_populate_ascension_floor()
		return
	if ActConfig.is_boss_floor(current_floor):
		_populate_boss_floor()
		return

	if dungeon.rooms.size() >= 1:
		player.move_to(dungeon.room_center(0), false)

	var enemy_count := mini(current_floor, MAX_ENEMIES_PER_FLOOR)
	for i in range(enemy_count):
		var room_index := i + 1
		if room_index < dungeon.rooms.size():
			_spawn_enemy(dungeon.room_center(room_index))

	_spawn_items()
	if _restore_altars.is_empty():
		_spawn_altar()
	else:
		_restore_altars_from_data(_restore_altars)
		_restore_altars = []  # consume once, subsequent floors spawn fresh

	# Scripted narrative prop: Benedict's own rosary in the Infernal Throne,
	# flanked by two torches against a wall. Discoverable on floor 28.
	if current_floor == 28:
		_spawn_floor_28_shrine()

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
		if _item_at(center) != null or _altar_at(center) != null:
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

# Lich-ending ascension floors (31-35). Empty dungeons in reverse biome
# order - Benedict climbs back through the memory of every act on his way
# to the Bastion where the cycle resets. No enemies, no items, no altars.
# Each floor spawns an "IT CAN'T BE" whisper above the player the instant
# it loads. The final ascension floor (Bastion) gets the Redeemer Paladin.
func _populate_ascension_floor() -> void:
	if dungeon.rooms.size() >= 1:
		player.move_to(dungeon.room_center(0), false)
	_spawn_ascension_whisper("IT CAN'T BE")
	if current_floor == 35:
		_spawn_redeemer_paladin()

func _ascension_biome() -> StringName:
	# Reverse descent order: Benedict climbs from the Throne back to the Bastion.
	match current_floor:
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

func _spawn_ascension_whisper(text: String) -> void:
	if Combat.effects_layer == null:
		return
	var world_pos: Vector2 = Vector2(player.grid_position.x, player.grid_position.y) * Grid.TILE_SIZE + Vector2(Grid.TILE_SIZE * 0.5, 0)
	BossWhisper.spawn(Combat.effects_layer, world_pos, text)

func _spawn_redeemer_paladin() -> void:
	# Final confrontation of the Lich ending: a new paladin descends into
	# the Bastion wearing Benedict's exact appearance. Scripted lethality -
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

func _populate_boss_floor() -> void:
	print("[BOSS] Populating boss arena on floor %d" % current_floor)
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
	print("[BOSS] %s spawned on floor %d (HP %d, ATK %d)" % [boss.name, current_floor, boss.hp, boss.atk])
	# All act bosses emit truly_died(Vector2i) when their final death lands.
	if boss is Lich:
		(boss as Lich).truly_died.connect(_on_boss_truly_died)
	elif boss is DeathKnight:
		(boss as DeathKnight).truly_died.connect(_on_boss_truly_died)
	elif boss is Abomination:
		(boss as Abomination).truly_died.connect(_on_boss_truly_died)
	elif boss is FireGiant:
		(boss as FireGiant).truly_died.connect(_on_boss_truly_died)
	elif boss is DemonLord:
		(boss as DemonLord).truly_died.connect(_on_boss_truly_died)
	AudioManager.play_music("boss", 1.5)

func _pick_enemy_type() -> Enemy:
	var roll := rng.randf()
	# Act 1 - Bastion (1-5, Lich on 6)
	if current_floor <= 2:
		return Slime.new()
	if current_floor <= 4:
		if roll < 0.5:
			return Skeleton.new()
		return Slime.new()
	if current_floor <= 5:
		if roll < 0.3:
			return Slime.new()
		if roll < 0.7:
			return Skeleton.new()
		return Archer.new()
	# Act 2 - Catacombs (7-11, Death Knight on 12)
	if current_floor <= 8:
		# Early Act 2: intro Wraith alongside Skeleton/Archer carryover.
		if roll < 0.3:
			return Skeleton.new()
		if roll < 0.6:
			return Archer.new()
		return Wraith.new()
	if current_floor <= 11:
		# Late Act 2: Wraith + Necrophage lead, Mage filler.
		if roll < 0.35:
			return Wraith.new()
		if roll < 0.65:
			return Necrophage.new()
		if roll < 0.85:
			return Mage.new()
		return Archer.new()
	# Act 3 - Blood Sanctum (13-17, Abomination on 18)
	if current_floor <= 14:
		# Early Act 3: intro Flayed Ghost.
		if roll < 0.4:
			return FlayedGhost.new()
		if roll < 0.7:
			return Wraith.new()
		return Necrophage.new()
	if current_floor <= 17:
		# Late Act 3: Rotting Hulk joins the line.
		if roll < 0.3:
			return RottingHulk.new()
		if roll < 0.55:
			return FlayedGhost.new()
		if roll < 0.8:
			return Necrophage.new()
		return Mage.new()
	# Act 4 - Burning Halls (19-23, Fire Giant on 24)
	if current_floor <= 20:
		# Early Act 4: first demons appear. Rotting Hulk carryover.
		if roll < 0.4:
			return Imp.new()
		if roll < 0.7:
			return RottingHulk.new()
		return FlayedGhost.new()
	if current_floor <= 23:
		# Late Act 4: add Hell Hound + Salamander.
		if roll < 0.25:
			return Imp.new()
		if roll < 0.55:
			return HellHound.new()
		if roll < 0.8:
			return Salamander.new()
		return RottingHulk.new()
	# Act 5 - Infernal Throne (25-29, Demon Lord on 30)
	if current_floor <= 26:
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

func _spawn_enemy(at: Vector2i) -> void:
	var enemy := _pick_enemy_type()
	entity_layer.add_child(enemy)
	enemy.dungeon = dungeon
	enemy.turn_manager = turn_manager
	# Per-enemy scaling curve (EnemyStats.STATS[sprite_key].atk_per_act)
	# replaces the old blanket (floor-1)/2 that forced four balance passes
	# on the Wraith alone.
	enemy.atk += EnemyStats.atk_bonus_for(enemy.sprite_key, current_floor)
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
		entity.item = ItemDB.random_item(rng, current_floor)
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
		print("Entered Act %d - altar cap reset." % new_act)

	for enemy in turn_manager.enemies.duplicate():
		if is_instance_valid(enemy):
			enemy.queue_free()
	turn_manager.enemies.clear()

	for child in items_layer.get_children():
		child.queue_free()

	for child in altars_layer.get_children():
		child.queue_free()

	for child in decorations_layer.get_children():
		child.queue_free()

	if _ascending:
		dungeon.set_biome(_ascension_biome())
	else:
		dungeon.set_biome(ActConfig.biome_for_floor(current_floor))
	if _ascending or not ActConfig.is_boss_floor(current_floor):
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

	hotbar.current_floor = current_floor
	hotbar.refresh()
	print("Descended to Floor %d | %d rooms, %d enemies" % [
		current_floor, dungeon.rooms.size(), turn_manager.enemies.size()
	])

	# Post-boss Benedict narration - fires after the descent to the first
	# floor of the new act. Input is paused until the player presses X.
	if was_boss_floor:
		var prev_boss_floor: int = current_floor - 1
		if BOSS_QUOTES.has(prev_boss_floor):
			player.turn_active = false
			dialogue_overlay.show_dialogue(BOSS_QUOTES[prev_boss_floor])

func _refresh_entity_visibility() -> void:
	for enemy in turn_manager.enemies:
		if is_instance_valid(enemy):
			enemy.visible = dungeon.is_tile_visible(enemy.grid_position)
	for item_entity in items_layer.get_children():
		item_entity.visible = dungeon.is_tile_visible(item_entity.grid_position)
	for altar in altars_layer.get_children():
		# The layer also hosts the rosary-ending victory portal, a plain
		# Sprite2D without grid_position. Skip anything not an Altar.
		if altar is Altar:
			altar.visible = dungeon.is_tile_visible(altar.grid_position)
	for decor in decorations_layer.get_children():
		if decor is Torch:
			decor.visible = dungeon.is_tile_visible(decor.grid_position)

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
	if cinematics.awaiting_rosary_victory and to_pos == cinematics.victory_portal_pos:
		cinematics.on_rosary_victory_step()
		return
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

func _on_dialogue_closed() -> void:
	# Restore normal input once Benedict finishes speaking, unless the run
	# has already ended (game over screen already holds input).
	if not game_over_screen.visible:
		player.turn_active = true

func _on_player_died() -> void:
	SaveManager.clear()
	# Lich ending: whisper + hold are owned by CinematicsController so all
	# scripted end-of-game pacing lives in one place.
	if _ascending:
		RunStats.record_lich_ending()
		print("[LICH ENDING] Benedict falls to the Redeemer. The cycle continues.")
		await cinematics.play_lich_ending_whisper(player.grid_position)
	else:
		print("You died on Floor %d" % current_floor)
	game_over_screen.show_result()

func _on_boss_truly_died(pos: Vector2i) -> void:
	# Act 1 milestone: Lich defeated. Still used as a stats flag.
	if current_floor == 6:
		RunStats.record_lich_defeated()

	# Whisper floats above the corpse - flavor line from the boss at the
	# moment of its true death. Spawned before minion cleanup so the
	# whisper has a parent layer that will survive the frame.
	if BOSS_WHISPERS.has(current_floor) and Combat.effects_layer != null:
		var whisper_world_pos: Vector2 = Vector2(pos.x, pos.y) * Grid.TILE_SIZE + Vector2(Grid.TILE_SIZE * 0.5, 0)
		BossWhisper.spawn(Combat.effects_layer, whisper_world_pos, BOSS_WHISPERS[current_floor])

	# Clean up boss-summoned minions (Lich/DK/Demon Lord all summon Skeletons
	# or Imps). Filter by the concrete classes we know get summoned.
	for enemy in turn_manager.enemies.duplicate():
		if is_instance_valid(enemy) and (enemy is Skeleton or enemy is Imp):
			enemy.queue_free()
	turn_manager.enemies = turn_manager.enemies.filter(func(e): return is_instance_valid(e))

	# Final boss of the game: two endings depending on whether Benedict is
	# currently wearing the rosary recovered from floor 28.
	if ActConfig.is_final_boss_floor(current_floor):
		var has_rosary: bool = player.inventory.shield != null and player.inventory.shield.id == "rosary"
		if has_rosary:
			await cinematics.play_rosary_ending(pos, current_floor)
			return
		# Lich ending - Benedict becomes what he came to destroy. Stairs
		# spawn upward and ascension mode begins.
		_ascending = true
		player.transform_into_lich()
		dungeon.grid.set_cell(pos, Grid.CellType.STAIRS)
		dungeon.stairs_position = pos
		dungeon.set_stairs_ascending(true)
		AudioManager.stop_music(0.5)
		print("[LICH ENDING] The Demon Lord has fallen; Benedict ascends.")
		return

	# Mid-arc boss: spawn stairs so the player can continue to the next act.
	dungeon.grid.set_cell(pos, Grid.CellType.STAIRS)
	dungeon.stairs_position = pos
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
	# Altar stays active while the player is standing on it - multiple
	# sacrifices per visit are allowed. It only consumes when the player
	# leaves the tile (see _on_player_moved). Sacrifice mode stays on.
	AudioManager.play_sfx("sacrifice")
	hotbar.refresh()
	player.turn_done.emit()

func _on_hotbar_consumable_used(stack_idx: int) -> void:
	# stack_idx points into Inventory.potion_stacks. Build a fresh Consumable
	# from the stack's item_id, apply it, and decrement the stack count on
	# success.
	var potion_id: String = player.inventory.peek_potion(stack_idx)
	if potion_id == "":
		return
	var item: Item = ItemDB.from_id(potion_id)
	if not (item is Consumable):
		return
	var consumed: bool = (item as Consumable).use_on(player)
	if consumed:
		player.inventory.consume_potion(stack_idx)
		hotbar.refresh()
		player.turn_done.emit()
		player.turn_done.emit()
