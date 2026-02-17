extends Resource
class_name SaveData
## SaveData - Structure for save file data

@export var current_zone: String = "store"
@export var spawn_point: String = "default"
@export var player_position: Vector2 = Vector2.ZERO
@export var player_direction: Vector2 = Vector2.DOWN
@export var save_timestamp: float = 0.0
@export var game_flags: Dictionary = {}
@export var inventory: Array[String] = []
@export var completed_tasks: Array[String] = []


func to_dict() -> Dictionary:
	return {
		"current_zone": current_zone,
		"spawn_point": spawn_point,
		"player_position": {"x": player_position.x, "y": player_position.y},
		"player_direction": {"x": player_direction.x, "y": player_direction.y},
		"save_timestamp": save_timestamp,
		"game_flags": game_flags,
		"inventory": inventory,
		"completed_tasks": completed_tasks,
	}


func from_dict(data: Dictionary) -> void:
	current_zone = data.get("current_zone", "store")
	spawn_point = data.get("spawn_point", "default")

	var pos: Dictionary = data.get("player_position", {})
	player_position = Vector2(pos.get("x", 0.0), pos.get("y", 0.0))

	var dir: Dictionary = data.get("player_direction", {})
	player_direction = Vector2(dir.get("x", 0.0), dir.get("y", 1.0))

	save_timestamp = data.get("save_timestamp", 0.0)
	game_flags = data.get("game_flags", {})
	inventory = Array(data.get("inventory", []), TYPE_STRING, "", null)
	completed_tasks = Array(data.get("completed_tasks", []), TYPE_STRING, "", null)
