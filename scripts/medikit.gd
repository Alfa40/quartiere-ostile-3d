extends Area3D

const HEAL_FRACTION := 1.0
const LIFESPAN := 14.0

var life := LIFESPAN
var bob_phase := 0.0

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
	bob_phase += delta * 2.5
	rotate_y(delta * 1.5)
	position.y = 0.35 + sin(bob_phase) * 0.06

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("heal"):
		body.heal(HEAL_FRACTION)
		queue_free()
