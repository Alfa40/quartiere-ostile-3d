extends Node3D

const TICK_INTERVAL := 0.5
const BLIND_REFRESH := 0.6

@onready var mesh: MeshInstance3D = $Mesh

var radius := 5.0
var duration := 7.0
var _tick_timer := TICK_INTERVAL

func _ready() -> void:
	mesh.scale = Vector3(radius, 1.0, radius)

func _process(delta: float) -> void:
	duration -= delta
	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer = TICK_INTERVAL
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy is Node3D and enemy.has_method("apply_blind"):
				if enemy.global_position.distance_to(global_position) <= radius:
					enemy.apply_blind(BLIND_REFRESH)
	if duration <= 0.0:
		queue_free()
