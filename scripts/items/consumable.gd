class_name Consumable
extends Item

enum Effect { HEAL_MINOR, HEAL_FULL, TELEPORT }

@export var effect: int = Effect.HEAL_MINOR
@export var amount: int = 0

func use_on(target: Actor) -> bool:
	match effect:
		Effect.HEAL_MINOR, Effect.HEAL_FULL:
			return _heal(target)
		Effect.TELEPORT:
			return _teleport(target)
	return false

func _heal(target: Actor) -> bool:
	if target.hp >= target.max_hp:
		print("%s: already at full HP" % display_name)
		return false
	var before_hp: int = target.hp
	var heal_amount: int
	if effect == Effect.HEAL_FULL:
		heal_amount = target.max_hp - target.hp
	else:
		heal_amount = mini(amount, target.max_hp - target.hp)
	target.hp += heal_amount
	target.queue_redraw()
	print("Used %s — healed %d HP (%d/%d)" % [display_name, heal_amount, target.hp, target.max_hp])
	var delta := target.hp - before_hp
	if delta > 0 and Combat.effects_layer != null:
		var heal_pos: Vector2 = target.position - Vector2(0, 8)
		DamageNumber.spawn(Combat.effects_layer, heal_pos, "+%d" % delta, Combat.DMG_COLOR_HEAL, 1.0)
	return true

func _teleport(target: Actor) -> bool:
	if not (target is Player):
		return false
	var player := target as Player
	if player.dungeon == null:
		return false

	var grid := player.dungeon.grid
	var candidates: Array[Vector2i] = []
	for y in range(grid.height):
		for x in range(grid.width):
			var pos := Vector2i(x, y)
			if pos == player.grid_position:
				continue
			if grid.is_walkable(pos):
				candidates.append(pos)

	if candidates.is_empty():
		return false

	var destination: Vector2i = candidates[randi() % candidates.size()]
	player.move_to(destination, false)
	print("Used %s — teleported to %s" % [display_name, str(destination)])
	return true
