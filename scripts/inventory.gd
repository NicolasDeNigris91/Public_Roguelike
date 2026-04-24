class_name Inventory
extends RefCounted
# Holds equipped gear + bag, and owns the pickup routing policy:
# stronger weapons/armor auto-equip (old goes to bag), weaker go to bag,
# rings never auto-swap, all else falls back to add_to_bag.

const BAG_SIZE: int = 5                 # equipables only now (consumables moved to potion_stacks)
const MAX_POTION_STACKS: int = 3        # distinct consumable types held at once

enum PickupResult {
	EQUIPPED,                # slot was empty, item equipped directly
	EQUIPPED_AND_BAGGED_OLD, # new item stronger, old one moved to bag
	EQUIPPED_AND_DROPPED_OLD,# swap happened, old item should land on the floor
	BAGGED,                  # item placed in bag (weaker or consumable or ring-slot-busy)
	REJECTED_BAG_FULL,       # no room; caller should leave item on floor
}

# When a pickup routes through the "drop old on floor" path (currently the
# rosary swap), the displaced item lands here for the caller to emit as an
# item_dropped signal. Consumed once by Player.pickup after try_pickup.
var pending_floor_drop: Item = null

var weapon: Weapon
var armor: Armor
var shield: Shield
var ring: Ring
var amulet: Amulet
# Bag holds equipable-only items (weapons/armor/shields/rings/amulets) now.
# Consumables never enter here; they stack in potion_stacks instead.
var bag: Array[Item] = []
# Potion stacks: up to 3 entries, each {"item_id": String, "count": int}.
# Same item_id collapses into a single stack with count incremented.
var potion_stacks: Array = []

func equip_weapon(new_weapon: Weapon) -> Weapon:
	var previous := weapon
	weapon = new_weapon
	return previous

func equip_armor(new_armor: Armor) -> Armor:
	var previous := armor
	armor = new_armor
	return previous

func equip_shield(new_shield: Shield) -> Shield:
	var previous := shield
	shield = new_shield
	return previous

func equip_ring(new_ring: Ring) -> Ring:
	var previous := ring
	ring = new_ring
	return previous

func equip_amulet(new_amulet: Amulet) -> Amulet:
	var previous := amulet
	amulet = new_amulet
	return previous

func add_to_bag(item: Item) -> bool:
	if bag.size() >= BAG_SIZE:
		return false
	bag.append(item)
	return true

func try_pickup(item: Item) -> PickupResult:
	if item is Consumable:
		return _pickup_potion(item as Consumable)
	if item is Weapon:
		return _pickup_weapon(item as Weapon)
	if item is Armor:
		return _pickup_armor(item as Armor)
	if item is Shield:
		return _pickup_shield(item as Shield)
	if item is Ring:
		return _pickup_ring(item as Ring)
	if item is Amulet:
		return _pickup_amulet(item as Amulet)
	if add_to_bag(item):
		return PickupResult.BAGGED
	return PickupResult.REJECTED_BAG_FULL

# Consumables stack by item_id up to MAX_POTION_STACKS distinct types.
# Beyond that, pickup is rejected (item stays on floor).
func _pickup_potion(consumable: Consumable) -> PickupResult:
	for stack in potion_stacks:
		if stack["item_id"] == consumable.id:
			stack["count"] = int(stack["count"]) + 1
			return PickupResult.BAGGED
	if potion_stacks.size() < MAX_POTION_STACKS:
		potion_stacks.append({"item_id": consumable.id, "count": 1})
		return PickupResult.BAGGED
	return PickupResult.REJECTED_BAG_FULL

# Peek at a potion stack without consuming. Returns empty string if the
# slot index is out of range.
func peek_potion(stack_idx: int) -> String:
	if stack_idx < 0 or stack_idx >= potion_stacks.size():
		return ""
	return String(potion_stacks[stack_idx]["item_id"])

# Decrement the stack at stack_idx by one; if count hits zero, drop the
# stack entirely so subsequent stacks collapse toward index 0.
func consume_potion(stack_idx: int) -> void:
	if stack_idx < 0 or stack_idx >= potion_stacks.size():
		return
	var stack: Dictionary = potion_stacks[stack_idx]
	stack["count"] = int(stack["count"]) - 1
	if stack["count"] <= 0:
		potion_stacks.remove_at(stack_idx)

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

func _pickup_shield(new_shield: Shield) -> PickupResult:
	if shield == null:
		shield = new_shield
		return PickupResult.EQUIPPED
	# Rosary swap — always trades places with whatever is in the shield
	# slot, regardless of def_bonus. The displaced item drops back to the
	# floor at the pickup tile so the swap is perfectly reversible: walking
	# back onto the shrine puts the rosary back on the floor and re-equips
	# the original shield. Narrative mechanic, not a stat decision.
	if new_shield.id == "rosary" or shield.id == "rosary":
		pending_floor_drop = shield
		shield = new_shield
		return PickupResult.EQUIPPED_AND_DROPPED_OLD
	if new_shield.def_bonus > shield.def_bonus:
		if bag.size() >= BAG_SIZE:
			return PickupResult.REJECTED_BAG_FULL
		bag.append(shield)
		shield = new_shield
		return PickupResult.EQUIPPED_AND_BAGGED_OLD
	if add_to_bag(new_shield):
		return PickupResult.BAGGED
	return PickupResult.REJECTED_BAG_FULL

func _pickup_ring(new_ring: Ring) -> PickupResult:
	if ring == null:
		ring = new_ring
		return PickupResult.EQUIPPED
	if add_to_bag(new_ring):
		return PickupResult.BAGGED
	return PickupResult.REJECTED_BAG_FULL

func _pickup_amulet(new_amulet: Amulet) -> PickupResult:
	if amulet == null:
		amulet = new_amulet
		return PickupResult.EQUIPPED
	# Amulets, like rings, don't auto-swap — different variants have non-comparable
	# effects. Second amulet goes to the bag; player manually chooses which to wear.
	if add_to_bag(new_amulet):
		return PickupResult.BAGGED
	return PickupResult.REJECTED_BAG_FULL
