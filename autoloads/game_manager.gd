extends Node
## GameManager - Handles game state and scene transitions

signal zone_changed(zone_name: String)
signal game_started
signal game_loaded

enum GameState { TITLE, PLAYING, PAUSED, DIALOGUE }

var current_state: GameState = GameState.TITLE
var current_zone: String = ""
var player: CharacterBody2D = null

const GAME_SCENE_PATH := "res://scenes/game/game.tscn"


func start_new_game() -> void:
	SaveManager.create_new_save()
	_load_game_scene()
	game_started.emit()


func continue_game() -> void:
	if SaveManager.load_game():
		_load_game_scene()
		game_loaded.emit()


func _load_game_scene() -> void:
	current_state = GameState.PLAYING
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


func change_zone(zone_name: String, spawn_point: String = "default") -> void:
	current_zone = zone_name
	SaveManager.current_data.current_zone = zone_name
	SaveManager.current_data.spawn_point = spawn_point
	zone_changed.emit(zone_name)


func return_to_title() -> void:
	current_state = GameState.TITLE
	get_tree().change_scene_to_file("res://scenes/title/title.tscn")


func set_state(new_state: GameState) -> void:
	current_state = new_state


func is_playing() -> bool:
	return current_state == GameState.PLAYING


func is_in_dialogue() -> bool:
	return current_state == GameState.DIALOGUE
