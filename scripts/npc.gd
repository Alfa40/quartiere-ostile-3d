extends CharacterBody3D

# NPC del tutorial iniziale: nessuna IA di combattimento, solo due stati —
# fermo in attesa (a terra, aggredito o in attesa del prossimo passo) e
# cammino guidato verso un punto (per farsi accompagnare a casa).

signal reached_target

const GRAVITY := 20.0
const WALK_SPEED := 3.0

@onready var facing_pivot: Node3D = $FacingPivot

var state := "idle"
var walk_target := Vector3.ZERO
var walk_arrive_radius := 1.2

func face_direction(dir: Vector3) -> void:
	if dir.length() < 0.0001:
		return
	facing_pivot.look_at(facing_pivot.global_position + dir, Vector3.UP)

func start_walking_to(target: Vector3, arrive_radius: float = 1.2) -> void:
	walk_target = target
	walk_arrive_radius = arrive_radius
	state = "walking"

func _physics_process(delta: float) -> void:
	if state == "walking":
		var to_target: Vector3 = walk_target - global_position
		to_target.y = 0.0
		var dist := to_target.length()
		if dist <= walk_arrive_radius:
			state = "idle"
			velocity.x = 0.0
			velocity.z = 0.0
			reached_target.emit()
		else:
			var dir := to_target.normalized()
			velocity.x = dir.x * WALK_SPEED
			velocity.z = dir.z * WALK_SPEED
			face_direction(dir)
	else:
		velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, WALK_SPEED * 8.0 * delta)

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()
