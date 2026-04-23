class_name InventoryUI
extends CanvasLayer

signal item_used(slot_index: int)
signal closed

const ICON_SIZE: int = 32
const SECTION_HEADER_FONT_SIZE: int = 14

@onready var equipped_vbox: VBoxContainer = $Control/PanelContainer/MarginContainer/VBoxContainer/EquippedPanel/EquippedVBox
@onready var bag_vbox: VBoxContainer = $Control/PanelContainer/MarginContainer/VBoxContainer/BagPanel/BagVBox

var player: Player

func _ready() -> void:
	visible = false

func open() -> void:
	AudioManager.play_sfx("ui_open")
	visible = true
	refresh()

func close() -> void:
	AudioManager.play_sfx("ui_close")
	visible = false
	closed.emit()

func refresh() -> void:
	if player == null or equipped_vbox == null or bag_vbox == null:
		return

	for child in equipped_vbox.get_children():
		child.queue_free()
	for child in bag_vbox.get_children():
		child.queue_free()

	var inv := player.inventory

	_add_section_header(equipped_vbox, "Equipped")

	if inv.weapon != null:
		_add_item_row(equipped_vbox, inv.weapon.texture, "%s (+%d ATK)" % [inv.weapon.display_name, inv.weapon.atk_bonus])
	else:
		_add_item_row(equipped_vbox, null, "Weapon: (none)")

	if inv.armor != null:
		_add_item_row(equipped_vbox, inv.armor.texture, "%s (+%d DEF)" % [inv.armor.display_name, inv.armor.def_bonus])
	else:
		_add_item_row(equipped_vbox, null, "Armor: (none)")

	if inv.ring != null:
		_add_item_row(equipped_vbox, inv.ring.texture, "%s (+%d max HP)" % [inv.ring.display_name, inv.ring.max_hp_bonus])
	else:
		_add_item_row(equipped_vbox, null, "Ring: (none)")

	_add_section_header(bag_vbox, "Bag")

	for i in range(Inventory.BAG_SIZE):
		if i < inv.bag.size():
			var item: Item = inv.bag[i]
			_add_item_row(bag_vbox, item.texture, "%d. %s" % [i + 1, item.display_name])
		else:
			_add_item_row(bag_vbox, null, "%d. (empty)" % (i + 1))

func _add_section_header(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", SECTION_HEADER_FONT_SIZE)
	label.modulate = Color(0.8, 0.8, 0.9, 1.0)
	parent.add_child(label)

func _add_item_row(parent: VBoxContainer, texture: Texture2D, text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = texture
	row.add_child(icon)

	var label := Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	parent.add_child(row)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_I, KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			close()
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8:
			var slot: int = event.keycode - KEY_1
			get_viewport().set_input_as_handled()
			item_used.emit(slot)
