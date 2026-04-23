# Run: <godot> --headless -s scripts/tests/test_altar_smoke.gd
extends SceneTree

func _init() -> void:
	assert(Altar != null, "Altar class_name should exist")
	var altar := Altar.new()
	assert(altar.consumed == false, "default consumed should be false")
	assert(altar.is_active() == true, "default should be active")
	altar.consumed = true
	assert(altar.is_active() == false, "consumed altar is not active")
	var emitted := [false]
	altar.consumed_changed.connect(func(v): emitted[0] = v)
	altar.consumed = false
	altar.consume()  # should flip + emit
	assert(altar.consumed == true)
	assert(emitted[0] == true, "consume() should emit consumed_changed(true)")
	altar.consume()  # second call is a no-op
	print("PASS test_altar_smoke")
	quit()
