extends Node2D
class_name BroomRack
## BroomRack - Parking spot for witches' brooms, like a bicycle rack

signal broom_parked(broom: WitchesBroom)
signal broom_departed(broom: WitchesBroom)

@export var parking_spots: int = 3

var parked_brooms: Array[WitchesBroom] = []
var spot_positions: Array[Vector2] = []


func _ready() -> void:
	add_to_group("broom_rack")
	_calculate_spot_positions()


func _calculate_spot_positions() -> void:
	# Spread spots horizontally
	var spacing := 30.0
	var total_width := spacing * (parking_spots - 1)
	var start_x := -total_width / 2

	for i in parking_spots:
		spot_positions.append(Vector2(start_x + i * spacing, 0))


func get_available_spot() -> Vector2:
	# Find first empty spot
	for i in parking_spots:
		var spot_taken := false
		var spot_pos := global_position + spot_positions[i]

		for broom in parked_brooms:
			if broom and is_instance_valid(broom):
				if broom.global_position.distance_to(spot_pos) < 15.0:
					spot_taken = true
					break

		if not spot_taken:
			return spot_pos

	# All spots taken, return center as fallback
	return global_position


func has_available_spot() -> bool:
	return parked_brooms.size() < parking_spots


func register_parked_broom(broom: WitchesBroom) -> void:
	if broom not in parked_brooms:
		parked_brooms.append(broom)
		broom_parked.emit(broom)


func unregister_broom(broom: WitchesBroom) -> void:
	parked_brooms.erase(broom)
	broom_departed.emit(broom)
