class_name Projectile

# Short-lived Sprite2D that tweens from start to end world-pos and frees itself.
# Used for ranged attack visualization (archer arrow, mage bolt, paladin smite).

const DEFAULT_DURATION: float = 0.18

static func spawn(
	layer: Node2D,
	from_world: Vector2,
	to_world: Vector2,
	texture: Texture2D,
	duration: float = DEFAULT_DURATION
) -> Signal:
	var s := Sprite2D.new()
	s.texture = texture
	s.centered = true
	s.position = from_world
	layer.add_child(s)
	var tw := s.create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_LINEAR)
	tw.tween_property(s, "position", to_world, duration)
	tw.tween_callback(func() -> void:
		s.queue_free()
	)
	return tw.finished

# Directional spawn: picks the pre-rotated frame matching the angle from→to.
# Expects exactly 8 frames arranged clockwise starting from East (0°).
static func spawn_directional(
	layer: Node2D,
	from_world: Vector2,
	to_world: Vector2,
	frames_8: Array,
	duration: float = DEFAULT_DURATION
) -> Signal:
	return spawn(layer, from_world, to_world, _pick_octant_frame(from_world, to_world, frames_8), duration)

# Brief impact flash at a world position (e.g. searing burst on smite hit).
static func spawn_burst(
	layer: Node2D,
	at_world: Vector2,
	texture: Texture2D,
	duration: float = 0.15
) -> void:
	var s := Sprite2D.new()
	s.texture = texture
	s.centered = true
	s.position = at_world
	layer.add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "modulate:a", 0.0, duration)
	tw.tween_callback(func() -> void:
		s.queue_free()
	)

static func _pick_octant_frame(from_world: Vector2, to_world: Vector2, frames_8: Array) -> Texture2D:
	var dir: Vector2 = to_world - from_world
	var angle: float = atan2(dir.y, dir.x)
	if angle < 0.0:
		angle += TAU
	var idx: int = int(round(angle / (PI / 4.0))) % 8
	return frames_8[idx]
