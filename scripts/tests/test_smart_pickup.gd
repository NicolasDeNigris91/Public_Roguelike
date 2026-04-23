# Run: godot --headless -s scripts/tests/test_smart_pickup.gd
extends SceneTree

func _init() -> void:
	_test_stronger_weapon_replaces_and_bags_old()
	_test_weaker_weapon_goes_to_bag()
	_test_weaker_weapon_bag_full_stays_on_floor()
	print("PASS test_smart_pickup")
	quit()

func _make_player() -> Player:
	var p := Player.new()
	p.inventory = Inventory.new()
	# Start with Long Sword equipped (atk_bonus=2)
	p.inventory.weapon = ItemDB.long_sword()
	return p

func _test_stronger_weapon_replaces_and_bags_old() -> void:
	var p := _make_player()
	var ground := ItemDB.axe()   # atk_bonus=3 > equipped 2
	var result := p.pickup_item(ground)
	assert(result == Player.PickupResult.EQUIPPED_AND_BAGGED_OLD, "expected EQUIPPED_AND_BAGGED_OLD, got %s" % result)
	assert(p.inventory.weapon.id == "axe", "new weapon should be equipped")
	assert(p.inventory.bag.size() == 1, "old weapon should be in bag")
	assert(p.inventory.bag[0].id == "long_sword", "old weapon id mismatch")

func _test_weaker_weapon_goes_to_bag() -> void:
	var p := _make_player()
	var ground := ItemDB.short_sword()   # atk_bonus=1 < equipped 2
	var result := p.pickup_item(ground)
	assert(result == Player.PickupResult.BAGGED, "expected BAGGED, got %s" % result)
	assert(p.inventory.weapon.id == "long_sword", "equipped weapon should be unchanged")
	assert(p.inventory.bag.size() == 1, "ground weapon should be in bag")
	assert(p.inventory.bag[0].id == "short_sword")

func _test_weaker_weapon_bag_full_stays_on_floor() -> void:
	var p := _make_player()
	for i in range(Inventory.BAG_SIZE):
		p.inventory.bag.append(ItemDB.healing_potion())
	var ground := ItemDB.short_sword()
	var result := p.pickup_item(ground)
	assert(result == Player.PickupResult.REJECTED_BAG_FULL, "expected REJECTED_BAG_FULL")
	assert(p.inventory.bag.size() == Inventory.BAG_SIZE, "bag size unchanged")
