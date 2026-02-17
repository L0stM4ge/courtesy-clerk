extends VehicleBase
class_name Motorcycle
## Motorcycle - Smaller, moderate speed vehicle


func _ready() -> void:
	super._ready()
	add_to_group("motorcycle")

	# Motorcycle base speed
	if speed < 180.0:
		speed = 180.0
