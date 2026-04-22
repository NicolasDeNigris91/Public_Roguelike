class_name HitPause

static func freeze(tree: SceneTree, duration: float) -> void:
	Engine.time_scale = 0.0
	var timer := tree.create_timer(duration, true)  # ignore_time_scale = true
	await timer.timeout
	Engine.time_scale = 1.0
