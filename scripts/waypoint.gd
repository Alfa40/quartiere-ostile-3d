extends Area3D

signal reached

@onready var ring: MeshInstance3D = $Ring

var spin := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	spin += delta
	rotation.y = spin * 0.8
	ring.position.y = 0.15 + sin(spin * 2.0) * 0.05

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		reached.emit()
		queue_free()
