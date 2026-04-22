class_name HitPause

# Counter tracks how many freezes are currently pending.
# time_scale is restored only when the count hits zero — i.e. the LAST
# freeze's timer fires. Since each timer ticks in real time (ignore_time_scale),
# whichever freeze has the longest duration is the last to complete,
# giving us max-wins semantics for nested freezes automatically.
static var _pending: int = 0

static func freeze(tree: SceneTree, duration: float) -> void:
	_pending += 1
	Engine.time_scale = 0.0
	# Args: wait_time, process_always=true, process_in_physics=false, ignore_time_scale=true
	# ignore_time_scale is the 4th arg — required because we set time_scale to 0.
	var timer := tree.create_timer(duration, true, false, true)
	await timer.timeout
	_pending -= 1
	if _pending <= 0:
		_pending = 0
		Engine.time_scale = 1.0
