class_name Shake

const STEPS: int = 5

static func apply(target: Node2D, intensity: float, duration: float) -> void:
	if target == null:
		return

	var original_pos: Vector2 = target.get_meta("shake_origin", target.position)
	target.set_meta("shake_origin", original_pos)

	var previous_tween: Tween = target.get_meta("shake_tween", null)
	if previous_tween != null and previous_tween.is_valid():
		previous_tween.kill()

	var tw := target.create_tween()
	tw.set_ease(Tween.EASE_OUT)
	var step_duration: float = duration / float(STEPS)
	for i in range(STEPS):
		var angle := randf() * TAU
		var offset := Vector2(cos(angle), sin(angle)) * intensity
		tw.tween_property(target, "position", original_pos + offset, step_duration)
	tw.tween_property(target, "position", original_pos, step_duration)

	target.set_meta("shake_tween", tw)
