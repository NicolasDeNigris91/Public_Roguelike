extends CanvasLayer
# Permanent bottom hotbar. No class_name to avoid autoload-style collisions
# and because the scene-root identity is sufficient for external refs.

signal consumable_used(slot_idx: int)

const MAX_FLOOR: int = 6

var player: Player
var current_floor: int = 1

@onready var status_container: HBoxContainer = $PanelContainer/MarginContainer/HBoxContainer/StatusContainer
@onready var equipped_container: HBoxContainer = $PanelContainer/MarginContainer/HBoxContainer/EquippedContainer
@onready var bag_container: HBoxContainer = $PanelContainer/MarginContainer/HBoxContainer/BagContainer

func _ready() -> void:
	layer = 5

func refresh() -> void:
	# Populated in Tasks 3-5.
	pass

func use_consumable_slot(idx: int) -> void:
	if player == null:
		return
	if idx < 0 or idx >= player.inventory.bag.size():
		return
	var item: Item = player.inventory.bag[idx]
	if not (item is Consumable):
		return
	consumable_used.emit(idx)
