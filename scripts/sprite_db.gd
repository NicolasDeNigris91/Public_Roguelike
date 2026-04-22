class_name SpriteDB

const _ACTORS := {
	"player":   preload("res://assets/sprites/actors/player.png"),
	"slime":    preload("res://assets/sprites/actors/slime.png"),
	"skeleton": preload("res://assets/sprites/actors/skeleton.png"),
	"archer":   preload("res://assets/sprites/actors/archer.png"),
	"mage":     preload("res://assets/sprites/actors/mage.png"),
	"lich":     preload("res://assets/sprites/actors/lich.png"),
}

const _ITEMS := {
	"short_sword":     preload("res://assets/sprites/items/short_sword.png"),
	"long_sword":      preload("res://assets/sprites/items/long_sword.png"),
	"axe":             preload("res://assets/sprites/items/axe.png"),
	"hammer":          preload("res://assets/sprites/items/hammer.png"),
	"dagger":          preload("res://assets/sprites/items/dagger.png"),
	"leather_armor":   preload("res://assets/sprites/items/leather_armor.png"),
	"chain_mail":      preload("res://assets/sprites/items/leather_armor.png"),
	"plate_armor":     preload("res://assets/sprites/items/plate_armor.png"),
	"healing_potion":  preload("res://assets/sprites/items/healing_potion.png"),
	"greater_potion":  preload("res://assets/sprites/items/greater_potion.png"),
	"teleport_scroll": preload("res://assets/sprites/items/teleport_scroll.png"),
	"ring_of_life":    preload("res://assets/sprites/items/ring_of_life.png"),
}

const _TILES := {
	"floor":       preload("res://assets/tiles/floor.png"),
	"wall":        preload("res://assets/tiles/wall.png"),
	"stairs_down": preload("res://assets/tiles/stairs_down.png"),
	"floor_n":     preload("res://assets/tiles/floor_borders/floor_n.png"),
	"floor_s":     preload("res://assets/tiles/floor_borders/floor_s.png"),
	"floor_e":     preload("res://assets/tiles/floor_borders/floor_e.png"),
	"floor_w":     preload("res://assets/tiles/floor_borders/floor_w.png"),
	"floor_ne":    preload("res://assets/tiles/floor_borders/floor_ne.png"),
	"floor_nw":    preload("res://assets/tiles/floor_borders/floor_nw.png"),
	"floor_se":    preload("res://assets/tiles/floor_borders/floor_se.png"),
	"floor_sw":    preload("res://assets/tiles/floor_borders/floor_sw.png"),
}

static func actor(key: String) -> Texture2D:
	return _ACTORS[key]

static func item(key: String) -> Texture2D:
	return _ITEMS[key]

static func tile(key: String) -> Texture2D:
	return _TILES[key]
