# Run: <godot> --headless -s scripts/tests/test_altar_buff.gd
# Tests the AltarBuff.compute() pure mapping. Does not depend on ItemDB.
extends SceneTree

func _init() -> void:
	_test_weapon_yields_atk_plus_one()
	_test_armor_yields_def_plus_one()
	_test_ring_yields_max_hp_plus_two()
	_test_consumable_is_not_applicable()
	print("PASS test_altar_buff")
	quit()

func _weapon() -> Weapon:
	var w := Weapon.new()
	w.id = "test_weapon"
	w.display_name = "test"
	w.atk_bonus = 2
	return w

func _armor() -> Armor:
	var a := Armor.new()
	a.id = "test_armor"
	a.display_name = "test"
	a.def_bonus = 1
	return a

func _ring() -> Ring:
	var r := Ring.new()
	r.id = "test_ring"
	r.display_name = "test"
	r.max_hp_bonus = 5
	return r

func _plain_item() -> Item:
	var i := Item.new()
	i.id = "plain"
	i.display_name = "plain"
	return i

func _test_weapon_yields_atk_plus_one() -> void:
	var result := AltarBuff.compute(_weapon())
	assert(result["applicable"] == true, "weapon should be sacrificable")
	assert(result["stat"] == AltarBuff.STAT_ATK, "expected atk, got %s" % result["stat"])
	assert(result["delta"] == 1, "expected delta 1, got %s" % result["delta"])

func _test_armor_yields_def_plus_one() -> void:
	var result := AltarBuff.compute(_armor())
	assert(result["applicable"] == true)
	assert(result["stat"] == AltarBuff.STAT_DEF)
	assert(result["delta"] == 1)

func _test_ring_yields_max_hp_plus_two() -> void:
	var result := AltarBuff.compute(_ring())
	assert(result["applicable"] == true)
	assert(result["stat"] == AltarBuff.STAT_MAX_HP)
	assert(result["delta"] == 2)

func _test_consumable_is_not_applicable() -> void:
	# Note: we don't construct Consumable because consumable.gd may transitively
	# reference autoloads that blow up headless. A plain Item is sufficient to test
	# the "not applicable" branch (the same branch that Consumable and other
	# non-Weapon/Armor/Ring items would take).
	var result := AltarBuff.compute(_plain_item())
	assert(result["applicable"] == false, "plain Item should not be sacrificable")
