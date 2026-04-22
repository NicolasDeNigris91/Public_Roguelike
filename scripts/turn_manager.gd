class_name TurnManager
extends Node

signal turn_changed(is_player_turn: bool)

var dungeon: Dungeon
var player: Player
var enemies: Array[Enemy] = []
var is_player_turn: bool = true

func register_player(p: Player) -> void:
	player = p
	p.turn_done.connect(_on_player_turn_done)

func register_enemy(e: Enemy) -> void:
	enemies.append(e)
	e.died.connect(_on_enemy_died.bind(e))

func _on_player_turn_done() -> void:
	player.turn_active = false
	is_player_turn = false
	turn_changed.emit(false)

	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy):
			continue
		if dungeon != null and not enemy.always_takes_turn and not dungeon.is_tile_visible(enemy.grid_position):
			continue
		enemy.take_turn()

	is_player_turn = true
	if is_instance_valid(player):
		player.turn_active = true
	turn_changed.emit(true)

func _on_enemy_died(e: Enemy) -> void:
	enemies.erase(e)
