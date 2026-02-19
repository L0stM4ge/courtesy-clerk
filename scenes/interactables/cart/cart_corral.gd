extends Area2D
class_name CartCorral
## CartCorral - Collection point for shopping carts

signal cart_collected(cart: ShoppingCart)
signal all_carts_collected

@export var corral_id: String = ""

var carts_collected: int = 0


func _ready() -> void:
	add_to_group("cart_corral")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is ShoppingCart:
		_collect_cart(body as ShoppingCart)


func _collect_cart(cart: ShoppingCart) -> void:
	if not cart.is_grabbed:
		# Only collect carts that are being pushed by the player
		return

	# Release and collect the cart
	cart.release()
	cart.remove_from_group("cart")
	carts_collected += 1
	cart_collected.emit(cart)

	# Visual feedback on corral
	_show_collect_feedback()

	# Animate cart into corral
	var tween := create_tween()
	tween.tween_property(cart, "global_position", global_position, 0.2)
	tween.tween_property(cart, "scale", Vector2(0.5, 0.5), 0.2)
	tween.tween_callback(cart.queue_free)

	# Check if all carts in the zone are collected
	await get_tree().process_frame
	_check_all_collected()


func _show_collect_feedback() -> void:
	# Flash the corral border
	var border := get_node_or_null("CorralBorder")
	if border and border is ColorRect:
		var original_color: Color = border.color
		border.color = Color(0.2, 0.9, 0.2, 1)  # Green flash

		var tween := create_tween()
		tween.tween_property(border, "color", original_color, 0.5)


func _check_all_collected() -> void:
	var remaining_carts := get_tree().get_nodes_in_group("cart")
	if remaining_carts.is_empty():
		all_carts_collected.emit()


func get_carts_collected() -> int:
	return carts_collected
