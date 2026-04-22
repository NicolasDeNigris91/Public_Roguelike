class_name HitPause

# Max-wins semantics: nested freezes use the longest duration.
# Each call registers an end time; only the timer that finds itself at or after
# the latest registered end time actually restores time_scale.
static var _latest_end_msec: int = 0

static func freeze(tree: SceneTree, duration: float) -> void:
	Engine.time_scale = 0.0
	var my_end_msec: int = Time.get_ticks_msec() + int(duration * 1000.0)
	if my_end_msec > _latest_end_msec:
		_latest_end_msec = my_end_msec
	# Args: wait_time, process_always=true, process_in_physics=false, ignore_time_scale=true
	# ignore_time_scale is required because we just set time_scale to 0.
	var timer := tree.create_timer(duration, true, false, true)
	await timer.timeout
	if Time.get_ticks_msec() >= _latest_end_msec:
		Engine.time_scale = 1.0
