class_name InventoryUI
extends CanvasLayer

signal item_used(slot_index: int)
signal closed

@onready var content: VBoxContainer = $Control/PanelContainer/MarginContainer/VBoxContainer

var player: Player

func _ready() -> void:
	visible = false

func open() -> void:
	visible = true
	refresh()

func close() -> void:
	visible = false
	closed.emit()

func refresh() -> void:
	if player == null or content == null:
		return
	for child in content.get_children():
		child.queue_free()

	_add_label("INVENTORY", 18)
	_add_label("")

	var inv := player.inventory
	var weapon_text: String
	if inv.weapon != null:
		weapon_text = "Weapon: %s (+%d ATK)" % [inv.weapon.display_name, inv.weapon.atk_bonus]
	else:
		weapon_text = "Weapon: (none)"

	var armor_text: String
	if inv.armor != null:
		armor_text = "Armor: %s (+%d DEF)" % [inv.armor.display_name, inv.armor.def_bonus]
	else:
		armor_text = "Armor: (none)"

	_add_label(weapon_text)
	_add_label(armor_text)
	_add_label("")
	_add_label("Bag:")

	for i in range(Inventory.BAG_SIZE):
		var line: String
		if i < inv.bag.size():
			line = "  %d. %s" % [i + 1, inv.bag[i].display_name]
		else:
			line = "  %d. (empty)" % (i + 1)
		_add_label(line)

	_add_label("")
	_add_label("[1-8] Use   [I/Esc] Close")

func _add_label(text: String, font_size: int = 0) -> void:
	var label := Label.new()
	label.text = text
	if font_size > 0:
		label.add_theme_font_size_override("font_size", font_size)
	content.add_child(label)

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
