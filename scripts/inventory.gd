class_name Inventory
extends RefCounted
# Holds equipped gear + bag, and owns the pickup routing policy:
# stronger weapons/armor auto-equip (old goes to bag), weaker go to bag,
# rings never auto-swap, all else falls back to add_to_bag.

const BAG_SIZE: int = 8

enum PickupResult {
	EQUIPPED,               # slot was empty, item equipped directly
	EQUIPPED_AND_BAGGED_OLD,# new item stronger, old one moved to bag
	BAGGED,                 # item placed in bag (weaker or consumable or ring-slot-busy)
	REJECTED_BAG_FULL,      # no room; caller should leave item on floor
}

var weapon: Weapon
var armor: Armor
var ring: Ring
var bag: Array[Item] = []

func equip_weapon(new_weapon: Weapon) -> Weapon:
	var previous := weapon
	weapon = new_weapon
	return previous

func equip_armor(new_armor: Armor) -> Armor:
	var previous := armor
	armor = new_armor
	return previous

func equip_ring(new_ring: Ring) -> Ring:
	var previous := ring
	ring = new_ring
	return previous

func add_to_bag(item: Item) -> bool:
	if bag.size() >= BAG_SIZE:
		return false
	bag.append(item)
	return true

func try_pickup(item: Item) -> PickupResult:
	if item is Weapon:
		return _pickup_weapon(item as Weapon)
	if item is Armor:
		return _pickup_armor(item as Armor)
	if item is Ring:
		return _pickup_ring(item as Ring)
	if add_to_bag(item):
		return PickupResult.BAGGED
	return PickupResult.REJECTED_BAG_FULL

func _pickup_weapon(new_weapon: Weapon) -> PickupResult:
	if weapon == null:
		weapon = new_weapon
		return PickupResult.EQUIPPED
	if new_weapon.atk_bonus > weapon.atk_bonus:
		if bag.size() >= BAG_SIZE:
			return PickupResult.REJECTED_BAG_FULL
		bag.append(weapon)
		weapon = new_weapon
		return PickupResult.EQUIPPED_AND_BAGGED_OLD
	if add_to_bag(new_weapon):
		return PickupResult.BAGGED
	return PickupResult.REJECTED_BAG_FULL

func _pickup_armor(new_armor: Armor) -> PickupResult:
	if armor == null:
		armor = new_armor
		return PickupResult.EQUIPPED
	if new_armor.def_bonus > armor.def_bonus:
		if bag.size() >= BAG_SIZE:
			return PickupResult.REJECTED_BAG_FULL
		bag.append(armor)
		armor = new_armor
		return PickupResult.EQUIPPED_AND_BAGGED_OLD
	if add_to_bag(new_armor):
		return PickupResult.BAGGED
	return PickupResult.REJECTED_BAG_FULL

func _pickup_ring(new_ring: Ring) -> PickupResult:
	if ring == null:
		ring = new_ring
		return PickupResult.EQUIPPED
	if add_to_bag(new_ring):
		return PickupResult.BAGGED
	return PickupResult.REJECTED_BAG_FULL
