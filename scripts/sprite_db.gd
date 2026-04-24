class_name SpriteDB

const _ACTORS := {
	"player":       preload("res://assets/sprites/actors/player.png"),
	"slime":        preload("res://assets/sprites/actors/slime.png"),
	"skeleton":     preload("res://assets/sprites/actors/skeleton.png"),
	"archer":       preload("res://assets/sprites/actors/archer.png"),
	"mage":         preload("res://assets/sprites/actors/mage.png"),
	"lich":         preload("res://assets/sprites/actors/lich.png"),
	"wraith":       preload("res://assets/sprites/actors/wraith.png"),
	"necrophage":   preload("res://assets/sprites/actors/necrophage.png"),
	"death_knight": preload("res://assets/sprites/actors/death_knight.png"),
	"flayed_ghost": preload("res://assets/sprites/actors/flayed_ghost.png"),
	"rotting_hulk": preload("res://assets/sprites/actors/rotting_hulk.png"),
	"abomination":  preload("res://assets/sprites/actors/abomination.png"),
	"imp":          preload("res://assets/sprites/actors/imp.png"),
	"hell_hound":   preload("res://assets/sprites/actors/hell_hound.png"),
	"salamander":   preload("res://assets/sprites/actors/salamander.png"),
	"fire_giant":   preload("res://assets/sprites/actors/fire_giant.png"),
	"hellwing":     preload("res://assets/sprites/actors/hellwing.png"),
	"executioner":  preload("res://assets/sprites/actors/executioner.png"),
	"demon_lord":   preload("res://assets/sprites/actors/demon_lord.png"),
}

const _ITEMS := {
	"short_sword":     preload("res://assets/sprites/items/short_sword.png"),
	"long_sword":      preload("res://assets/sprites/items/long_sword.png"),
	"axe":             preload("res://assets/sprites/items/axe.png"),
	"hammer":          preload("res://assets/sprites/items/hammer.png"),
	"dagger":          preload("res://assets/sprites/items/dagger.png"),
	"ancient_sword":   preload("res://assets/sprites/items/ancient_sword.png"),
	"scythe_of_curses":preload("res://assets/sprites/items/scythe_of_curses.png"),
	"sword_of_cerebov":preload("res://assets/sprites/items/sword_of_cerebov.png"),
	"demon_blade":     preload("res://assets/sprites/items/demon_blade.png"),
	"leather_armor":   preload("res://assets/sprites/items/leather_armor.png"),
	"chain_mail":      preload("res://assets/sprites/items/leather_armor.png"),
	"plate_armor":     preload("res://assets/sprites/items/plate_armor.png"),
	"banded_mail":     preload("res://assets/sprites/items/banded_mail.png"),
	"crystal_plate":   preload("res://assets/sprites/items/crystal_plate.png"),
	"dragon_plate":    preload("res://assets/sprites/items/dragon_plate.png"),
	"healing_potion":  preload("res://assets/sprites/items/healing_potion.png"),
	"greater_potion":  preload("res://assets/sprites/items/greater_potion.png"),
	"teleport_scroll": preload("res://assets/sprites/items/teleport_scroll.png"),
	"ring_of_life":        preload("res://assets/sprites/items/ring_of_life.png"),
	"ring_of_strength":    preload("res://assets/sprites/items/ring_of_strength.png"),
	"ring_of_protection":  preload("res://assets/sprites/items/ring_of_protection.png"),
	"ring_of_vitality":    preload("res://assets/sprites/items/ring_of_vitality.png"),
	"amulet_of_faith":     preload("res://assets/sprites/items/amulet_of_faith.png"),
	"amulet_of_warding":   preload("res://assets/sprites/items/amulet_of_warding.png"),
	"amulet_of_resolve":   preload("res://assets/sprites/items/amulet_of_resolve.png"),
	"potion_of_strength":   preload("res://assets/sprites/items/potion_of_strength.png"),
	"potion_of_resistance": preload("res://assets/sprites/items/potion_of_resistance.png"),
	"buckler":         preload("res://assets/sprites/items/buckler.png"),
	"kite_shield":     preload("res://assets/sprites/items/kite_shield.png"),
	"tower_shield":    preload("res://assets/sprites/items/tower_shield.png"),
	"aegis":           preload("res://assets/sprites/items/aegis.png"),
	"ember_shield":    preload("res://assets/sprites/items/ember_shield.png"),
	"infernal_aegis":  preload("res://assets/sprites/items/infernal_aegis.png"),
}

const _EFFECTS := {
	"magic_bolt":     preload("res://assets/sprites/effects/magic_bolt.png"),
	"searing_burst":  preload("res://assets/sprites/effects/searing_burst.png"),
	"necro_bolt":     preload("res://assets/sprites/effects/necro_bolt.png"),
	"gloom":          preload("res://assets/sprites/effects/gloom.png"),
}

const _ARROW_FRAMES: Array = [
	preload("res://assets/sprites/effects/arrow/arrow_0.png"),
	preload("res://assets/sprites/effects/arrow/arrow_1.png"),
	preload("res://assets/sprites/effects/arrow/arrow_2.png"),
	preload("res://assets/sprites/effects/arrow/arrow_3.png"),
	preload("res://assets/sprites/effects/arrow/arrow_4.png"),
	preload("res://assets/sprites/effects/arrow/arrow_5.png"),
	preload("res://assets/sprites/effects/arrow/arrow_6.png"),
	preload("res://assets/sprites/effects/arrow/arrow_7.png"),
]

const _CRYSTAL_SPEAR_FRAMES: Array = [
	preload("res://assets/sprites/effects/crystal_spear/crystal_spear_0.png"),
	preload("res://assets/sprites/effects/crystal_spear/crystal_spear_1.png"),
	preload("res://assets/sprites/effects/crystal_spear/crystal_spear_2.png"),
	preload("res://assets/sprites/effects/crystal_spear/crystal_spear_3.png"),
	preload("res://assets/sprites/effects/crystal_spear/crystal_spear_4.png"),
	preload("res://assets/sprites/effects/crystal_spear/crystal_spear_5.png"),
	preload("res://assets/sprites/effects/crystal_spear/crystal_spear_6.png"),
	preload("res://assets/sprites/effects/crystal_spear/crystal_spear_7.png"),
]

const _TILES := {
	"floor":            preload("res://assets/tiles/floor.png"),
	"wall":             preload("res://assets/tiles/wall.png"),
	"floor_catacombs":      preload("res://assets/tiles/floor_catacombs.png"),
	"wall_catacombs":       preload("res://assets/tiles/wall_catacombs.png"),
	"floor_blood_sanctum":  preload("res://assets/tiles/floor_blood_sanctum.png"),
	"wall_blood_sanctum":   preload("res://assets/tiles/wall_blood_sanctum.png"),
	"floor_burning_halls":    preload("res://assets/tiles/floor_burning_halls.png"),
	"wall_burning_halls":     preload("res://assets/tiles/wall_burning_halls.png"),
	"floor_infernal_throne":  preload("res://assets/tiles/floor_infernal_throne.png"),
	"wall_infernal_throne":   preload("res://assets/tiles/wall_infernal_throne.png"),
	"stairs_down":      preload("res://assets/tiles/stairs_down.png"),
	"floor_n":          preload("res://assets/tiles/floor_borders/floor_n.png"),
	"floor_s":          preload("res://assets/tiles/floor_borders/floor_s.png"),
	"floor_e":          preload("res://assets/tiles/floor_borders/floor_e.png"),
	"floor_w":          preload("res://assets/tiles/floor_borders/floor_w.png"),
	"floor_ne":         preload("res://assets/tiles/floor_borders/floor_ne.png"),
	"floor_nw":         preload("res://assets/tiles/floor_borders/floor_nw.png"),
	"floor_se":         preload("res://assets/tiles/floor_borders/floor_se.png"),
	"floor_sw":         preload("res://assets/tiles/floor_borders/floor_sw.png"),
}

static func actor(key: String) -> Texture2D:
	return _ACTORS[key]

static func item(key: String) -> Texture2D:
	return _ITEMS[key]

static func tile(key: String) -> Texture2D:
	return _TILES[key]

static func effect(key: String) -> Texture2D:
	return _EFFECTS[key]

static func arrow_frames() -> Array:
	return _ARROW_FRAMES

static func crystal_spear_frames() -> Array:
	return _CRYSTAL_SPEAR_FRAMES
