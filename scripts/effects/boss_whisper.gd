class_name BossWhisper
extends Node2D
# Floating ghostly text that appears over a dying boss - flavor line the
# player can read but Benedict supposedly cannot hear. Fades in, drifts
# upward, fades out, queue-frees itself. No UI panel, no input, no pause.

const FADE_IN_DURATION: float = 0.6
const HOLD_DURATION: float = 3.2
const FADE_OUT_DURATION: float = 1.2
const RISE_DISTANCE: float = 26.0

const WHISPER_COLOR := Color(0.72, 0.88, 0.95, 1.0)  # pale ghostly blue
const OUTLINE_COLOR := Color(0.05, 0.05, 0.1, 0.9)

var _label: Label

static func spawn(parent: Node, world_pos: Vector2, text: String) -> void:
	var w := BossWhisper.new()
	w.position = world_pos
	w._configure(text)
	parent.add_child(w)

func _configure(text: String) -> void:
	_label = Label.new()
	_label.text = text
	_label.add_theme_color_override("font_color", WHISPER_COLOR)
	_label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	_label.add_theme_constant_override("outline_size", 4)
	_label.add_theme_font_size_override("font_size", 13)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Rough centering - Label places its origin at top-left. Pull left by
	# half the text's estimated width so the whisper floats centered above
	# the boss rather than originating at its top-left corner.
	var estimated_width: float = float(text.length()) * 7.0
	_label.position = Vector2(-estimated_width * 0.5, -20.0)
	add_child(_label)
	modulate = Color(1.0, 1.0, 1.0, 0.0)

func _ready() -> void:
	var start_pos := position
	var end_pos := start_pos + Vector2(0, -RISE_DISTANCE)

	var tw := create_tween()
	# Rise slowly across the whole life of the whisper.
	tw.tween_property(self, "position", end_pos, FADE_IN_DURATION + HOLD_DURATION + FADE_OUT_DURATION)

	var fade_tw := create_tween()
	fade_tw.tween_property(self, "modulate:a", 1.0, FADE_IN_DURATION)
	fade_tw.tween_interval(HOLD_DURATION)
	fade_tw.tween_property(self, "modulate:a", 0.0, FADE_OUT_DURATION)
	fade_tw.tween_callback(queue_free)
