# scripts/tests/test_smoke.gd
# Run: godot --headless -s scripts/tests/test_smoke.gd
extends SceneTree

func _init() -> void:
	assert(1 + 1 == 2, "math is broken")
	print("PASS test_smoke")
	quit()
