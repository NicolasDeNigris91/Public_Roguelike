extends Node2D

# Floor / enemy / item / altar / shrine spawn logic lives in FloorPopulator.
# main asks the populator to populate, then wires whatever it hands back.

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
var floor_populator: FloorPopulator = null

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

	floor_populator = FloorPopulator.new()
	floor_populator.dungeon = dungeon
	floor_populator.player = player
	floor_populator.turn_manager = turn_manager
	floor_populator.entity_layer = entity_layer
	floor_populator.items_layer = items_layer
	floor_populator.altars_layer = altars_layer
	floor_populator.decorations_layer = decorations_layer
	floor_populator.rng = rng
	floor_populator.boss_spawned.connect(_on_boss_spawned)
	add_child(floor_populator)

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
	floor_populator.populate(current_floor, _ascending, _restore_altars)
	# Consume the restore data once; subsequent floors spawn fresh altars.
	if not _restore_altars.is_empty():
		_restore_altars = []

# Wired via floor_populator.boss_spawned in _ready. All act bosses emit
# truly_died(Vector2i); we connect each type by hand because GDScript does
# not let us declare the signal generically on the base Enemy class.
func _on_boss_spawned(boss: Enemy) -> void:
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
		dungeon.set_biome(floor_populator.ascension_biome(current_floor))
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
	floor_populator.refresh_entity_visibility()

func _try_pickup(pos: Vector2i) -> void:
	var entity := floor_populator.item_at(pos)
	if entity == null:
		return
	var taken: bool = player.pickup(entity.item)
	if taken:
		entity.queue_free()

func _on_player_moved(to_pos: Vector2i) -> void:
	var new_altar := floor_populator.altar_at(to_pos)
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
	floor_populator.spawn_dropped_item(item, pos)
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
