extends Node
## SaveManager - Handles save/load functionality

signal save_completed
signal load_completed

const SAVE_PATH := "user://save.dat"

var current_data: SaveData = null


func _ready() -> void:
	current_data = SaveData.new()


func create_new_save() -> void:
	current_data = SaveData.new()
	current_data.current_zone = "store"
	current_data.spawn_point = "default"
	current_data.player_position = Vector2.ZERO


func save_game() -> bool:
	current_data.save_timestamp = Time.get_unix_time_from_system()

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file for writing: %s" % FileAccess.get_open_error())
		return false

	var data := current_data.to_dict()
	file.store_var(data)
	file.close()

	save_completed.emit()
	print("Game saved successfully")
	return true


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		push_error("Save file does not exist")
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open save file for reading: %s" % FileAccess.get_open_error())
		return false

	var data: Dictionary = file.get_var()
	file.close()

	current_data = SaveData.new()
	current_data.from_dict(data)

	load_completed.emit()
	print("Game loaded successfully")
	return true


func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
