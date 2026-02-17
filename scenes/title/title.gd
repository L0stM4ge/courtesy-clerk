extends Control

@onready var play_button: Button = $ButtonContainer/PlayButton
@onready var new_game_button: Button = $ButtonContainer/NewGameButton
@onready var select_file_button: Button = $ButtonContainer/SelectFileButton
@onready var options_button: Button = $ButtonContainer/OptionsButton
@onready var exit_button: Button = $ButtonContainer/ExitButton


func _ready() -> void:
	_connect_signals()
	_update_play_button()


func _connect_signals() -> void:
	play_button.pressed.connect(_on_play_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	select_file_button.pressed.connect(_on_select_file_pressed)
	options_button.pressed.connect(_on_options_pressed)
	exit_button.pressed.connect(_on_exit_pressed)


func _update_play_button() -> void:
	play_button.disabled = not SaveManager.has_save_file()


func _on_play_pressed() -> void:
	GameManager.continue_game()


func _on_new_game_pressed() -> void:
	GameManager.start_new_game()


func _on_select_file_pressed() -> void:
	# TODO: Open save file selection menu
	print("Select file menu")


func _on_options_pressed() -> void:
	# TODO: Open options menu
	print("Options menu")


func _on_exit_pressed() -> void:
	get_tree().quit()
