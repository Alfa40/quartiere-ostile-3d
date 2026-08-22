extends Node3D

const GrenadeUtils := preload("res://scripts/grenade_utils.gd")
const TICK_INTERVAL := 0.5

@onready var mesh: MeshInstance3D = $Mesh

var radius := 3.0
var duration := 5.0
var dps := 8.0
var source: Node = null
var _tick_timer := TICK_INTERVAL

func _ready() -> void:
	mesh.scale = Vector3(radius, 1.0, radius)

func _process(delta: float) -> void:
	duration -= delta
	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer = TICK_INTERVAL
		GrenadeUtils.explode_damage(get_tree(), global_position, radius, dps * TICK_INTERVAL, source)
	if duration <= 0.0:
		queue_free()
