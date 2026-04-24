class_name ItemDB

static func short_sword() -> Weapon:
	var w := Weapon.new()
	w.id = "short_sword"
	w.display_name = "Short Sword"
	w.texture = SpriteDB.item("short_sword")
	w.atk_bonus = 1
	return w

static func long_sword() -> Weapon:
	var w := Weapon.new()
	w.id = "long_sword"
	w.display_name = "Long Sword"
	w.texture = SpriteDB.item("long_sword")
	w.atk_bonus = 2
	return w

static func axe() -> Weapon:
	var w := Weapon.new()
	w.id = "axe"
	w.display_name = "Axe"
	w.texture = SpriteDB.item("axe")
	w.atk_bonus = 3
	return w

static func hammer() -> Weapon:
	var w := Weapon.new()
	w.id = "hammer"
	w.display_name = "Hammer"
	w.texture = SpriteDB.item("hammer")
	w.atk_bonus = 4
	return w

static func dagger() -> Weapon:
	var w := Weapon.new()
	w.id = "dagger"
	w.display_name = "Dagger"
	w.texture = SpriteDB.item("dagger")
	w.atk_bonus = 0
	return w

static func leather_armor() -> Armor:
	var a := Armor.new()
	a.id = "leather_armor"
	a.display_name = "Leather Armor"
	a.texture = SpriteDB.item("leather_armor")
	a.def_bonus = 1
	return a

static func chain_mail() -> Armor:
	var a := Armor.new()
	a.id = "chain_mail"
	a.display_name = "Chain Mail"
	a.texture = SpriteDB.item("chain_mail")
	a.def_bonus = 2
	return a

static func plate_armor() -> Armor:
	var a := Armor.new()
	a.id = "plate_armor"
	a.display_name = "Plate Armor"
	a.texture = SpriteDB.item("plate_armor")
	a.def_bonus = 3
	return a

static func healing_potion() -> Consumable:
	var c := Consumable.new()
	c.id = "healing_potion"
	c.display_name = "Healing Potion"
	c.description = "Cura 10 HP"
	c.texture = SpriteDB.item("healing_potion")
	c.effect = Consumable.Effect.HEAL_MINOR
	c.amount = 10
	return c

static func greater_potion() -> Consumable:
	var c := Consumable.new()
	c.id = "greater_potion"
	c.display_name = "Greater Potion"
	c.description = "Cura totalmente"
	c.texture = SpriteDB.item("greater_potion")
	c.effect = Consumable.Effect.HEAL_FULL
	return c

static func teleport_scroll() -> Consumable:
	var c := Consumable.new()
	c.id = "teleport_scroll"
	c.display_name = "Teleport Scroll"
	c.description = "Teleporta para tile aleatório"
	c.texture = SpriteDB.item("teleport_scroll")
	c.effect = Consumable.Effect.TELEPORT
	return c

static func ring_of_life() -> Ring:
	var r := Ring.new()
	r.id = "ring_of_life"
	r.display_name = "Ring of Life"
	r.texture = SpriteDB.item("ring_of_life")
	r.max_hp_bonus = 10
	return r

static func ring_of_strength() -> Ring:
	var r := Ring.new()
	r.id = "ring_of_strength"
	r.display_name = "Ring of Strength"
	r.texture = SpriteDB.item("ring_of_strength")
	r.atk_bonus = 2
	return r

static func ring_of_protection() -> Ring:
	var r := Ring.new()
	r.id = "ring_of_protection"
	r.display_name = "Ring of Protection"
	r.texture = SpriteDB.item("ring_of_protection")
	r.def_bonus = 2
	return r

static func ring_of_vitality() -> Ring:
	var r := Ring.new()
	r.id = "ring_of_vitality"
	r.display_name = "Ring of Vitality"
	r.texture = SpriteDB.item("ring_of_vitality")
	r.max_hp_bonus = 15
	return r

static func buckler() -> Shield:
	var s := Shield.new()
	s.id = "buckler"
	s.display_name = "Buckler"
	s.texture = SpriteDB.item("buckler")
	s.def_bonus = 1
	return s

static func kite_shield() -> Shield:
	var s := Shield.new()
	s.id = "kite_shield"
	s.display_name = "Kite Shield"
	s.texture = SpriteDB.item("kite_shield")
	s.def_bonus = 2
	return s

static func tower_shield() -> Shield:
	var s := Shield.new()
	s.id = "tower_shield"
	s.display_name = "Tower Shield"
	s.texture = SpriteDB.item("tower_shield")
	s.def_bonus = 3
	return s

static func from_id(id: String) -> Item:
	match id:
		"short_sword": return short_sword()
		"long_sword": return long_sword()
		"axe": return axe()
		"hammer": return hammer()
		"dagger": return dagger()
		"leather_armor": return leather_armor()
		"chain_mail": return chain_mail()
		"plate_armor": return plate_armor()
		"healing_potion": return healing_potion()
		"greater_potion": return greater_potion()
		"teleport_scroll": return teleport_scroll()
		"ring_of_life": return ring_of_life()
		"ring_of_strength": return ring_of_strength()
		"ring_of_protection": return ring_of_protection()
		"ring_of_vitality": return ring_of_vitality()
		"buckler": return buckler()
		"kite_shield": return kite_shield()
		"tower_shield": return tower_shield()
	return null

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

static func random_ring(rng: RandomNumberGenerator) -> Ring:
	match rng.randi() % 4:
		0:
			return ring_of_life()
		1:
			return ring_of_strength()
		2:
			return ring_of_protection()
		_:
			return ring_of_vitality()

static func random_shield(rng: RandomNumberGenerator) -> Shield:
	match rng.randi() % 3:
		0:
			return buckler()
		1:
			return kite_shield()
		_:
			return tower_shield()

static func random_item(rng: RandomNumberGenerator) -> Item:
	var roll := rng.randf()
	if roll < 0.30:
		return random_weapon(rng)
	elif roll < 0.50:
		return random_armor(rng)
	elif roll < 0.65:
		return random_shield(rng)
	elif roll < 0.90:
		return random_consumable(rng)
	else:
		return random_ring(rng)
