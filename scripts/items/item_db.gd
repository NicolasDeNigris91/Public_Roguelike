class_name ItemDB

static func short_sword() -> Weapon:
	var w := Weapon.new()
	w.display_name = "Short Sword"
	w.texture = SpriteDB.item("short_sword")
	w.atk_bonus = 1
	return w

static func long_sword() -> Weapon:
	var w := Weapon.new()
	w.display_name = "Long Sword"
	w.texture = SpriteDB.item("long_sword")
	w.atk_bonus = 2
	return w

static func axe() -> Weapon:
	var w := Weapon.new()
	w.display_name = "Axe"
	w.texture = SpriteDB.item("axe")
	w.atk_bonus = 3
	return w

static func hammer() -> Weapon:
	var w := Weapon.new()
	w.display_name = "Hammer"
	w.texture = SpriteDB.item("hammer")
	w.atk_bonus = 4
	return w

static func dagger() -> Weapon:
	var w := Weapon.new()
	w.display_name = "Dagger"
	w.texture = SpriteDB.item("dagger")
	w.atk_bonus = 0
	return w

static func leather_armor() -> Armor:
	var a := Armor.new()
	a.display_name = "Leather Armor"
	a.texture = SpriteDB.item("leather_armor")
	a.def_bonus = 1
	return a

static func chain_mail() -> Armor:
	var a := Armor.new()
	a.display_name = "Chain Mail"
	a.texture = SpriteDB.item("chain_mail")
	a.def_bonus = 2
	return a

static func plate_armor() -> Armor:
	var a := Armor.new()
	a.display_name = "Plate Armor"
	a.texture = SpriteDB.item("plate_armor")
	a.def_bonus = 3
	return a

static func healing_potion() -> Consumable:
	var c := Consumable.new()
	c.display_name = "Healing Potion"
	c.texture = SpriteDB.item("healing_potion")
	c.effect = Consumable.Effect.HEAL_MINOR
	c.amount = 10
	return c

static func greater_potion() -> Consumable:
	var c := Consumable.new()
	c.display_name = "Greater Potion"
	c.texture = SpriteDB.item("greater_potion")
	c.effect = Consumable.Effect.HEAL_FULL
	return c

static func teleport_scroll() -> Consumable:
	var c := Consumable.new()
	c.display_name = "Teleport Scroll"
	c.texture = SpriteDB.item("teleport_scroll")
	c.effect = Consumable.Effect.TELEPORT
	return c

static func ring_of_life() -> Ring:
	var r := Ring.new()
	r.display_name = "Ring of Life"
	r.texture = SpriteDB.item("ring_of_life")
	r.max_hp_bonus = 10
	return r

static func random_weapon(rng: RandomNumberGenerator) -> Weapon:
	match rng.randi() % 5:
		0:
			return short_sword()
		1:
			return long_sword()
		2:
			return axe()
		3:
			return hammer()
		_:
			return dagger()

static func random_armor(rng: RandomNumberGenerator) -> Armor:
	match rng.randi() % 3:
		0:
			return leather_armor()
		1:
			return chain_mail()
		_:
			return plate_armor()

static func random_consumable(rng: RandomNumberGenerator) -> Consumable:
	var roll := rng.randf()
	if roll < 0.5:
		return healing_potion()
	elif roll < 0.8:
		return greater_potion()
	else:
		return teleport_scroll()

static func random_ring(_rng: RandomNumberGenerator) -> Ring:
	return ring_of_life()

static func random_item(rng: RandomNumberGenerator) -> Item:
	var roll := rng.randf()
	if roll < 0.35:
		return random_weapon(rng)
	elif roll < 0.60:
		return random_armor(rng)
	elif roll < 0.85:
		return random_consumable(rng)
	else:
		return random_ring(rng)
