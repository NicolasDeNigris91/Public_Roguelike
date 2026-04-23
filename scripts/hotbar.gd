extends CanvasLayer
# Permanent bottom hotbar. No class_name to avoid autoload-style collisions
# and because the scene-root identity is sufficient for external refs.

signal consumable_used(slot_idx: int)

const MAX_FLOOR: int = 6

const HP_BAR_SIZE := Vector2(120, 16)

const HP_COLOR_LOW := Color(0.85, 0.15, 0.15, 1)
const HP_COLOR_MID := Color(0.85, 0.75, 0.15, 1)
const HP_COLOR_HIGH := Color(0.20, 0.75, 0.25, 1)

var player: Player
var current_floor: int = 1

var _hp_bar: ProgressBar
var _hp_label: Label
var _floor_label: Label

@onready var status_container: HBoxContainer = $PanelContainer/MarginContainer/HBoxContainer/StatusContainer
@onready var equipped_container: HBoxContainer = $PanelContainer/MarginContainer/HBoxContainer/EquippedContainer
@onready var bag_container: HBoxContainer = $PanelContainer/MarginContainer/HBoxContainer/BagContainer

func _ready() -> void:
	layer = 5
	_build_status()

func _build_status() -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	status_container.add_child(vbox)

	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 8)
	vbox.add_child(hp_row)

	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = HP_BAR_SIZE
	_hp_bar.show_percentage = false
	_hp_bar.min_value = 0
	_hp_bar.max_value = 20
	_hp_bar.value = 20
	hp_row.add_child(_hp_bar)

	_hp_label = Label.new()
	_hp_label.text = "0/0"
	_hp_label.add_theme_font_size_override("font_size", 14)
	hp_row.add_child(_hp_label)

	_floor_label = Label.new()
	_floor_label.text = "Andar 1/%d" % MAX_FLOOR
	_floor_label.add_theme_font_size_override("font_size", 14)
	_floor_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	vbox.add_child(_floor_label)

func _refresh_status() -> void:
	if player == null:
		return
	_hp_bar.max_value = player.max_hp
	_hp_bar.value = player.hp
	_hp_label.text = "%d/%d" % [player.hp, player.max_hp]
	_floor_label.text = "Andar %d/%d" % [current_floor, MAX_FLOOR]

	# HP color: red→yellow→green via two-stage lerp
	var ratio: float = 0.0
	if player.max_hp > 0:
		ratio = float(player.hp) / float(player.max_hp)
	var bar_color: Color
	if ratio < 0.5:
		bar_color = HP_COLOR_LOW.lerp(HP_COLOR_MID, ratio * 2.0)
	else:
		bar_color = HP_COLOR_MID.lerp(HP_COLOR_HIGH, (ratio - 0.5) * 2.0)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = bar_color
	fill_style.corner_radius_top_left = 2
	fill_style.corner_radius_top_right = 2
	fill_style.corner_radius_bottom_right = 2
	fill_style.corner_radius_bottom_left = 2
	_hp_bar.add_theme_stylebox_override("fill", fill_style)

func refresh() -> void:
	_refresh_status()
	# _refresh_equipped and _refresh_bag added in Tasks 4-5.

func use_consumable_slot(idx: int) -> void:
	if player == null:
		return
	if idx < 0 or idx >= player.inventory.bag.size():
		return
	var item: Item = player.inventory.bag[idx]
	if not (item is Consumable):
		return
	consumable_used.emit(idx)
