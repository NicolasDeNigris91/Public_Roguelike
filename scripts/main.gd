extends Node2D

@onready var dungeon: Dungeon = $World/Dungeon
@onready var player: Player = $World/EntityLayer/Player

func _ready() -> void:
	player.dungeon = dungeon
	player.move_to(Vector2i(10, 7))
	print("Roguelike booted — Sprint 1 OK")
