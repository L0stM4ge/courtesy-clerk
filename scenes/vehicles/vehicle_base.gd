extends CharacterBody2D
class_name VehicleBase
## VehicleBase - Base class for all vehicles in the parking lot

signal hit_player(player: Node2D)
signal reached_turn_point(vehicle: VehicleBase)

enum Direction { LEFT, RIGHT, UP, DOWN }
enum ParkingState { NONE, DRIVING_TO_AISLE, DRIVING_DOWN_AISLE,
	PARKING_TWEEN, PARKED, BACKING_OUT_TWEEN,
	DRIVING_TO_EXIT_LANE, EXITING }

@export var speed: float = 200.0
@export var direction: Direction = Direction.LEFT
@export var north_boundary: float = -280.0  # Don't go past store front

# Turn point configuration
var turn_at_y: float = -1000.0  # Y position to turn at (disabled by default)
var turn_direction: Direction = Direction.LEFT  # Direction to turn
var has_turned: bool = false

var move_direction: Vector2 = Vector2.LEFT
var is_active: bool = true

# Traffic following
const FOLLOW_DISTANCE := 70.0  # How far ahead to detect vehicles
const MIN_GAP := 40.0  # Stop if closer than this

# Parking state
var parking_state: ParkingState = ParkingState.NONE
var parking_spot_index: int = -1
var parking_target: Vector2 = Vector2.ZERO
var parking_facing: Direction = Direction.RIGHT
var parking_aisle_x: float = 0.0
var parking_row_y: float = 0.0
var parking_manager: Node2D = null  # ParkingManager reference
var parked_timer: float = 0.0
var parked_duration: float = 0.0


func _ready() -> void:
	add_to_group("vehicle")
	_set_move_direction()


func _physics_process(delta: float) -> void:
	if not is_active:
		if parking_state == ParkingState.PARKED:
			_process_parked(delta)
		return

	match parking_state:
		ParkingState.NONE:
			_process_normal_driving()
		ParkingState.DRIVING_TO_AISLE:
			_process_driving_to_aisle()
		ParkingState.DRIVING_DOWN_AISLE:
			_process_driving_down_aisle()
		ParkingState.DRIVING_TO_EXIT_LANE:
			_process_driving_to_exit_lane()
		ParkingState.EXITING:
			_process_normal_driving()


func _get_following_speed() -> float:
	if move_direction == Vector2.ZERO:
		return speed

	var my_pos := global_position
	var ahead_dir := move_direction
	var perp_dir := ahead_dir.orthogonal()
	var closest_ahead := FOLLOW_DISTANCE
	var leader_speed := speed

	for v in get_tree().get_nodes_in_group("vehicle"):
		if v == self or not is_instance_valid(v):
			continue

		var diff: Vector2 = v.global_position - my_pos

		# Must be ahead of us
		var ahead_dot: float = diff.dot(ahead_dir)
		if ahead_dot <= 0.0:
			continue

		# Must be in our lane (small perpendicular distance)
		if absf(diff.dot(perp_dir)) > 30.0:
			continue

		if ahead_dot < closest_ahead:
			closest_ahead = ahead_dot
			if v is VehicleBase:
				leader_speed = (v as VehicleBase).velocity.length()
			else:
				leader_speed = 0.0

	if closest_ahead <= MIN_GAP:
		return 0.0
	elif closest_ahead < FOLLOW_DISTANCE:
		var t := (closest_ahead - MIN_GAP) / (FOLLOW_DISTANCE - MIN_GAP)
		return lerpf(leader_speed, speed, t)

	return speed


func _process_normal_driving() -> void:
	# Check if we should turn (for vehicles coming up from bottom)
	if not has_turned and direction == Direction.UP:
		if global_position.y <= turn_at_y:
			_execute_turn()

	# Check north boundary - don't crash into store
	if global_position.y < north_boundary:
		if move_direction.y < 0:
			velocity = Vector2.ZERO
			is_active = false
			return

	velocity = move_direction * _get_following_speed()
	move_and_slide()
	_check_player_collisions()


func _process_driving_to_aisle() -> void:
	# Driving RIGHT along bottom lane until reaching aisle_x
	velocity = Vector2.RIGHT * _get_following_speed()
	move_and_slide()
	_check_player_collisions()

	if global_position.x >= parking_aisle_x:
		# Snap to aisle and turn down
		global_position.x = parking_aisle_x
		parking_state = ParkingState.DRIVING_DOWN_AISLE
		set_direction(Direction.DOWN)
		_rotate_to_direction(Direction.DOWN)


func _process_driving_down_aisle() -> void:
	# Driving DOWN the yellow lane until reaching the spot's row_y
	velocity = Vector2.DOWN * _get_following_speed()
	move_and_slide()
	_check_player_collisions()

	if global_position.y >= parking_row_y:
		# Snap to row and begin parking tween
		global_position.y = parking_row_y
		velocity = Vector2.ZERO
		is_active = false
		_start_parking_tween()


func _process_driving_to_exit_lane() -> void:
	# Driving UP the yellow lane to reach horizontal lane
	velocity = Vector2.UP * _get_following_speed()
	move_and_slide()
	_check_player_collisions()

	# Check if we reached the bottom horizontal lane (y=-175)
	if global_position.y <= -175.0:
		global_position.y = -175.0
		# Pick random exit: RIGHT on bottom lane, or continue to top lane
		var go_top := randf() > 0.5
		if go_top:
			# Continue up to top lane, then go LEFT
			turn_at_y = -225.0
			turn_direction = Direction.LEFT
			has_turned = false
			set_direction(Direction.UP)
			_rotate_to_direction(Direction.UP)
			parking_state = ParkingState.EXITING
		else:
			# Join bottom lane going RIGHT
			set_direction(Direction.RIGHT)
			_rotate_to_direction(Direction.RIGHT)
			parking_state = ParkingState.EXITING


func _process_parked(delta: float) -> void:
	parked_timer -= delta
	if parked_timer <= 0.0:
		_start_backing_out()


func _start_parking_tween() -> void:
	parking_state = ParkingState.PARKING_TWEEN
	_set_collision_enabled(false)

	var tween := create_tween()
	tween.set_parallel(true)

	# Tween duration scales with distance (vehicle is on yellow lane, tweening to spot)
	var park_dist := global_position.distance_to(parking_target)
	var park_duration := maxf(0.8, park_dist / 120.0)

	# Tween position into the spot
	tween.tween_property(self, "global_position", parking_target, park_duration) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)

	# Tween rotation to face the parking direction
	var target_rot: float
	match parking_facing:
		Direction.LEFT:
			target_rot = PI / 2
		Direction.RIGHT:
			target_rot = -PI / 2
		_:
			target_rot = 0.0

	# Avoid 270-degree sweep: when going from DOWN (PI) to RIGHT (-PI/2),
	# use equivalent angle (3*PI/2 mapped appropriately)
	var current_rot := rotation
	# Normalize to find shortest path
	var diff := target_rot - current_rot
	while diff > PI:
		diff -= TAU
	while diff < -PI:
		diff += TAU
	var adjusted_target := current_rot + diff

	tween.tween_property(self, "rotation", adjusted_target, park_duration) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)

	tween.finished.connect(_on_parking_tween_finished)


func _on_parking_tween_finished() -> void:
	parking_state = ParkingState.PARKED
	parked_duration = randf_range(8.0, 20.0)
	parked_timer = parked_duration


func _start_backing_out() -> void:
	parking_state = ParkingState.BACKING_OUT_TWEEN

	# Tween back to yellow lane position, facing UP
	var aisle_pos := Vector2(parking_aisle_x, parking_row_y)

	# Duration scales with distance
	var back_dist := global_position.distance_to(aisle_pos)
	var back_duration := maxf(0.8, back_dist / 120.0)

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(self, "global_position", aisle_pos, back_duration) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)

	# Tween rotation to face UP (0)
	var current_rot := rotation
	var target_rot := 0.0
	var diff := target_rot - current_rot
	while diff > PI:
		diff -= TAU
	while diff < -PI:
		diff += TAU
	var adjusted_target := current_rot + diff

	tween.tween_property(self, "rotation", adjusted_target, back_duration) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)

	tween.finished.connect(_on_backing_out_finished)


func _on_backing_out_finished() -> void:
	_set_collision_enabled(true)
	is_active = true
	set_direction(Direction.UP)
	_rotate_to_direction(Direction.UP)
	parking_state = ParkingState.DRIVING_TO_EXIT_LANE

	# Release the parking spot
	if parking_manager and parking_spot_index >= 0:
		parking_manager.release_spot(parking_spot_index)
		parking_spot_index = -1


func assign_parking(spot_index: int, spot_pos: Vector2, facing: Direction, aisle_x: float, row_y: float, manager: Node2D) -> void:
	parking_spot_index = spot_index
	parking_target = spot_pos
	parking_facing = facing
	parking_aisle_x = aisle_x
	parking_row_y = row_y
	parking_manager = manager
	parking_state = ParkingState.DRIVING_TO_AISLE


func _set_collision_enabled(enabled: bool) -> void:
	var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape:
		shape.disabled = not enabled


func _check_player_collisions() -> void:
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


func _exit_tree() -> void:
	if parking_manager and parking_spot_index >= 0:
		parking_manager.release_spot(parking_spot_index)
		parking_spot_index = -1
