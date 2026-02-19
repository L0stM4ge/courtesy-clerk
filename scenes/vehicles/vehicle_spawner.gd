extends Node2D
class_name VehicleSpawner
## VehicleSpawner - Manages spawning vehicles in parking lot lanes

signal vehicle_spawned(vehicle: Node2D)
signal vehicle_despawned(vehicle: Node2D)

@export var spawn_enabled: bool = true
@export var min_spawn_interval: float = 2.0
@export var max_spawn_interval: float = 5.0
@export var max_active_vehicles: int = 30
@export var broom_spawn_chance: float = 0.15  # 15% chance for a broom
@export var parking_chance: float = 0.4
@export var max_parked_vehicles: int = 20
@export var target_parked_vehicles: int = 15  # Parking chance ramps up below this

# Vehicle scenes
var sedan_scene: PackedScene = preload("res://scenes/vehicles/sedan.tscn")
var motorcycle_scene: PackedScene = preload("res://scenes/vehicles/motorcycle.tscn")
var mom_van_scene: PackedScene = preload("res://scenes/vehicles/mom_van.tscn")
var broom_scene: PackedScene = preload("res://scenes/vehicles/witches_broom.tscn")

# Lane definitions (start_pos, end_pos, direction)
var horizontal_lanes: Array[Dictionary] = []
var vertical_lanes: Array[Dictionary] = []

# Broom rack reference
var broom_rack: BroomRack = null

# Parking manager reference
var parking_manager: ParkingManager = null

# Active vehicles
var active_vehicles: Array[Node2D] = []
var spawn_timer: float = 0.0
var next_spawn_time: float = 2.0


func _ready() -> void:
	_setup_lanes()
	# Defer finding siblings to ensure all nodes are ready
	call_deferred("_find_broom_rack")
	call_deferred("_find_parking_manager")
	next_spawn_time = randf_range(min_spawn_interval, max_spawn_interval)


func _setup_lanes() -> void:
	# Horizontal lanes - ONE WAY traffic
	# Top lane (y = -225): RIGHT to LEFT only
	horizontal_lanes.append({
		"y": -225,
		"direction": VehicleBase.Direction.LEFT,
		"start_x": 550,
		"end_x": -550
	})

	# Bottom lane (y = -175): LEFT to RIGHT only
	horizontal_lanes.append({
		"y": -175,
		"direction": VehicleBase.Direction.RIGHT,
		"start_x": -550,
		"end_x": 550
	})

	# Vertical lanes (cars drive up from bottom, then turn onto horizontal lanes)
	# West lane: x = -465
	vertical_lanes.append({
		"x": -465,
		"direction": VehicleBase.Direction.UP,
		"start_y": 650,
		"turn_y": -175,
		"will_turn": true
	})

	# Mid-left lane: x = -135
	vertical_lanes.append({
		"x": -135,
		"direction": VehicleBase.Direction.UP,
		"start_y": 650,
		"turn_y": -175,
		"will_turn": true
	})

	# Mid-right lane: x = 135
	vertical_lanes.append({
		"x": 135,
		"direction": VehicleBase.Direction.UP,
		"start_y": 650,
		"turn_y": -175,
		"will_turn": true
	})

	# East lane: x = 465
	vertical_lanes.append({
		"x": 465,
		"direction": VehicleBase.Direction.UP,
		"start_y": 650,
		"turn_y": -175,
		"will_turn": true
	})


func _find_broom_rack() -> void:
	var racks := get_tree().get_nodes_in_group("broom_rack")
	if racks.size() > 0:
		broom_rack = racks[0] as BroomRack


func _find_parking_manager() -> void:
	var parent := get_parent()
	if parent:
		for child in parent.get_children():
			if child is ParkingManager:
				parking_manager = child
				break
	if parking_manager:
		parking_manager.pre_populate(self)


func _process(delta: float) -> void:
	if not spawn_enabled:
		return

	# Clean up despawned vehicles
	_cleanup_vehicles()

	# Spawn timer
	spawn_timer += delta
	if spawn_timer >= next_spawn_time:
		spawn_timer = 0.0
		next_spawn_time = randf_range(min_spawn_interval, max_spawn_interval)

		if active_vehicles.size() < max_active_vehicles:
			_spawn_random_vehicle()


func _cleanup_vehicles() -> void:
	var to_remove: Array[Node2D] = []

	for vehicle in active_vehicles:
		if not is_instance_valid(vehicle):
			to_remove.append(vehicle)
			continue

		if vehicle is VehicleBase:
			var vb := vehicle as VehicleBase
			# Skip vehicles that are in parking states (not NONE or EXITING)
			if vb.parking_state != VehicleBase.ParkingState.NONE and \
				vb.parking_state != VehicleBase.ParkingState.EXITING:
				continue

		# Check if vehicle is out of bounds
		var pos := vehicle.global_position
		if pos.x < -600 or pos.x > 600 or pos.y < -500 or pos.y > 700:
			to_remove.append(vehicle)
			if vehicle is VehicleBase:
				var vb := vehicle as VehicleBase
				if vb.parking_manager and vb.parking_spot_index >= 0:
					vb.parking_manager.release_spot(vb.parking_spot_index)
					vb.parking_spot_index = -1
			vehicle.queue_free()
			vehicle_despawned.emit(vehicle)
			continue

		# Clean up stopped vehicles (e.g. hit north boundary)
		if vehicle is VehicleBase and not vehicle.is_active:
			var vb := vehicle as VehicleBase
			if vb.parking_state == VehicleBase.ParkingState.NONE:
				to_remove.append(vehicle)
				vehicle.queue_free()
				vehicle_despawned.emit(vehicle)

	for vehicle in to_remove:
		active_vehicles.erase(vehicle)


func _spawn_random_vehicle() -> void:
	# Decide if spawning a broom or regular vehicle
	if broom_rack and broom_rack.has_available_spot() and randf() < broom_spawn_chance:
		_spawn_broom()
	else:
		_spawn_ground_vehicle()


func _spawn_ground_vehicle() -> void:
	# Pick random vehicle type (weighted)
	var vehicle: VehicleBase = _create_random_ground_vehicle()

	# Check if this vehicle should park
	var can_park := not (vehicle is Motorcycle)
	if can_park and parking_manager:
		var parked_count := parking_manager.get_parked_count()
		if parked_count < max_parked_vehicles:
			# Dynamic parking chance: ramps up when lot is emptier than target
			var effective_chance := parking_chance
			if parked_count < target_parked_vehicles:
				var urgency := 1.0 - float(parked_count) / float(target_parked_vehicles)
				effective_chance = lerpf(parking_chance, 0.95, urgency)
			if randf() < effective_chance:
				var spot_data := parking_manager.get_available_spot()
				if not spot_data.is_empty():
					_spawn_parking_vehicle(vehicle, spot_data)
					return

	# Otherwise, spawn as drive-through
	_spawn_drive_through_vehicle(vehicle)


func _spawn_parking_vehicle(vehicle: VehicleBase, spot_data: Dictionary) -> void:
	var index: int = spot_data["index"]
	var spot: Dictionary = spot_data["spot"]

	# Claim the spot
	parking_manager.claim_spot(index, vehicle)

	# Spawn on bottom lane going RIGHT
	vehicle.global_position = Vector2(-550, -175)
	vehicle.set_direction(VehicleBase.Direction.RIGHT)
	_rotate_vehicle_to_direction(vehicle, VehicleBase.Direction.RIGHT)

	# Assign parking behavior
	vehicle.assign_parking(index, spot["position"], spot["facing"], spot["aisle_x"], spot["row_y"], parking_manager)

	# Add to scene
	add_child(vehicle)
	active_vehicles.append(vehicle)
	vehicle_spawned.emit(vehicle)


func _spawn_drive_through_vehicle(vehicle: VehicleBase) -> void:
	# Pick random lane type (60% horizontal, 40% vertical)
	var use_horizontal := randf() > 0.4
	var lane: Dictionary

	if use_horizontal:
		lane = horizontal_lanes[randi() % horizontal_lanes.size()]
	else:
		lane = vertical_lanes[randi() % vertical_lanes.size()]

	# Position vehicle at lane start
	if use_horizontal:
		vehicle.global_position = Vector2(lane["start_x"], lane["y"])
		vehicle.set_direction(lane["direction"])
	else:
		vehicle.global_position = Vector2(lane["x"], lane["start_y"])
		vehicle.set_direction(lane["direction"])

		# Configure turn behavior for vertical vehicles
		if lane.get("will_turn", false):
			# Pick random turn direction
			var turn_left := randf() > 0.5
			if turn_left:
				# Turn left - go to top lane (y=-225) which moves LEFT
				vehicle.turn_at_y = -225
				vehicle.turn_direction = VehicleBase.Direction.LEFT
			else:
				# Turn right - stay in bottom lane (y=-175) which moves RIGHT
				vehicle.turn_at_y = -175
				vehicle.turn_direction = VehicleBase.Direction.RIGHT

	# Rotate vehicle to face movement direction
	_rotate_vehicle_to_direction(vehicle, lane["direction"])

	# Add to scene
	add_child(vehicle)
	active_vehicles.append(vehicle)
	vehicle_spawned.emit(vehicle)


func _create_random_ground_vehicle() -> VehicleBase:
	var roll := randf()

	if roll < 0.5:
		# 50% sedan
		return sedan_scene.instantiate() as VehicleBase
	elif roll < 0.8:
		# 30% motorcycle
		return motorcycle_scene.instantiate() as VehicleBase
	else:
		# 20% mom van
		return mom_van_scene.instantiate() as VehicleBase


func _create_random_parkable_vehicle() -> VehicleBase:
	# Only sedan or mom_van (no motorcycles)
	if randf() < 0.7:
		return sedan_scene.instantiate() as VehicleBase
	else:
		return mom_van_scene.instantiate() as VehicleBase


func _rotate_vehicle_to_direction(vehicle: Node2D, direction: VehicleBase.Direction) -> void:
	match direction:
		VehicleBase.Direction.LEFT:
			vehicle.rotation = PI / 2  # 90 degrees
		VehicleBase.Direction.RIGHT:
			vehicle.rotation = -PI / 2  # -90 degrees
		VehicleBase.Direction.UP:
			vehicle.rotation = 0
		VehicleBase.Direction.DOWN:
			vehicle.rotation = PI  # 180 degrees


func _spawn_broom() -> void:
	if not broom_rack:
		return

	var broom: WitchesBroom = broom_scene.instantiate() as WitchesBroom

	# Get parking spot
	var target_pos := broom_rack.get_available_spot()

	# Random entry angle (from corners or sides at odd angles)
	var entry_points: Array[Dictionary] = [
		{"pos": Vector2(-600, -500), "dir": Vector2(1, 0.5).normalized()},   # Top-left, angled down-right
		{"pos": Vector2(600, -500), "dir": Vector2(-1, 0.5).normalized()},   # Top-right, angled down-left
		{"pos": Vector2(-600, 200), "dir": Vector2(1, -0.7).normalized()},   # Left side, angled up-right
		{"pos": Vector2(600, 200), "dir": Vector2(-1, -0.7).normalized()},   # Right side, angled up-left
		{"pos": Vector2(0, -600), "dir": Vector2(0.3, 1).normalized()},      # Top center, slight angle
		{"pos": Vector2(-400, -550), "dir": Vector2(0.5, 1).normalized()},   # Top-left area
		{"pos": Vector2(400, -550), "dir": Vector2(-0.5, 1).normalized()},   # Top-right area
	]

	var entry := entry_points[randi() % entry_points.size()]

	# Start flying in
	broom.fly_in_from_angle(entry["pos"], entry["dir"])

	# Add to scene
	add_child(broom)
	active_vehicles.append(broom)
	vehicle_spawned.emit(broom)

	# After a delay, start landing
	_schedule_broom_landing(broom, target_pos)


func _schedule_broom_landing(broom: WitchesBroom, target: Vector2) -> void:
	# Wait until broom is closer to the parking lot
	var tween := create_tween()
	tween.tween_interval(1.5)  # Fly for 1.5 seconds
	tween.tween_callback(func():
		if is_instance_valid(broom):
			broom.start_landing(target, broom_rack)
			broom.landed.connect(func(): _on_broom_landed(broom))
	)


func _on_broom_landed(broom: WitchesBroom) -> void:
	if broom_rack:
		broom_rack.register_parked_broom(broom)

	# Broom takes off after some time
	var park_time := randf_range(8.0, 15.0)
	var tween := create_tween()
	tween.tween_interval(park_time)
	tween.tween_callback(func():
		if is_instance_valid(broom):
			_broom_take_off(broom)
	)


func _broom_take_off(broom: WitchesBroom) -> void:
	if broom_rack:
		broom_rack.unregister_broom(broom)

	# Random exit direction
	var exit_directions: Array[Vector2] = [
		Vector2(-1, -0.5).normalized(),
		Vector2(1, -0.5).normalized(),
		Vector2(0, -1),
		Vector2(-0.7, -0.7).normalized(),
		Vector2(0.7, -0.7).normalized(),
	]

	var exit_dir := exit_directions[randi() % exit_directions.size()]
	broom.take_off(exit_dir)


func set_spawn_enabled(enabled: bool) -> void:
	spawn_enabled = enabled


func despawn_all() -> void:
	for vehicle in active_vehicles:
		if is_instance_valid(vehicle):
			vehicle.queue_free()
	active_vehicles.clear()
