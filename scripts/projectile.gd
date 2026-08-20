extends Area3D

var travel := Vector3.ZERO
var damage := 6.0
var life := 3.0
var source: Node = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	global_position += travel * delta

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, source)
	queue_free()
