extends Node2D

@onready var dungeon: Dungeon = $World/Dungeon
@onready var entity_layer: Node2D = $World/EntityLayer
@onready var player: Player = $World/EntityLayer/Player
@onready var turn_manager: TurnManager = $TurnManager

func _ready() -> void:
	player.dungeon = dungeon
	player.turn_manager = turn_manager
	player.died.connect(_on_player_died)
	turn_manager.register_player(player)

	if dungeon.rooms.size() >= 1:
		player.move_to(dungeon.room_center(0))
	if dungeon.rooms.size() >= 2:
		_spawn_slime(dungeon.room_center(1))

	print("Roguelike booted — Sprint 3a OK (%d rooms)" % dungeon.rooms.size())

func _spawn_slime(at: Vector2i) -> void:
	var slime := Slime.new()
	entity_layer.add_child(slime)
	slime.dungeon = dungeon
	slime.turn_manager = turn_manager
	slime.move_to(at)
	turn_manager.register_enemy(slime)

func _on_player_died() -> void:
	print("You died")
