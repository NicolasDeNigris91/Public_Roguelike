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

# Act 2 themed weapon — bones of the catacombs fused into a blade.
static func ancient_sword() -> Weapon:
	var w := Weapon.new()
	w.id = "ancient_sword"
	w.display_name = "Ancient Sword"
	w.texture = SpriteDB.item("ancient_sword")
	w.atk_bonus = 5
	return w

# Act 3 themed weapon — harvests sacrificial blood with every strike.
static func scythe_of_curses() -> Weapon:
	var w := Weapon.new()
	w.id = "scythe_of_curses"
	w.display_name = "Scythe of Curses"
	w.texture = SpriteDB.item("scythe_of_curses")
	w.atk_bonus = 6
	return w

# Act 4 themed weapon — fire-demon blade, heavy and hot.
static func sword_of_cerebov() -> Weapon:
	var w := Weapon.new()
	w.id = "sword_of_cerebov"
	w.display_name = "Sword of Cerebov"
	w.texture = SpriteDB.item("sword_of_cerebov")
	w.atk_bonus = 7
	return w

# Act 5 themed weapon — the Demon Lord's own pattern, infernal steel.
static func demon_blade() -> Weapon:
	var w := Weapon.new()
	w.id = "demon_blade"
	w.display_name = "Demon Blade"
	w.texture = SpriteDB.item("demon_blade")
	w.atk_bonus = 8
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

static func potion_of_strength() -> Consumable:
	var c := Consumable.new()
	c.id = "potion_of_strength"
	c.display_name = "Potion of Strength"
	c.description = "+3 ATK por 10 turnos"
	c.texture = SpriteDB.item("potion_of_strength")
	c.effect = Consumable.Effect.BUFF_ATK
	c.amount = 3
	c.duration = 10
	return c

static func potion_of_resistance() -> Consumable:
	var c := Consumable.new()
	c.id = "potion_of_resistance"
	c.display_name = "Potion of Resistance"
	c.description = "+3 DEF por 10 turnos"
	c.texture = SpriteDB.item("potion_of_resistance")
	c.effect = Consumable.Effect.BUFF_DEF
	c.amount = 3
	c.duration = 10
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

static func amulet_of_faith() -> Amulet:
	var a := Amulet.new()
	a.id = "amulet_of_faith"
	a.display_name = "Amulet of Faith"
	a.texture = SpriteDB.item("amulet_of_faith")
	a.atk_bonus = 1
	a.def_bonus = 1
	return a

static func amulet_of_warding() -> Amulet:
	var a := Amulet.new()
	a.id = "amulet_of_warding"
	a.display_name = "Amulet of Warding"
	a.texture = SpriteDB.item("amulet_of_warding")
	a.def_bonus = 3
	return a

static func amulet_of_resolve() -> Amulet:
	var a := Amulet.new()
	a.id = "amulet_of_resolve"
	a.display_name = "Amulet of Resolve"
	a.texture = SpriteDB.item("amulet_of_resolve")
	a.max_hp_bonus = 20
	return a

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
		"ancient_sword": return ancient_sword()
		"scythe_of_curses": return scythe_of_curses()
		"sword_of_cerebov": return sword_of_cerebov()
		"demon_blade": return demon_blade()
		"leather_armor": return leather_armor()
		"chain_mail": return chain_mail()
		"plate_armor": return plate_armor()
		"healing_potion": return healing_potion()
		"greater_potion": return greater_potion()
		"teleport_scroll": return teleport_scroll()
		"potion_of_strength": return potion_of_strength()
		"potion_of_resistance": return potion_of_resistance()
		"ring_of_life": return ring_of_life()
		"ring_of_strength": return ring_of_strength()
		"ring_of_protection": return ring_of_protection()
		"ring_of_vitality": return ring_of_vitality()
		"amulet_of_faith": return amulet_of_faith()
		"amulet_of_warding": return amulet_of_warding()
		"amulet_of_resolve": return amulet_of_resolve()
		"buckler": return buckler()
		"kite_shield": return kite_shield()
		"tower_shield": return tower_shield()
	return null

static func random_weapon(rng: RandomNumberGenerator, floor_num: int = 1) -> Weapon:
	# Act-aware weapon pool. Each act drops thematically appropriate gear —
	# weak starters disappear from late acts, and each act's signature
	# weapon (ancient_sword/scythe_of_curses/sword_of_cerebov/demon_blade)
	# only appears from its act onward, escalating ATK through the descent.
	var act: int = ActConfig.act_for_floor(floor_num)
	var roll := rng.randf()
	match act:
		1:
			# Act 1 — Bastion: basic starters only. Max atk = 2.
			if roll < 0.4:
				return dagger()
			if roll < 0.75:
				return short_sword()
			return long_sword()
		2:
			# Act 2 — Catacombs: intro Ancient Sword. Old weapons fade out.
			if roll < 0.2:
				return short_sword()
			if roll < 0.45:
				return long_sword()
			if roll < 0.7:
				return axe()
			if roll < 0.9:
				return hammer()
			return ancient_sword()
		3:
			# Act 3 — Blood Sanctum: Scythe of Curses enters top slot.
			if roll < 0.2:
				return axe()
			if roll < 0.45:
				return hammer()
			if roll < 0.75:
				return ancient_sword()
			return scythe_of_curses()
		4:
			# Act 4 — Burning Halls: Sword of Cerebov drops in.
			if roll < 0.2:
				return hammer()
			if roll < 0.45:
				return ancient_sword()
			if roll < 0.75:
				return scythe_of_curses()
			return sword_of_cerebov()
		_:
			# Act 5 — Infernal Throne: only top-tier infernal weapons appear.
			if roll < 0.25:
				return scythe_of_curses()
			if roll < 0.55:
				return sword_of_cerebov()
			return demon_blade()

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
	if roll < 0.35:
		return healing_potion()
	elif roll < 0.55:
		return greater_potion()
	elif roll < 0.70:
		return teleport_scroll()
	elif roll < 0.85:
		return potion_of_strength()
	else:
		return potion_of_resistance()

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

static func random_amulet(rng: RandomNumberGenerator) -> Amulet:
	match rng.randi() % 3:
		0:
			return amulet_of_faith()
		1:
			return amulet_of_warding()
		_:
			return amulet_of_resolve()

static func random_item(rng: RandomNumberGenerator, floor_num: int = 1) -> Item:
	var roll := rng.randf()
	if roll < 0.28:
		return random_weapon(rng, floor_num)
	elif roll < 0.46:
		return random_armor(rng)
	elif roll < 0.60:
		return random_shield(rng)
	elif roll < 0.82:
		return random_consumable(rng)
	elif roll < 0.93:
		return random_ring(rng)
	else:
		return random_amulet(rng)
