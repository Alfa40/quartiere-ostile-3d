extends "res://scripts/park_object.gd"

@onready var trunk: MeshInstance3D = $Trunk
@onready var foliage: MeshInstance3D = $Foliage

# Applica l'aspetto dello scenario corrente (o, in transizione, di quello
# successivo). apply_scenario_visual (classe base) mostra il vero modello
# 3D dedicato se questo scenario ne ha uno (figlio "RealModel_<idx>"),
# altrimenti lascia visibili le forme primitive tronco/chioma qui sotto,
# colorate e sagomate secondo lo scenario ("cone" = abete, "sparse" =
# chioma rada e spoglia, qualsiasi altro valore = cespuglio rotondo).
func apply_scenario_appearance(trunk_color: Color, foliage_color: Color, shape: String, scenario_idx: int) -> void:
	apply_scenario_visual(scenario_idx)
	if _real_models.has(scenario_idx):
		return

	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = trunk_color
	trunk_mat.roughness = 0.9
	trunk.set_surface_override_material(0, trunk_mat)

	var foliage_mat := StandardMaterial3D.new()
	foliage_mat.albedo_color = foliage_color
	foliage_mat.roughness = 0.85
	foliage.set_surface_override_material(0, foliage_mat)

	match shape:
		"cone":
			var cone_mesh := CylinderMesh.new()
			cone_mesh.top_radius = 0.0
			cone_mesh.bottom_radius = 1.0
			cone_mesh.height = 2.2
			foliage.mesh = cone_mesh
			foliage.position = Vector3(0, 1.9, 0)
		_:
			var sparse_mesh := SphereMesh.new()
			sparse_mesh.radius = 0.5
			sparse_mesh.height = 1.0
			foliage.mesh = sparse_mesh
			foliage.position = Vector3(0, 1.7, 0)
