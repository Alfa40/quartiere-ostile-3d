extends Area3D

var travel := Vector3.ZERO
var damage := 20.0
var max_distance := 14.0
var source: Node = null
var _traveled := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 12  # nemici (4) + oggetti del parco (8)
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
		return
	# Gli oggetti bassi (cestini, recinzioni) non vengono colpiti dai proiettili.
	if body.is_in_group("park_objects") and body.has_method("take_damage") and not bool(body.get("low_object")):
		body.take_damage(damage, source)
		queue_free()
