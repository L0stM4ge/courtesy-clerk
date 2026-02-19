extends Area2D
class_name ZoneTransition
## ZoneTransition - Triggers zone changes when player enters

signal transition_triggered(target_zone: String, spawn_point: String)

@export var target_zone: String = ""
@export var spawn_point: String = "default"
@export var auto_transition: bool = true  # Transition immediately on contact
@export var transition_delay: float = 0.0


func _ready() -> void:
	add_to_group("zone_transition")
	body_entered.connect(_on_body_entered)

	if not auto_transition:
		add_to_group("interactable")


func _on_body_entered(body: Node2D) -> void:
	if not auto_transition:
		return

	if body.is_in_group("player"):
		_do_transition()


func interact(_player: Node2D) -> void:
	if not auto_transition:
		_do_transition()


func _do_transition() -> void:
	if transition_delay > 0:
		await get_tree().create_timer(transition_delay).timeout

	transition_triggered.emit(target_zone, spawn_point)
