class_name ItemDB

static func short_sword() -> Weapon:
	var w := Weapon.new()
	w.display_name = "Short Sword"
	w.color = Color("#c0c0c0")
	w.atk_bonus = 1
	return w

static func axe() -> Weapon:
	var w := Weapon.new()
	w.display_name = "Axe"
	w.color = Color("#b07050")
	w.atk_bonus = 3
	return w

static func dagger() -> Weapon:
	var w := Weapon.new()
	w.display_name = "Dagger"
	w.color = Color("#8890a0")
	w.atk_bonus = 0
	return w

static func leather_armor() -> Armor:
	var a := Armor.new()
	a.display_name = "Leather Armor"
	a.color = Color("#7a4f2a")
	a.def_bonus = 1
	return a

static func chain_mail() -> Armor:
	var a := Armor.new()
	a.display_name = "Chain Mail"
	a.color = Color("#9ea0a8")
	a.def_bonus = 2
	return a

static func healing_potion() -> Consumable:
	var c := Consumable.new()
	c.display_name = "Healing Potion"
	c.color = Color("#d64545")
	c.effect = Consumable.Effect.HEAL_MINOR
	c.amount = 10
	return c

static func greater_potion() -> Consumable:
	var c := Consumable.new()
	c.display_name = "Greater Potion"
	c.color = Color("#e040b0")
	c.effect = Consumable.Effect.HEAL_FULL
	return c

static func random_weapon(rng: RandomNumberGenerator) -> Weapon:
	match rng.randi() % 3:
		0:
			return short_sword()
		1:
			return axe()
		_:
			return dagger()

static func random_armor(rng: RandomNumberGenerator) -> Armor:
	if rng.randi() % 2 == 0:
		return leather_armor()
	return chain_mail()

static func random_consumable(rng: RandomNumberGenerator) -> Consumable:
	if rng.randf() < 0.7:
		return healing_potion()
	return greater_potion()

static func random_item(rng: RandomNumberGenerator) -> Item:
	var roll := rng.randf()
	if roll < 0.4:
		return random_weapon(rng)
	elif roll < 0.7:
		return random_armor(rng)
	else:
		return random_consumable(rng)
