extends CanvasLayer
# Permanent bottom hotbar. No class_name to avoid autoload-style collisions
# and because the scene-root identity is sufficient for external refs.

signal consumable_used(slot_idx: int)

const MAX_FLOOR: int = 6

const HP_BAR_SIZE := Vector2(120, 16)

const HP_COLOR_LOW := Color(0.85, 0.15, 0.15, 1)
const HP_COLOR_MID := Color(0.85, 0.75, 0.15, 1)
const HP_COLOR_HIGH := Color(0.20, 0.75, 0.25, 1)

const EQUIPPED_SLOT_SIZE := Vector2(48, 64)
const BAG_SLOT_SIZE := Vector2(44, 58)
const BAG_SLOT_COUNT: int = 8
const SLOT_ICON_SIZE: int = 32
const SLOT_BG_FILLED := Color(0.14, 0.14, 0.17, 0.95)
const SLOT_BG_EMPTY := Color(0.10, 0.10, 0.12, 0.95)
const SLOT_BORDER := Color(0.4, 0.4, 0.45, 1)

var player: Player
var current_floor: int = 1

var _hp_bar: ProgressBar
var _hp_label: Label
var _floor_label: Label

var _weapon_slot: Dictionary
var _armor_slot: Dictionary
var _ring_slot: Dictionary
var _bag_slots: Array = []

@onready var status_container: HBoxContainer = $PanelContainer/MarginContainer/HBoxContainer/StatusContainer
@onready var equipped_container: HBoxContainer = $PanelContainer/MarginContainer/HBoxContainer/EquippedContainer
@onready var bag_container: HBoxContainer = $PanelContainer/MarginContainer/HBoxContainer/BagContainer

func _ready() -> void:
	layer = 5
	_build_status()
	_build_equipped()
	_build_bag()

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

func _build_equipped_slot() -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = EQUIPPED_SLOT_SIZE

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(SLOT_ICON_SIZE, SLOT_ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(icon)

	var label := Label.new()
	label.text = "—"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1))
	vbox.add_child(label)

	equipped_container.add_child(panel)

	return {"panel": panel, "icon": icon, "label": label}

func _build_equipped() -> void:
	_weapon_slot = _build_equipped_slot()
	_armor_slot = _build_equipped_slot()
	_ring_slot = _build_equipped_slot()

func _refresh_equipped() -> void:
	if player == null:
		return
	var inv := player.inventory
	_set_equipped_slot(_weapon_slot, inv.weapon, "ATK")
	_set_equipped_slot(_armor_slot, inv.armor, "DEF")
	_set_equipped_slot(_ring_slot, inv.ring, "HP")

func _set_equipped_slot(slot: Dictionary, item: Item, stat_name: String) -> void:
	var panel: PanelContainer = slot["panel"]
	var icon: TextureRect = slot["icon"]
	var label: Label = slot["label"]

	var stylebox := StyleBoxFlat.new()
	stylebox.border_width_left = 1
	stylebox.border_width_top = 1
	stylebox.border_width_right = 1
	stylebox.border_width_bottom = 1
	stylebox.border_color = SLOT_BORDER
	stylebox.corner_radius_top_left = 3
	stylebox.corner_radius_top_right = 3
	stylebox.corner_radius_bottom_right = 3
	stylebox.corner_radius_bottom_left = 3
	stylebox.content_margin_left = 4
	stylebox.content_margin_top = 4
	stylebox.content_margin_right = 4
	stylebox.content_margin_bottom = 4

	if item == null:
		stylebox.bg_color = SLOT_BG_EMPTY
		icon.visible = false
		label.text = "—"
	else:
		stylebox.bg_color = SLOT_BG_FILLED
		icon.visible = true
		icon.texture = item.texture
		var bonus: int = 0
		if item is Weapon:
			bonus = (item as Weapon).atk_bonus
		elif item is Armor:
			bonus = (item as Armor).def_bonus
		elif item is Ring:
			bonus = (item as Ring).max_hp_bonus
		label.text = "+%d %s" % [bonus, stat_name]

	panel.add_theme_stylebox_override("panel", stylebox)

func _build_bag() -> void:
	for i in range(BAG_SLOT_COUNT):
		var panel := PanelContainer.new()
		panel.custom_minimum_size = BAG_SLOT_SIZE

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 4)
		margin.add_theme_constant_override("margin_top", 4)
		margin.add_theme_constant_override("margin_right", 4)
		margin.add_theme_constant_override("margin_bottom", 4)
		panel.add_child(margin)

		var stack := Control.new()
		stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
		margin.add_child(stack)

		var number_label := Label.new()
		number_label.text = str(i + 1)
		number_label.add_theme_font_size_override("font_size", 10)
		number_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
		number_label.position = Vector2(0, 0)
		stack.add_child(number_label)

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(SLOT_ICON_SIZE, SLOT_ICON_SIZE)
		icon.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.anchor_left = 0.5
		icon.anchor_top = 0.5
		icon.anchor_right = 0.5
		icon.anchor_bottom = 0.5
		icon.offset_left = -16.0
		icon.offset_top = -16.0
		icon.offset_right = 16.0
		icon.offset_bottom = 16.0
		stack.add_child(icon)

		bag_container.add_child(panel)

		_bag_slots.append({"panel": panel, "icon": icon, "number_label": number_label})

func _refresh_bag() -> void:
	if player == null:
		return
	var bag := player.inventory.bag

	for i in range(BAG_SLOT_COUNT):
		var slot: Dictionary = _bag_slots[i]
		var panel: PanelContainer = slot["panel"]
		var icon: TextureRect = slot["icon"]

		var stylebox := StyleBoxFlat.new()
		stylebox.border_width_left = 1
		stylebox.border_width_top = 1
		stylebox.border_width_right = 1
		stylebox.border_width_bottom = 1
		stylebox.border_color = SLOT_BORDER
		stylebox.corner_radius_top_left = 3
		stylebox.corner_radius_top_right = 3
		stylebox.corner_radius_bottom_right = 3
		stylebox.corner_radius_bottom_left = 3

		if i < bag.size():
			var item: Item = bag[i]
			stylebox.bg_color = SLOT_BG_FILLED
			icon.visible = true
			icon.texture = item.texture
		else:
			stylebox.bg_color = SLOT_BG_EMPTY
			icon.visible = false

		panel.add_theme_stylebox_override("panel", stylebox)

func refresh() -> void:
	_refresh_status()
	_refresh_equipped()
	_refresh_bag()

func use_consumable_slot(idx: int) -> void:
	if player == null:
		return
	if idx < 0 or idx >= player.inventory.bag.size():
		return
	var item: Item = player.inventory.bag[idx]
	if not (item is Consumable):
		return
	consumable_used.emit(idx)
