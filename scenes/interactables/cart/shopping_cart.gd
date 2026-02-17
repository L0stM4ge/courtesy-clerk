extends CharacterBody2D
class_name ShoppingCart
## ShoppingCart - A pushable cart that can be collected at corrals

signal collected(cart: ShoppingCart)
signal released_by_vehicle(cart: ShoppingCart)

@export var cart_offset: Vector2 = Vector2(0, -30.0)  # North of player

var is_grabbed: bool = false
var grabber: Node2D = null


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("cart")


func _physics_process(_delta: float) -> void:
	if is_grabbed and grabber:
		# Rigidly follow the player - no physics, just match position
		global_position = grabber.global_position + cart_offset


func interact(player: Node2D) -> void:
	if is_grabbed:
		release()
	else:
		grab(player)


func grab(player: Node2D) -> void:
	if is_grabbed:
		return

	is_grabbed = true
	grabber = player

	# Track cart reference on player
	if "grabbed_cart" in player:
		player.grabbed_cart = self

	# Visual feedback - slightly brighter when grabbed
	modulate = Color(1.2, 1.2, 1.2, 1.0)

	# Connect to player to detect when they try to interact again
	if player.has_signal("interacted_with"):
		if not player.interacted_with.is_connected(_on_player_interacted):
			player.interacted_with.connect(_on_player_interacted)


func release() -> void:
	if not is_grabbed:
		return

	if grabber and grabber.has_signal("interacted_with"):
		if grabber.interacted_with.is_connected(_on_player_interacted):
			grabber.interacted_with.disconnect(_on_player_interacted)

	# Clear cart reference on player
	if grabber and "grabbed_cart" in grabber:
		grabber.grabbed_cart = null

	is_grabbed = false
	grabber = null
	modulate = Color(1.0, 1.0, 1.0, 1.0)


func _on_player_interacted(interactable: Node2D) -> void:
	# If player interacts with something else while holding cart, release it
	if interactable != self:
		release()


func collect() -> void:
	# Called when cart enters a corral
	release()
	collected.emit(self)

	# Animate cart disappearing
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
	tween.tween_callback(queue_free)


func hit_by_vehicle() -> void:
	# Called when player/cart is hit by a vehicle - releases the cart
	if not is_grabbed:
		return

	release()
	released_by_vehicle.emit(self)
