extends Area3D

# Resta nel campo abbastanza a lungo da poter essere notato ed eventualmente
# raggiunto anche se il player è dall'altra parte della zona quando compare.
const LIFESPAN := 240.0

var mushroom_id := ""
var life := LIFESPAN
var bob_phase := 0.0

@onready var cap: MeshInstance3D = $Cap

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body_entered)
	bob_phase = randf() * TAU
	_apply_color()

# Un solo modello per tutte le varietà: il colore del cappello (definito in
# Mushrooms.DATA) è l'unica cosa che le distingue a vista.
func _apply_color() -> void:
	var data: Dictionary = Mushrooms.DATA.get(mushroom_id, {})
	var color: Color = data.get("color", Color(0.8, 0.8, 0.8))
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.6
	cap.set_surface_override_material(0, mat)

func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	bob_phase += delta * 2.0
	rotate_y(delta * 0.8)
	position.y = 0.2 + sin(bob_phase) * 0.04

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and "main" in body and body.main != null and body.main.has_method("collect_mushroom"):
		body.main.collect_mushroom(mushroom_id)
		queue_free()
