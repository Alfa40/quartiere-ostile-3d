extends Area3D

var travel := Vector3.ZERO
var damage := 20.0
var max_distance := 14.0
var source: Node = null
var _traveled := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 4
	monitoring = true
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	var step := travel * delta
	global_position += step
	_traveled += step.length()
	if _traveled >= max_distance:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage, source)
	queue_free()
