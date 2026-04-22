class_name Consumable
extends Item

enum Effect { HEAL_MINOR, HEAL_FULL, TELEPORT }

@export var effect: int = Effect.HEAL_MINOR
@export var amount: int = 0

func use_on(target: Actor) -> bool:
	match effect:
		Effect.HEAL_MINOR, Effect.HEAL_FULL:
			if target.hp >= target.max_hp:
				print("%s: already at full HP" % display_name)
				return false
			var heal_amount: int
			if effect == Effect.HEAL_FULL:
				heal_amount = target.max_hp - target.hp
			else:
				heal_amount = mini(amount, target.max_hp - target.hp)
			target.hp += heal_amount
			target.queue_redraw()
			print("Used %s — healed %d HP (%d/%d)" % [display_name, heal_amount, target.hp, target.max_hp])
			return true
		Effect.TELEPORT:
			return false
	return false
