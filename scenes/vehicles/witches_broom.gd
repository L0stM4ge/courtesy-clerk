extends CharacterBody2D
class_name WitchesBroom
## WitchesBroom - Flying broom that comes from odd angles to park at the broom rack

signal hit_player(player: Node2D)
signal landed
signal took_off

enum State { FLYING, LANDING, PARKED, TAKING_OFF }

@export var flight_speed: float = 200.0
@export var landing_speed: float = 80.0

var current_state: State = State.FLYING
var target_position: Vector2 = Vector2.ZERO
var flight_direction: Vector2 = Vector2.ZERO
var parking_spot: Node2D = null


func _ready() -> void:
	add_to_group("vehicle")
	add_to_group("witches_broom")


func _physics_process(_delta: float) -> void:
	match current_state:
		State.FLYING:
			_process_flying()
		State.LANDING:
			_process_landing()
		State.PARKED:
			pass  # Stay still
		State.TAKING_OFF:
			_process_taking_off()

	# Check for player collision while moving
	if current_state != State.PARKED:
		for i in get_slide_collision_count():
			var collision := get_slide_collision(i)
			var collider := collision.get_collider()
			if collider and collider.is_in_group("player"):
				_on_hit_player(collider)


func _process_flying() -> void:
	velocity = flight_direction * flight_speed
	move_and_slide()


func _process_landing() -> void:
	var direction := (target_position - global_position)
	if direction.length() < 5.0:
		# Arrived at parking spot
		global_position = target_position
		velocity = Vector2.ZERO
		current_state = State.PARKED
		landed.emit()
		_rotate_to_parked()
	else:
		velocity = direction.normalized() * landing_speed
		# Rotate to face movement direction
		rotation = velocity.angle() + PI / 2
		move_and_slide()


func _process_taking_off() -> void:
	velocity = flight_direction * flight_speed
	move_and_slide()


func _rotate_to_parked() -> void:
	# Point upward when parked (handle facing up)
	rotation = 0


func fly_in_from_angle(start_pos: Vector2, direction: Vector2) -> void:
	global_position = start_pos
	flight_direction = direction.normalized()
	rotation = flight_direction.angle() + PI / 2
	current_state = State.FLYING


func start_landing(target: Vector2, spot: Node2D = null) -> void:
	target_position = target
	parking_spot = spot
	current_state = State.LANDING


func take_off(direction: Vector2) -> void:
	flight_direction = direction.normalized()
	rotation = flight_direction.angle() + PI / 2
	current_state = State.TAKING_OFF
	took_off.emit()


func _on_hit_player(player: Node2D) -> void:
	hit_player.emit(player)
	if player.has_method("hit_by_vehicle"):
		player.hit_by_vehicle()
