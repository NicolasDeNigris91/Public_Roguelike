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

static func random_item(rng: RandomNumberGenerator) -> Item:
	if rng.randf() < 0.5:
		return random_weapon(rng)
	return random_armor(rng)
