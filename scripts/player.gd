class_name Player
extends Actor

signal turn_done

const BASE_ATK: int = 5
const BASE_DEF: int = 3

var dungeon: Dungeon
var turn_manager: TurnManager
var turn_active: bool = true
var inventory: Inventory

func _ready() -> void:
	color = Color("#4a90e2")
	hp = 20
	max_hp = 20
	inventory = Inventory.new()
	_recalculate_stats()
	super._ready()

func _unhandled_input(event: InputEvent) -> void:
	if not turn_active:
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	var direction := Vector2i.ZERO
	match event.keycode:
		KEY_UP, KEY_W:
			direction = Vector2i(0, -1)
		KEY_DOWN, KEY_S:
			direction = Vector2i(0, 1)
		KEY_LEFT, KEY_A:
			direction = Vector2i(-1, 0)
		KEY_RIGHT, KEY_D:
			direction = Vector2i(1, 0)
		_:
			return

	get_viewport().set_input_as_handled()

	var target_pos := grid_position + direction
	var target_enemy := _enemy_at(target_pos)

	if target_enemy != null:
		Combat.attack(self, target_enemy)
		turn_done.emit()
	elif dungeon and dungeon.grid.is_walkable(target_pos):
		move_to(target_pos)
		turn_done.emit()

func pickup(item: Item) -> void:
	if item is Weapon:
		var old := inventory.equip_weapon(item)
		if old != null:
			inventory.add_to_bag(old)
		_recalculate_stats()
		print("Picked up %s — equipped (ATK %d)" % [item.display_name, atk])
	elif item is Armor:
		var old := inventory.equip_armor(item)
		if old != null:
			inventory.add_to_bag(old)
		_recalculate_stats()
		print("Picked up %s — equipped (DEF %d)" % [item.display_name, def])
	else:
		if inventory.add_to_bag(item):
			print("Picked up %s — in bag" % item.display_name)
		else:
			print("Bag full, could not pick up %s" % item.display_name)

func die() -> void:
	died.emit()
	turn_active = false

func _recalculate_stats() -> void:
	atk = BASE_ATK
	def = BASE_DEF
	if inventory.weapon != null:
		atk += inventory.weapon.atk_bonus
	if inventory.armor != null:
		def += inventory.armor.def_bonus

func _enemy_at(pos: Vector2i) -> Enemy:
	if turn_manager == null:
		return null
	for e in turn_manager.enemies:
		if is_instance_valid(e) and e.grid_position == pos:
			return e
	return null
