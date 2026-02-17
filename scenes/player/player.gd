extends CharacterBody2D
class_name Player
## Player - The zombie grocery bagger controlled by the player

signal interacted_with(interactable: Node2D)

@export var move_speed: float = 150.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var camera: Camera2D = $Camera2D

var facing_direction: Vector2 = Vector2.DOWN
var interactables_in_range: Array[Node2D] = []
var can_move: bool = true


func _ready() -> void:
	add_to_group("player")
	interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area.body_exited.connect(_on_interaction_area_body_exited)
	interaction_area.area_entered.connect(_on_interaction_area_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_area_exited)

	# Register with GameManager
	GameManager.player = self


func _physics_process(_delta: float) -> void:
	if not can_move or GameManager.is_in_dialogue():
		velocity = Vector2.ZERO
		return

	_handle_movement()
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not GameManager.is_in_dialogue():
		_try_interact()


func _handle_movement() -> void:
	var input_direction := Vector2.ZERO

	input_direction.x = Input.get_axis("move_left", "move_right")
	input_direction.y = Input.get_axis("move_up", "move_down")

	if input_direction != Vector2.ZERO:
		input_direction = input_direction.normalized()
		facing_direction = input_direction
		_update_sprite_direction()

	velocity = input_direction * move_speed


func _update_sprite_direction() -> void:
	# Placeholder: flip sprite based on horizontal direction
	if facing_direction.x < 0:
		sprite.flip_h = true
	elif facing_direction.x > 0:
		sprite.flip_h = false


func _try_interact() -> void:
	if interactables_in_range.is_empty():
		return

	# Get the closest interactable
	var closest: Node2D = _get_closest_interactable()
	if closest and closest.has_method("interact"):
		closest.interact(self)
		interacted_with.emit(closest)


func _get_closest_interactable() -> Node2D:
	var closest: Node2D = null
	var closest_dist: float = INF

	for interactable in interactables_in_range:
		var dist := global_position.distance_to(interactable.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = interactable

	return closest


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("interactable") and body not in interactables_in_range:
		interactables_in_range.append(body)


func _on_interaction_area_body_exited(body: Node2D) -> void:
	interactables_in_range.erase(body)


func _on_interaction_area_area_entered(area: Area2D) -> void:
	var parent := area.get_parent()
	if parent.is_in_group("interactable") and parent not in interactables_in_range:
		interactables_in_range.append(parent)
	elif area.is_in_group("interactable") and area not in interactables_in_range:
		interactables_in_range.append(area)


func _on_interaction_area_area_exited(area: Area2D) -> void:
	var parent := area.get_parent()
	interactables_in_range.erase(parent)
	interactables_in_range.erase(area)


func set_position_to_spawn(spawn_marker: Marker2D) -> void:
	global_position = spawn_marker.global_position


func enable_movement() -> void:
	can_move = true


func disable_movement() -> void:
	can_move = false
	velocity = Vector2.ZERO
