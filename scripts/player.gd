class_name Player
extends Actor

signal turn_done

const BASE_ATK: int = 5
const BASE_DEF: int = 3
const BASE_MAX_HP: int = 20
const BASE_VISION_RANGE: int = 8

var dungeon: Dungeon
var turn_manager: TurnManager
var turn_active: bool = true
var inventory: Inventory
var vision_range: int = BASE_VISION_RANGE
var vision_debuff_turns: int = 0

func _ready() -> void:
	max_hp = BASE_MAX_HP
	hp = BASE_MAX_HP
	inventory = Inventory.new()
	_recalculate_stats()
	super._ready()
	sprite_node.texture = SpriteDB.actor("player")

func _unhandled_input(event: InputEvent) -> void:
	if not turn_active or is_tweening:
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
		await Combat.attack(self, target_enemy)
		_end_turn()
	elif dungeon and dungeon.grid.is_walkable(target_pos):
		AudioManager.play_sfx("step")
		move_to(target_pos)
		await moved
		_end_turn()

func _end_turn() -> void:
	if vision_debuff_turns > 0:
		vision_debuff_turns -= 1
		if vision_debuff_turns == 0:
			vision_range = BASE_VISION_RANGE
			if dungeon != null:
				dungeon.update_fov(grid_position, vision_range)
			print("Player vision restored")
	turn_done.emit()

func apply_vision_debuff(new_range: int, turns: int) -> void:
	vision_range = new_range
	vision_debuff_turns = turns
	if dungeon != null:
		dungeon.update_fov(grid_position, vision_range)
	print("Player vision reduced to %d for %d turns" % [new_range, turns])

func pickup(item: Item) -> void:
	AudioManager.play_sfx("pickup")
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
	elif item is Ring:
		var old := inventory.equip_ring(item)
		if old != null:
			inventory.add_to_bag(old)
		_recalculate_stats()
		print("Picked up %s — equipped (max HP %d)" % [item.display_name, max_hp])
	else:
		if inventory.add_to_bag(item):
			print("Picked up %s — in bag" % item.display_name)
		else:
			print("Bag full, could not pick up %s" % item.display_name)

func die() -> void:
	AudioManager.play_sfx("player_die")
	AudioManager.stop_music(0.5)
	if Combat.world_node != null:
		Shake.apply(Combat.world_node, Combat.SHAKE_DEATH.x, Combat.SHAKE_DEATH.y)
		HitPause.freeze(get_tree(), 0.1)
	died.emit()
	turn_active = false

func _recalculate_stats() -> void:
	atk = BASE_ATK
	def = BASE_DEF
	if inventory.weapon != null:
		atk += inventory.weapon.atk_bonus
	if inventory.armor != null:
		def += inventory.armor.def_bonus

	var new_max_hp := BASE_MAX_HP
	if inventory.ring != null:
		new_max_hp += inventory.ring.max_hp_bonus

	var delta := new_max_hp - max_hp
	max_hp = new_max_hp
	if delta > 0:
		hp += delta
	hp = mini(hp, max_hp)
	queue_redraw()

func _enemy_at(pos: Vector2i) -> Enemy:
	if turn_manager == null:
		return null
	for e in turn_manager.enemies:
		if is_instance_valid(e) and e.grid_position == pos:
			return e
	return null
