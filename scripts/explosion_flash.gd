extends Node3D

@onready var mesh: MeshInstance3D = $Mesh

var radius := 3.0
var color := Color(1.0, 0.55, 0.2, 0.85)

func _ready() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b, 1.0)
	mat.emission_energy_multiplier = 1.6
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.set_surface_override_material(0, mat)
	mesh.scale = Vector3(0.15, 1.0, 0.15)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(mesh, "scale", Vector3(radius, 1.0, radius), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.32).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(queue_free)
