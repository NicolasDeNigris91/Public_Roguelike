class_name Inventory
extends RefCounted

const BAG_SIZE: int = 8

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
