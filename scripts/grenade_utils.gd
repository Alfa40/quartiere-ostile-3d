class_name GrenadeUtils
extends RefCounted

static func explode_damage(tree: SceneTree, center: Vector3, radius: float, damage: float, source: Node) -> void:
	for body in tree.get_nodes_in_group("enemies"):
		if body is Node3D and body.has_method("take_damage"):
			if body.global_position.distance_to(center) <= radius:
				body.take_damage(damage, source)
