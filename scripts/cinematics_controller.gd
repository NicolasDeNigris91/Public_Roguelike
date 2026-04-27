class_name CinematicsController
extends Node
# Owns the scripted end-of-game sequences so main.gd stays an orchestrator.
# Two sequences live here:
#
#   - Lich ending (rosary not equipped): triggered indirectly when the
#     Redeemer kills Benedict during the ascent; main.gd asks us to play
#     the final "But yet it is..." whisper and hold for 4.5s before the
#     game-over screen.
#   - Rosary ending (rosary equipped): full cinematic - Benedict briefly
#     becomes the Lich, a halo descends, he reverts, a portal opens on
#     the Demon Lord's corpse. Player regains control and walks through
#     the portal to trigger the victory screen.

# Rosary-victory state. main.gd checks these on every player move to detect
# the "step into the portal = win" trigger. Stored here instead of on main
# because the lifetime matches the cinematic, not the scene.
var awaiting_rosary_victory: bool = false
var victory_portal_pos: Vector2i = Vector2i(-1, -1)

var _victory_portal_sprite: Sprite2D = null

# Wired from main._ready(). Held as soft references - no signal connections
# owned here, so main stays the source of truth for player/UI lifecycle.
var player: Player
var game_over_screen: CanvasLayer

# Thin helper so callers do not recompute the tile-centre offset.
func spawn_boss_whisper(world_pos_center: Vector2, text: String) -> void:
	if Combat.effects_layer == null:
		return
	BossWhisper.spawn(Combat.effects_layer, world_pos_center, text)

# Lich ending tail - called from main._on_player_died when Benedict falls
# during the ascent. Awaits the whisper's full play so the game-over screen
# does not cut it off.
func play_lich_ending_whisper(player_grid_pos: Vector2i) -> void:
	if Combat.effects_layer != null:
		var world_pos: Vector2 = Vector2(player_grid_pos.x, player_grid_pos.y) * Grid.TILE_SIZE + Vector2(Grid.TILE_SIZE * 0.5, 0)
		BossWhisper.spawn(Combat.effects_layer, world_pos, "But yet it is...")
	await get_tree().create_timer(4.5).timeout

# Rosary ending - awaited by main on final-boss death when the player wears
# the rosary. By the end, awaiting_rosary_victory is true and the portal is
# on-screen at demon_pos.
func play_rosary_ending(demon_pos: Vector2i, current_floor: int) -> void:
	# in_cinematic is orthogonal to turn_active: TurnManager restores
	# turn_active to true at the end of the enemy phase that fires during
	# the boss-kill frame, so turn_active alone would unlock input mid-scene.
	player.in_cinematic = true
	player.turn_active = false
	AudioManager.stop_music(0.8)

	# Phase 1 - the same horror as the bad ending, held long enough that the
	# whisper fully plays (BossWhisper: 0.6 fade-in + 3.2 hold + 1.2 fade-out).
	player.transform_into_lich()
	var whisper_world: Vector2 = Vector2(player.grid_position.x, player.grid_position.y) * Grid.TILE_SIZE + Vector2(Grid.TILE_SIZE * 0.5, 0)
	if Combat.effects_layer != null:
		BossWhisper.spawn(Combat.effects_layer, whisper_world, "It can't be...")
	await get_tree().create_timer(5.2).timeout

	# Phase 2 - halo descends, the rosary's grace rewrites the curse.
	if Combat.effects_layer != null:
		var halo_world: Vector2 = Vector2(player.grid_position.x, player.grid_position.y) * Grid.TILE_SIZE + Vector2(Grid.TILE_SIZE * 0.5, Grid.TILE_SIZE * 0.5)
		_spawn_divine_halo(halo_world)
		var whisper2_world: Vector2 = Vector2(player.grid_position.x, player.grid_position.y) * Grid.TILE_SIZE + Vector2(Grid.TILE_SIZE * 0.5, 0)
		BossWhisper.spawn(Combat.effects_layer, whisper2_world, "...and yet, by His grace, it shall not be.")
	AudioManager.play_sfx("smite")
	await get_tree().create_timer(5.2).timeout

	# Phase 3 - mortal form returns, portal opens on the corpse. Player walks
	# out under their own power; stepping onto the portal finalises the run.
	player.revert_from_lich()
	_spawn_victory_portal(demon_pos)
	awaiting_rosary_victory = true
	victory_portal_pos = demon_pos
	player.in_cinematic = false
	player.turn_active = true
	RunStats.record_run_victory()
	print("VICTORY - grace pulled Benedict back on floor %d." % current_floor)

# Fires when main sees the player step onto victory_portal_pos.
func on_rosary_victory_step() -> void:
	awaiting_rosary_victory = false
	player.turn_active = false
	SaveManager.clear()
	if _victory_portal_sprite != null and is_instance_valid(_victory_portal_sprite):
		_victory_portal_sprite.queue_free()
	game_over_screen.show_result()
	print("Benedict steps into the portal - run complete.")

func _spawn_divine_halo(world_pos: Vector2) -> void:
	if Combat.effects_layer == null:
		return
	var halo := Sprite2D.new()
	halo.texture = SpriteDB.effect("divine_halo")
	halo.centered = true
	halo.position = world_pos
	halo.scale = Vector2(0.5, 0.5)
	halo.modulate = Color(1.0, 0.95, 0.6, 0.0)
	Combat.effects_layer.add_child(halo)
	var tw := halo.create_tween()
	tw.set_parallel(true)
	tw.tween_property(halo, "modulate:a", 1.0, 0.6)
	tw.tween_property(halo, "scale", Vector2(2.2, 2.2), 2.5)
	tw.chain().tween_property(halo, "modulate:a", 0.0, 1.0)
	tw.chain().tween_callback(halo.queue_free)

func _spawn_victory_portal(grid_pos: Vector2i) -> void:
	_victory_portal_sprite = Sprite2D.new()
	_victory_portal_sprite.texture = SpriteDB.tile("victory_portal")
	_victory_portal_sprite.centered = true
	_victory_portal_sprite.position = Vector2(grid_pos.x, grid_pos.y) * Grid.TILE_SIZE + Vector2(Grid.TILE_SIZE * 0.5, Grid.TILE_SIZE * 0.5)
	# Parked on the effects layer (transient VFX home), not altars_layer -
	# nothing else iterates effects_layer expecting grid_position, so the
	# plain Sprite2D can't crash any visibility/altar loop.
	if Combat.effects_layer != null:
		Combat.effects_layer.add_child(_victory_portal_sprite)
	else:
		add_child(_victory_portal_sprite)
	# Gentle pulse so the portal reads as alive, not decorative.
	var tw := _victory_portal_sprite.create_tween().set_loops()
	tw.tween_property(_victory_portal_sprite, "modulate", Color(1.3, 1.25, 0.85, 1.0), 1.2)
	tw.tween_property(_victory_portal_sprite, "modulate", Color(0.85, 0.9, 1.15, 1.0), 1.2)
