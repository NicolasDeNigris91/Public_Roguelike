class_name DamageNumber
extends Node2D

const RISE_DISTANCE: float = 20.0
const TOTAL_DURATION: float = 0.8
const FADE_WINDOW: float = 0.4  # last 40% of duration
const SCALE_POP_DURATION: float = 0.1

var label: Label

static func spawn(parent: Node, world_pos: Vector2, text: String, color: Color, scale_mul: float = 1.0) -> void:
	var dn := DamageNumber.new()
	dn.position = world_pos
	dn._configure(text, color, scale_mul)
	parent.add_child(dn)

func _configure(text: String, color: Color, scale_mul: float) -> void:
	label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	var font_size: int = 18 if scale_mul > 1.0 else 14
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
	if scale_mul != 1.0:
		scale = Vector2(scale_mul, scale_mul)

func _ready() -> void:
	var start_pos := position
	var end_pos := start_pos + Vector2(0, -RISE_DISTANCE)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "position", end_pos, TOTAL_DURATION)
	if scale != Vector2.ONE:
		tw.tween_property(self, "scale", Vector2.ONE, SCALE_POP_DURATION)
	# Fade-out tween in the last 40%
	tw.tween_property(self, "modulate:a", 0.0, TOTAL_DURATION * FADE_WINDOW).set_delay(TOTAL_DURATION * (1.0 - FADE_WINDOW))
	tw.chain().tween_callback(queue_free)
