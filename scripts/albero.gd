extends "res://scripts/park_object.gd"

@onready var trunk: MeshInstance3D = $Trunk
@onready var foliage: MeshInstance3D = $Foliage
@onready var real_model: Node3D = get_node_or_null("RealModel")

# Applica l'aspetto dello scenario corrente (o, in transizione, di quello
# successivo): un materiale nuovo per tronco/chioma (mai condiviso, safe
# da mutare) e la forma della chioma secondo lo scenario ("sphere" =
# cespuglio rotondo del Parco, "cone" = abete del Bosco, "sparse" =
# chioma rada e spoglia della Palude). Solo il Parco ("sphere") ha un vero
# modello 3D (Kenney): Bosco e Palude restano con le forme primitive di
# sempre, non ancora rifatte.
func apply_scenario_appearance(trunk_color: Color, foliage_color: Color, shape: String) -> void:
	if shape == "sphere" and real_model != null:
		real_model.visible = true
		trunk.visible = false
		foliage.visible = false
		return
	if real_model != null:
		real_model.visible = false
	trunk.visible = true
	foliage.visible = true

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
