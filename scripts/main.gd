extends Node2D

@onready var dungeon: Dungeon = $World/Dungeon
@onready var entity_layer: Node2D = $World/EntityLayer
@onready var player: Player = $World/EntityLayer/Player
@onready var turn_manager: TurnManager = $TurnManager

func _ready() -> void:
	player.dungeon = dungeon
	player.turn_manager = turn_manager
	player.move_to(Vector2i(10, 7))
	player.died.connect(_on_player_died)
	turn_manager.register_player(player)

	_spawn_slime(Vector2i(14, 7))

	print("Roguelike booted — Sprint 2 OK")

func _spawn_slime(at: Vector2i) -> void:
	var slime := Slime.new()
	entity_layer.add_child(slime)
	slime.dungeon = dungeon
	slime.turn_manager = turn_manager
	slime.move_to(at)
	turn_manager.register_enemy(slime)

func _on_player_died() -> void:
	print("You died")
