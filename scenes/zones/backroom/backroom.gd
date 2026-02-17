extends Node2D
class_name BackroomZone
## BackroomZone - Storage, break room, and lockers

signal zone_transition_requested(target_zone: String, spawn_point: String)


func _ready() -> void:
	_connect_zone_transitions()


func _connect_zone_transitions() -> void:
	var transitions := get_tree().get_nodes_in_group("zone_transition")
	for transition in transitions:
		if transition.is_inside_tree() and is_ancestor_of(transition):
			if transition.has_signal("transition_triggered"):
				transition.transition_triggered.connect(_on_transition_triggered)


func _on_transition_triggered(target_zone: String, spawn_point: String) -> void:
	zone_transition_requested.emit(target_zone, spawn_point)
