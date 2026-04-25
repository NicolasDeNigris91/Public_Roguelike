# Run: <godot> --headless -s scripts/tests/test_smart_pickup.gd
# Tests the Inventory.try_pickup routing rules without using ItemDB,
# to avoid autoload dependencies in headless mode.
extends SceneTree

func _init() -> void:
	_test_empty_weapon_slot_equips()
	_test_stronger_weapon_replaces_and_bags_old()
	_test_weaker_weapon_goes_to_bag()
	_test_weaker_weapon_bag_full_stays_on_floor()
	_test_stronger_weapon_bag_full_rejected()
	_test_empty_armor_slot_equips()
	_test_stronger_armor_replaces_and_bags_old()
	_test_weaker_armor_goes_to_bag()
	_test_empty_ring_slot_equips()
	_test_ring_to_busy_slot_bags()
	_test_consumable_always_bags()
	print("PASS test_smart_pickup")
	quit()

func _weapon(id: String, atk: int) -> Weapon:
	var w := Weapon.new()
	w.id = id
	w.display_name = id
	w.atk_bonus = atk
	return w

func _armor(id: String, def: int) -> Armor:
	var a := Armor.new()
	a.id = id
	a.display_name = id
	a.def_bonus = def
	return a

func _ring(id: String, hp: int) -> Ring:
	var r := Ring.new()
	r.id = id
	r.display_name = id
	r.max_hp_bonus = hp
	return r

func _consumable(id: String) -> Item:
	# Use base Item to avoid Consumable's dependency on Combat/Player (which
	# reference AudioManager/RunStats autoloads - not available in headless mode).
	var c := Item.new()
	c.id = id
	c.display_name = id
	return c

func _test_empty_weapon_slot_equips() -> void:
	var inv := Inventory.new()
	var result := inv.try_pickup(_weapon("dagger", 0))
	assert(result == Inventory.PickupResult.EQUIPPED, "expected EQUIPPED, got %s" % result)
	assert(inv.weapon != null and inv.weapon.id == "dagger")
	assert(inv.bag.is_empty())

func _test_stronger_weapon_replaces_and_bags_old() -> void:
	var inv := Inventory.new()
	inv.weapon = _weapon("long_sword", 2)
	var result := inv.try_pickup(_weapon("axe", 3))
	assert(result == Inventory.PickupResult.EQUIPPED_AND_BAGGED_OLD, "expected EQUIPPED_AND_BAGGED_OLD, got %s" % result)
	assert(inv.weapon.id == "axe", "new weapon should be equipped, got %s" % inv.weapon.id)
	assert(inv.bag.size() == 1 and inv.bag[0].id == "long_sword", "old weapon should be in bag")

func _test_weaker_weapon_goes_to_bag() -> void:
	var inv := Inventory.new()
	inv.weapon = _weapon("long_sword", 2)
	var result := inv.try_pickup(_weapon("short_sword", 1))
	assert(result == Inventory.PickupResult.BAGGED, "expected BAGGED, got %s" % result)
	assert(inv.weapon.id == "long_sword", "equipped weapon should be unchanged")
	assert(inv.bag.size() == 1 and inv.bag[0].id == "short_sword")

func _test_weaker_weapon_bag_full_stays_on_floor() -> void:
	var inv := Inventory.new()
	inv.weapon = _weapon("long_sword", 2)
	for i in range(Inventory.BAG_SIZE):
		inv.bag.append(_consumable("filler_%d" % i))
	var result := inv.try_pickup(_weapon("short_sword", 1))
	assert(result == Inventory.PickupResult.REJECTED_BAG_FULL, "expected REJECTED_BAG_FULL, got %s" % result)
	assert(inv.bag.size() == Inventory.BAG_SIZE, "bag size unchanged")

func _test_stronger_weapon_bag_full_rejected() -> void:
	var inv := Inventory.new()
	inv.weapon = _weapon("long_sword", 2)
	for i in range(Inventory.BAG_SIZE):
		inv.bag.append(_consumable("filler_%d" % i))
	var result := inv.try_pickup(_weapon("axe", 3))
	assert(result == Inventory.PickupResult.REJECTED_BAG_FULL, "stronger weapon with full bag should reject")
	assert(inv.weapon.id == "long_sword")

func _test_empty_armor_slot_equips() -> void:
	var inv := Inventory.new()
	var result := inv.try_pickup(_armor("leather", 1))
	assert(result == Inventory.PickupResult.EQUIPPED)
	assert(inv.armor.id == "leather")

func _test_stronger_armor_replaces_and_bags_old() -> void:
	var inv := Inventory.new()
	inv.armor = _armor("leather", 1)
	var result := inv.try_pickup(_armor("plate", 3))
	assert(result == Inventory.PickupResult.EQUIPPED_AND_BAGGED_OLD)
	assert(inv.armor.id == "plate")
	assert(inv.bag[0].id == "leather")

func _test_weaker_armor_goes_to_bag() -> void:
	var inv := Inventory.new()
	inv.armor = _armor("plate", 3)
	var result := inv.try_pickup(_armor("leather", 1))
	assert(result == Inventory.PickupResult.BAGGED)
	assert(inv.armor.id == "plate")
	assert(inv.bag[0].id == "leather")

func _test_empty_ring_slot_equips() -> void:
	var inv := Inventory.new()
	var result := inv.try_pickup(_ring("life", 10))
	assert(result == Inventory.PickupResult.EQUIPPED)
	assert(inv.ring.id == "life")

func _test_ring_to_busy_slot_bags() -> void:
	var inv := Inventory.new()
	inv.ring = _ring("life_a", 10)
	var result := inv.try_pickup(_ring("life_b", 10))
	assert(result == Inventory.PickupResult.BAGGED, "second ring should go to bag")
	assert(inv.ring.id == "life_a")
	assert(inv.bag.size() == 1 and inv.bag[0].id == "life_b")

func _test_consumable_always_bags() -> void:
	var inv := Inventory.new()
	inv.weapon = _weapon("long_sword", 2)
	var result := inv.try_pickup(_consumable("healing_potion"))
	assert(result == Inventory.PickupResult.BAGGED)
	assert(inv.bag.size() == 1 and inv.bag[0].id == "healing_potion")
