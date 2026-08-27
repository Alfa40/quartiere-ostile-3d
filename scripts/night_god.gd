extends CharacterBody3D

# "Dio della notte": insegue insistentemente il player nel buio, sempre più
# lento di lui (vedi main.gd, speed impostata allo spawn a metà della
# velocità attuale del player) così da lasciare sempre una via di fuga a chi
# reagisce in tempo. Il contatto uccide all'istante. Può ricevere danni ma
# con GOD_HP_MULTIPLIER x la vita del player è, nella pratica, inespugnabile:
# l'unica strategia sensata è scappare, non combattere.
const KILL_RANGE := 1.3
const GRAVITY := 20.0

var target: Node3D = null
var speed := 2.0
var max_hp := 100.0
var hp := 100.0

func _ready() -> void:
	add_to_group("night_gods")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	if target != null and is_instance_valid(target):
		var to_target: Vector3 = target.global_position - global_position
		to_target.y = 0.0
		var dist: float = to_target.length()
		if dist > 0.05:
			var dir: Vector3 = to_target / dist
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed
			look_at(global_position + dir, Vector3.UP)
		else:
			velocity.x = 0.0
			velocity.z = 0.0
		if dist <= KILL_RANGE and target.has_method("take_damage"):
			target.take_damage(999999.0)

	move_and_slide()

func take_damage(amount: float, _source = null) -> void:
	hp = max(hp - amount, 0.0)
