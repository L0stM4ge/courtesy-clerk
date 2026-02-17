extends CharacterBody2D
class_name VehicleBase
## VehicleBase - Base class for all vehicles in the parking lot

signal hit_player(player: Node2D)
signal reached_turn_point(vehicle: VehicleBase)

enum Direction { LEFT, RIGHT, UP, DOWN }

@export var speed: float = 200.0
@export var direction: Direction = Direction.LEFT
@export var north_boundary: float = -280.0  # Don't go past store front

# Turn point configuration
var turn_at_y: float = -1000.0  # Y position to turn at (disabled by default)
var turn_direction: Direction = Direction.LEFT  # Direction to turn
var has_turned: bool = false

var move_direction: Vector2 = Vector2.LEFT
var is_active: bool = true


func _ready() -> void:
	add_to_group("vehicle")
	_set_move_direction()


func _physics_process(_delta: float) -> void:
	if not is_active:
		return

	# Check if we should turn (for vehicles coming up from bottom)
	if not has_turned and direction == Direction.UP:
		if global_position.y <= turn_at_y:
			_execute_turn()

	# Check north boundary - don't crash into store
	if global_position.y < north_boundary:
		if move_direction.y < 0:
			# Heading north, stop or turn
			velocity = Vector2.ZERO
			is_active = false
			return

	velocity = move_direction * speed
	move_and_slide()

	# Check for player collision
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider and collider.is_in_group("player"):
			_on_hit_player(collider)


func _execute_turn() -> void:
	has_turned = true
	# Snap to turn point Y position (align with the lane)
	global_position.y = turn_at_y
	set_direction(turn_direction)
	_rotate_to_direction(turn_direction)
	reached_turn_point.emit(self)


func _rotate_to_direction(dir: Direction) -> void:
	match dir:
		Direction.LEFT:
			rotation = PI / 2
		Direction.RIGHT:
			rotation = -PI / 2
		Direction.UP:
			rotation = 0
		Direction.DOWN:
			rotation = PI


func _set_move_direction() -> void:
	match direction:
		Direction.LEFT:
			move_direction = Vector2.LEFT
		Direction.RIGHT:
			move_direction = Vector2.RIGHT
		Direction.UP:
			move_direction = Vector2.UP
		Direction.DOWN:
			move_direction = Vector2.DOWN


func _on_hit_player(player: Node2D) -> void:
	hit_player.emit(player)
	if player.has_method("hit_by_vehicle"):
		player.hit_by_vehicle()


func set_direction(new_direction: Direction) -> void:
	direction = new_direction
	_set_move_direction()


func stop() -> void:
	is_active = false
	velocity = Vector2.ZERO


func resume() -> void:
	is_active = true
