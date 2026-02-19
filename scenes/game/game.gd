extends Node2D
class_name Game
## Game - Main game container that manages zones and UI

@onready var zone_container: Node2D = $ZoneContainer
@onready var player: Player = $Player
@onready var ui_layer: CanvasLayer = $UILayer
@onready var dialogue_box: Control = $UILayer/DialogueBox
@onready var interaction_prompt: Control = $UILayer/InteractionPrompt
@onready var hud: HUD = $UILayer/HUD

var current_zone: Node2D = null
var zones: Dictionary = {
	"store": "res://scenes/zones/store/store.tscn",
	"parking_lot": "res://scenes/zones/parking_lot/parking_lot.tscn",
	"bathroom": "res://scenes/zones/bathroom/bathroom.tscn",
	"backroom": "res://scenes/zones/backroom/backroom.tscn",
}


func _ready() -> void:
	GameManager.zone_changed.connect(_on_zone_changed)
	player.hp_changed.connect(_on_player_hp_changed)
	player.player_died.connect(_on_player_died)

	# Initialize HUD with player's starting HP
	hud.update_hp(player.current_hp, player.max_hp)

	# Load initial zone from save data
	var start_zone := SaveManager.current_data.current_zone
	var spawn_point := SaveManager.current_data.spawn_point
	_load_zone(start_zone, spawn_point)


func _load_zone(zone_name: String, spawn_point: String = "default") -> void:
	# Clear current zone
	if current_zone:
		current_zone.queue_free()
		current_zone = null

	# Load new zone
	if not zones.has(zone_name):
		push_error("Zone not found: %s" % zone_name)
		return

	var zone_scene := load(zones[zone_name]) as PackedScene
	if zone_scene == null:
		push_error("Failed to load zone scene: %s" % zone_name)
		return

	current_zone = zone_scene.instantiate()
	zone_container.add_child(current_zone)

	# Connect zone signals
	if current_zone.has_signal("zone_transition_requested"):
		current_zone.zone_transition_requested.connect(_on_zone_transition_requested)

	# Position player at spawn point
	_spawn_player(spawn_point)

	GameManager.current_zone = zone_name

	# Update HUD cart counter based on zone
	if zone_name == "parking_lot":
		hud.show_cart_counter()
		hud.update_cart_count(current_zone.get_remaining_carts())
		if current_zone.has_signal("cart_collected"):
			current_zone.cart_collected.connect(_on_cart_collected)
	else:
		hud.hide_cart_counter()


func _spawn_player(spawn_point_name: String) -> void:
	if current_zone == null:
		return

	var spawn_points := current_zone.get_node_or_null("SpawnPoints")
	if spawn_points == null:
		player.global_position = Vector2.ZERO
		return

	var spawn := spawn_points.get_node_or_null(spawn_point_name) as Marker2D
	if spawn == null:
		# Try default spawn
		spawn = spawn_points.get_node_or_null("default") as Marker2D

	if spawn:
		player.set_position_to_spawn(spawn)
	else:
		player.global_position = Vector2.ZERO


func _on_zone_changed(zone_name: String) -> void:
	var spawn_point := SaveManager.current_data.spawn_point
	_load_zone(zone_name, spawn_point)


func _on_zone_transition_requested(target_zone: String, spawn_point: String) -> void:
	GameManager.change_zone(target_zone, spawn_point)


func _on_player_hp_changed(current_hp: int, max_hp: int) -> void:
	hud.update_hp(current_hp, max_hp)


func _on_player_died() -> void:
	player.reset_hp()
	_spawn_player("default")


func _on_cart_collected(_cart: Node2D) -> void:
	if current_zone and current_zone.has_method("get_remaining_carts"):
		hud.update_cart_count(current_zone.get_remaining_carts())
