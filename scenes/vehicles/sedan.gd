extends VehicleBase
class_name Sedan
## Sedan - Regular car, moderate speed, medium size


func _ready() -> void:
	super._ready()
	add_to_group("sedan")
