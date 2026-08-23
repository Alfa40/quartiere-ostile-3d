extends "res://scripts/grenade_projectile.gd"

# Traiettoria a parabola (arco), usata dai lanciagranate: il colpo parte
# lento, sale e scende per gravità, rimbalza una volta a terra e poi esplode
# al secondo contatto col terreno (oppure subito se colpisce un nemico,
# comportamento ereditato da grenade_projectile.gd).
const ARC_GRAVITY := 20.0
const BOUNCE_DAMPING := 0.45
const GROUND_Y := 0.0

var arc_velocity := Vector3.ZERO
var _bounced := false

func _process(delta: float) -> void:
	if _stuck:
		if _stuck_body != null and is_instance_valid(_stuck_body):
			global_position = _stuck_body.global_position + _stuck_offset
		return
	arc_velocity.y -= ARC_GRAVITY * delta
	global_position += arc_velocity * delta
	if global_position.y <= GROUND_Y:
		global_position.y = GROUND_Y
		if not _bounced:
			_bounced = true
			arc_velocity.y = -arc_velocity.y * BOUNCE_DAMPING
			arc_velocity.x *= BOUNCE_DAMPING
			arc_velocity.z *= BOUNCE_DAMPING
		else:
			_arrive()
