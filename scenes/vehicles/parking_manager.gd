extends Node2D
class_name ParkingManager

var spots: Array[Dictionary] = []


func _ready() -> void:
	_define_all_spots()


func _define_all_spots() -> void:
	# Spot positions computed from actual white line edges in the tscn.
	# Lines are ColorRects rotated 90° CW, so after rotation:
	#   line_top  = row_y - max(offset_right across 3 lines)
	#   line_bottom = row_y - min(offset_left across 3 lines)
	# Spots are placed in the gaps between consecutive rows' white lines.
	# All 3 sections share identical y-positions; x differs by +300 per section.

	var section_configs := [
		{"x_off": 0.0, "left_lane_x": -465.0, "right_lane_x": -135.0},
		{"x_off": 300.0, "left_lane_x": -135.0, "right_lane_x": 135.0},
		{"x_off": 600.0, "left_lane_x": 135.0, "right_lane_x": 465.0},
	]

	# Template row edges for LeftSection (x_off = 0)
	# Left side rows (Row1, Row3, Row5, Row7, Row9) — cars face RIGHT
	var left_rows := [
		{"x": -335.0, "line_top": -134.0, "line_bottom": -127.0},
		{"x": -335.0, "line_top": 22.0, "line_bottom": 28.0},
		{"x": -329.0, "line_top": 179.0, "line_bottom": 187.0},
		{"x": -368.0, "line_top": 284.0, "line_bottom": 291.0},
		{"x": -367.0, "line_top": 423.0, "line_bottom": 430.0},
	]

	# Right side rows (Row2, Row4, Row6, Row8, Row10) — cars face LEFT
	var right_rows := [
		{"x": -265.0, "line_top": -164.0, "line_bottom": -157.0},
		{"x": -265.0, "line_top": -8.0, "line_bottom": -2.0},
		{"x": -265.0, "line_top": 144.0, "line_bottom": 150.0},
		{"x": -267.0, "line_top": 285.0, "line_bottom": 292.0},
		{"x": -266.0, "line_top": 423.0, "line_bottom": 429.0},
	]

	for config in section_configs:
		var x_off: float = config["x_off"]
		var left_lane_x: float = config["left_lane_x"]
		var right_lane_x: float = config["right_lane_x"]

		_add_spots_for_side(left_rows, x_off, VehicleBase.Direction.RIGHT, left_lane_x)
		_add_spots_for_side(right_rows, x_off, VehicleBase.Direction.LEFT, right_lane_x)


func _add_spots_for_side(rows: Array, x_offset: float, facing: VehicleBase.Direction, lane_x: float) -> void:
	var min_gap_for_two := 120.0  # Mom van is 60px long; need gap/4 >= 30 for margins

	for i in range(rows.size() - 1):
		var upper: Dictionary = rows[i]
		var lower: Dictionary = rows[i + 1]
		var gap_start: float = upper["line_bottom"]
		var gap_end: float = lower["line_top"]
		var gap_size: float = gap_end - gap_start
		var spot_x: float = (upper["x"] + lower["x"]) / 2.0 + x_offset

		if gap_size >= min_gap_for_two:
			# 2 spots at 1/4 and 3/4 of the gap
			var spot1_y: float = gap_start + gap_size / 4.0
			var spot2_y: float = gap_start + 3.0 * gap_size / 4.0
			_add_spot(Vector2(spot_x, spot1_y), facing, lane_x, spot1_y)
			_add_spot(Vector2(spot_x, spot2_y), facing, lane_x, spot2_y)
		else:
			# 1 spot centered in the gap
			var spot_y: float = (gap_start + gap_end) / 2.0
			_add_spot(Vector2(spot_x, spot_y), facing, lane_x, spot_y)


func _add_spot(pos: Vector2, facing: VehicleBase.Direction, aisle_x: float, row_y: float) -> void:
	spots.append({
		"position": pos,
		"facing": facing,
		"aisle_x": aisle_x,
		"row_y": row_y,
		"occupied": false,
		"vehicle": null,
	})


func get_available_spot() -> Dictionary:
	var available: Array[int] = []
	for i in spots.size():
		if not spots[i]["occupied"] and not _is_spot_blocked_by_cart(spots[i]["position"]):
			available.append(i)
	if available.is_empty():
		return {}
	var index: int = available[randi() % available.size()]
	return {"index": index, "spot": spots[index]}


func _is_spot_blocked_by_cart(spot_pos: Vector2) -> bool:
	var carts := get_tree().get_nodes_in_group("cart")
	for cart in carts:
		if cart is Node2D and cart.global_position.distance_to(spot_pos) < 40.0:
			return true
	return false


func claim_spot(index: int, vehicle: VehicleBase) -> void:
	spots[index]["occupied"] = true
	spots[index]["vehicle"] = vehicle


func release_spot(index: int) -> void:
	spots[index]["occupied"] = false
	spots[index]["vehicle"] = null


func get_parked_count() -> int:
	var count := 0
	for spot in spots:
		if spot["occupied"]:
			count += 1
	return count


func pre_populate(spawner: Node2D) -> void:
	var target_count := 20
	var indices: Array[int] = []
	for i in spots.size():
		if not _is_spot_blocked_by_cart(spots[i]["position"]):
			indices.append(i)
	indices.shuffle()

	for i in mini(target_count, indices.size()):
		var idx: int = indices[i]
		var spot: Dictionary = spots[idx]

		# Create random parkable vehicle (no motorcycles)
		var vehicle: VehicleBase = spawner._create_random_parkable_vehicle()

		# Assign parking data before adding to tree
		vehicle.parking_spot_index = idx
		vehicle.parking_target = spot["position"]
		vehicle.parking_facing = spot["facing"]
		vehicle.parking_aisle_x = spot["aisle_x"]
		vehicle.parking_row_y = spot["row_y"]
		vehicle.parking_manager = self
		vehicle.parking_state = VehicleBase.ParkingState.PARKED
		vehicle.parked_timer = randf_range(3.0, 15.0)
		vehicle.is_active = false

		# Add to scene
		spawner.add_child(vehicle)
		vehicle.global_position = spot["position"]

		# Rotate to face the right direction
		match spot["facing"]:
			VehicleBase.Direction.LEFT:
				vehicle.rotation = PI / 2
			VehicleBase.Direction.RIGHT:
				vehicle.rotation = -PI / 2

		# Disable collision for parked vehicles
		vehicle._set_collision_enabled(false)

		claim_spot(idx, vehicle)
		spawner.active_vehicles.append(vehicle)
