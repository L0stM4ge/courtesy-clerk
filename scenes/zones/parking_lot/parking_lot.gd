extends Node2D
class_name ParkingLotZone
## ParkingLotZone - Exterior parking area

signal zone_transition_requested(target_zone: String, spawn_point: String)
signal cart_collected(cart: Node2D)
signal all_carts_collected

var total_carts_collected: int = 0


func _ready() -> void:
	_connect_zone_transitions()
	_connect_cart_corrals()


func _connect_zone_transitions() -> void:
	var transitions := get_tree().get_nodes_in_group("zone_transition")
	for transition in transitions:
		if transition.is_inside_tree() and is_ancestor_of(transition):
			if transition.has_signal("transition_triggered"):
				transition.transition_triggered.connect(_on_transition_triggered)


func _connect_cart_corrals() -> void:
	var corrals := get_tree().get_nodes_in_group("cart_corral")
	for corral in corrals:
		if corral.is_inside_tree() and is_ancestor_of(corral):
			if corral.has_signal("cart_collected"):
				corral.cart_collected.connect(_on_cart_collected)
			if corral.has_signal("all_carts_collected"):
				corral.all_carts_collected.connect(_on_all_carts_collected)


func _on_transition_triggered(target_zone: String, spawn_point: String) -> void:
	zone_transition_requested.emit(target_zone, spawn_point)


func _on_cart_collected(cart: Node2D) -> void:
	total_carts_collected += 1
	cart_collected.emit(cart)
	print("Cart collected! Total: ", total_carts_collected)


func _on_all_carts_collected() -> void:
	all_carts_collected.emit()
	print("All carts collected!")


func get_remaining_carts() -> int:
	return get_tree().get_nodes_in_group("cart").size()


func get_total_collected() -> int:
	return total_carts_collected
