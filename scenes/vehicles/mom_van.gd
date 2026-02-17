extends VehicleBase
class_name MomVan
## MomVan - Aggressive SUV driven by moms picking up kids, slows down for no one

# MomVan is faster than motorcycle (motorcycle base speed ~180, momVan ~250)
# These moms drive SUVs like sports cars


func _ready() -> void:
	super._ready()
	add_to_group("mom_van")

	# MomVan doesn't slow down - override speed if not set high enough
	if speed < 250.0:
		speed = 250.0
