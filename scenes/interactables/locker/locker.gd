extends StaticBody2D
class_name Locker
## Locker - Player's locker serves as the save point

signal save_triggered

@export var is_player_locker: bool = false

@onready var visual: ColorRect = $Visual
@onready var interaction_area: Area2D = $InteractionArea


func _ready() -> void:
	add_to_group("interactable")

	if is_player_locker:
		# Make player's locker visually distinct
		visual.color = Color(0.3, 0.5, 0.7, 1)  # Blue tint
	else:
		visual.color = Color(0.5, 0.5, 0.55, 1)  # Gray


func interact(player: Node2D) -> void:
	if not is_player_locker:
		# Other lockers don't do anything
		print("This isn't your locker.")
		return

	# Player's locker triggers save
	_save_game(player)


func _save_game(player: Node2D) -> void:
	# Update save data with current position
	SaveManager.current_data.player_position = player.global_position
	SaveManager.current_data.current_zone = GameManager.current_zone

	if SaveManager.save_game():
		save_triggered.emit()
		_show_save_feedback()
	else:
		print("Failed to save game!")


func _show_save_feedback() -> void:
	# Flash the locker to indicate save
	var original_color := visual.color
	visual.color = Color(0.5, 0.8, 0.5, 1)  # Green flash

	var tween := create_tween()
	tween.tween_property(visual, "color", original_color, 0.5)

	print("Game Saved!")
