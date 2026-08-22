extends StaticBody3D

signal destroyed

@export var max_hp: float = 100.0
@export var material_drops: Dictionary = {}
@export var low_object: bool = false

var hp: float
var base_scale: Vector3

func _ready() -> void:
	hp = max_hp
	base_scale = scale
	add_to_group("park_objects")

func take_damage(amount: float, _source = null) -> void:
	if hp <= 0.0:
		return
	hp -= amount
	if hp <= 0.0:
		hp = 0.0
		destroyed.emit()
		_play_destroy_and_free()
	else:
		_flash_hit()

func _flash_hit() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", base_scale * 1.08, 0.05)
	tw.tween_property(self, "scale", base_scale, 0.08)

func _play_destroy_and_free() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", base_scale * 0.05, 0.25)
	tw.tween_callback(queue_free)
