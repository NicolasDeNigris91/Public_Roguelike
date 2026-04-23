class_name Actor
extends Node2D

signal died
signal moved(to_pos: Vector2i)

const MOVE_TWEEN_DURATION: float = 0.1
const BOBBING_AMPLITUDE: float = 2.0
const BOBBING_FREQUENCY: float = 2.0  # Hz
const FLASH_DURATION: float = 0.04  # each leg (to and from white)
const NUDGE_DURATION: float = 0.08  # each leg
const NUDGE_FRACTION: float = 0.5
const WALK_HOP_HEIGHT: float = 3.0  # px, up-arc during step
const WALK_SWAY_X: float = 1.5  # px, alternating lateral sway (left foot / right foot)

var grid_position: Vector2i
var hp: int = 10
var max_hp: int = 10
var atk: int = 3
var def: int = 1
var sprite_node: Sprite2D
var is_tweening: bool = false
# Ranged attack VFX. Subclasses assign one (or neither for a pure-melee enemy).
# If `ranged_projectile_frames` has 8 directional frames, Combat.attack uses
# them on non-adjacent hits. Otherwise it falls back to `ranged_projectile_texture`.
var ranged_projectile_frames: Array = []
var ranged_projectile_texture: Texture2D = null
var _bobbing_phase: float = 0.0
var _bobbing_time: float = 0.0
var _step_parity: int = 0

func _ready() -> void:
	sprite_node = Sprite2D.new()
	sprite_node.centered = false
	add_child(sprite_node)
	_bobbing_phase = randf() * TAU
	_sync_position_instant()

func _process(delta: float) -> void:
	if is_tweening:
		return  # walk tween drives sprite_node.offset during movement
	_bobbing_time += delta
	sprite_node.offset.y = sin(_bobbing_time * BOBBING_FREQUENCY * TAU + _bobbing_phase) * BOBBING_AMPLITUDE

func move_to(new_grid_pos: Vector2i, animate: bool = true) -> void:
	var dx := new_grid_pos.x - grid_position.x
	grid_position = new_grid_pos
	if animate:
		_face_horizontal(dx)
		_tween_to(grid_position)
	else:
		_sync_position_instant()
		moved.emit(new_grid_pos)

func _face_horizontal(dx: int) -> void:
	if dx > 0:
		sprite_node.flip_h = true
	elif dx < 0:
		sprite_node.flip_h = false

func take_damage(amount: int) -> void:
	hp = maxi(0, hp - amount)
	queue_redraw()
	if hp <= 0:
		die()

func die() -> void:
	died.emit()
	queue_free()

func take_turn() -> void:
	pass

func flash_white() -> void:
	var tw := create_tween()
	tw.tween_property(sprite_node, "modulate", Color(2, 2, 2), FLASH_DURATION)
	tw.tween_property(sprite_node, "modulate", Color.WHITE, FLASH_DURATION)

func nudge_toward(target_grid_pos: Vector2i) -> Signal:
	_face_horizontal(target_grid_pos.x - grid_position.x)
	var home := position
	var target_world := Vector2(target_grid_pos.x, target_grid_pos.y) * Grid.TILE_SIZE
	var offset := (target_world - home) * NUDGE_FRACTION
	is_tweening = true
	var tw := create_tween()
	tw.tween_property(self, "position", home + offset, NUDGE_DURATION)
	tw.tween_property(self, "position", home, NUDGE_DURATION)
	tw.tween_callback(func() -> void:
		is_tweening = false
		sprite_node.offset = Vector2.ZERO
	)
	return tw.finished

func _tween_to(target_grid_pos: Vector2i) -> void:
	var target_world := Vector2(target_grid_pos.x, target_grid_pos.y) * Grid.TILE_SIZE
	is_tweening = true
	_step_parity = 1 - _step_parity
	var half := MOVE_TWEEN_DURATION * 0.5
	var sway := WALK_SWAY_X if _step_parity == 0 else -WALK_SWAY_X

	var move_tw := create_tween()
	move_tw.set_ease(Tween.EASE_OUT)
	move_tw.set_trans(Tween.TRANS_CUBIC)
	move_tw.tween_property(self, "position", target_world, MOVE_TWEEN_DURATION)
	move_tw.tween_callback(func() -> void:
		is_tweening = false
		sprite_node.offset = Vector2.ZERO
		moved.emit(target_grid_pos)
	)

	var hop_tw := create_tween()
	hop_tw.set_trans(Tween.TRANS_SINE)
	hop_tw.tween_property(sprite_node, "offset:y", -WALK_HOP_HEIGHT, half)
	hop_tw.tween_property(sprite_node, "offset:y", 0.0, half)

	var sway_tw := create_tween()
	sway_tw.set_trans(Tween.TRANS_SINE)
	sway_tw.tween_property(sprite_node, "offset:x", sway, half)
	sway_tw.tween_property(sprite_node, "offset:x", 0.0, half)

func _sync_position_instant() -> void:
	position = Vector2(grid_position.x, grid_position.y) * Grid.TILE_SIZE
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var font_size := 10
	var text := str(hp)
	var text_pos := Vector2(2, -2)
	draw_string_outline(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 2, Color.BLACK)
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
