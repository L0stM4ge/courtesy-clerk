extends Control
class_name HUD
## HUD - Displays health bar and cart counter

@onready var hp_bar: ProgressBar = $MarginContainer/HpBar
@onready var hp_label: Label = $MarginContainer/HpBar/HpLabel
@onready var cart_counter: Label = $CartCounter


func _ready() -> void:
	cart_counter.visible = false


func update_hp(current: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current
	hp_label.text = "HP: %d/%d" % [current, max_hp]


func update_cart_count(remaining: int) -> void:
	cart_counter.text = "Carts: %d" % remaining


func show_cart_counter() -> void:
	cart_counter.visible = true


func hide_cart_counter() -> void:
	cart_counter.visible = false
