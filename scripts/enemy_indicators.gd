extends Control

const REVEAL_DELAY := 10.0
const MARGIN := 56.0
const ARROW_SIZE := 22.0

var camera: Camera3D = null
var targets: Array = []
var time_since_seen := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

func _process(delta: float) -> void:
	if camera == null:
		camera = get_viewport().get_camera_3d()
		if camera == null:
			return

	var vp_size := get_viewport_rect().size
	var center := vp_size / 2.0
	var enemies := get_tree().get_nodes_in_group("enemies")

	var any_visible := false
	var offscreen: Array = []
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var world_pos: Vector3 = enemy.global_position + Vector3(0, 1.0, 0)
		var behind: bool = camera.is_position_behind(world_pos)
		var screen_pos: Vector2 = camera.unproject_position(world_pos)
		var onscreen: bool = (not behind) and screen_pos.x >= 0.0 and screen_pos.x <= vp_size.x and screen_pos.y >= 0.0 and screen_pos.y <= vp_size.y
		if onscreen:
			any_visible = true
		else:
			offscreen.append({"screen_pos": screen_pos, "behind": behind})

	if any_visible or enemies.is_empty():
		time_since_seen = 0.0
	else:
		time_since_seen += delta

	targets.clear()
	if time_since_seen >= REVEAL_DELAY:
		var half_w := vp_size.x / 2.0 - MARGIN
		var half_h := vp_size.y / 2.0 - MARGIN
		for entry in offscreen:
			var dir: Vector2 = entry.screen_pos - center
			if entry.behind:
				dir = -dir
			if dir.length() < 0.001:
				dir = Vector2(1, 0)
			dir = dir.normalized()
			var tx: float = (half_w / absf(dir.x)) if dir.x != 0.0 else INF
			var ty: float = (half_h / absf(dir.y)) if dir.y != 0.0 else INF
			var t: float = min(tx, ty)
			var edge_pos: Vector2 = center + dir * t
			targets.append({"pos": edge_pos, "angle": dir.angle()})

	queue_redraw()

func _draw() -> void:
	for t in targets:
		var pos: Vector2 = t.pos
		var angle: float = t.angle
		var p1 := pos + Vector2(ARROW_SIZE, 0).rotated(angle)
		var p2 := pos + Vector2(-ARROW_SIZE * 0.6, ARROW_SIZE * 0.6).rotated(angle)
		var p3 := pos + Vector2(-ARROW_SIZE * 0.6, -ARROW_SIZE * 0.6).rotated(angle)
		draw_colored_polygon(PackedVector2Array([p1, p2, p3]), Color(1, 0.3, 0.25, 0.9))
