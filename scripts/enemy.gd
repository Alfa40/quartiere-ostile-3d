extends CharacterBody3D

const BASE_SPEED := 3.2
const BASE_MAX_HP := 40.0
const BASE_ATTACK_DAMAGE := 4.0
const BASE_ATTACK_COOLDOWN := 1.0
const MIN_ATTACK_COOLDOWN := 0.2
const ATTACK_RANGE := 1.6
const GRAVITY := 20.0

const RANGED_PREFERRED := 8.0
const RANGED_MAX := 10.0
const RANGED_PROJECTILE_SPEED := 13.0

const ProjectileScene := preload("res://scenes/Projectile.tscn")
const EnemyArchetypes := preload("res://scripts/enemy_archetypes.gd")

signal died

@onready var facing_pivot: Node3D = $FacingPivot
@onready var visual_root: Node3D = $FacingPivot/VisualRoot
@onready var right_shoulder: Node3D = $FacingPivot/VisualRoot/RightShoulder
@onready var right_elbow: Node3D = $FacingPivot/VisualRoot/RightShoulder/RightElbow
@onready var left_shoulder: Node3D = $FacingPivot/VisualRoot/LeftShoulder
@onready var left_elbow: Node3D = $FacingPivot/VisualRoot/LeftShoulder/LeftElbow
@onready var left_hip: Node3D = $FacingPivot/VisualRoot/LeftHip
@onready var left_knee: Node3D = $FacingPivot/VisualRoot/LeftHip/LeftKnee
@onready var right_hip: Node3D = $FacingPivot/VisualRoot/RightHip
@onready var right_knee: Node3D = $FacingPivot/VisualRoot/RightHip/RightKnee

var speed := BASE_SPEED
var max_hp := BASE_MAX_HP
var hp := BASE_MAX_HP
var attack_damage := BASE_ATTACK_DAMAGE
var attack_cooldown := BASE_ATTACK_COOLDOWN
var radius_mult := 1.0
var behavior := "steady"

var attack_cooldown_timer := 0.0
var dead := false
var player: Node3D = null
var walk_phase := 0.0
var arm_tween: Tween = null

var erratic_state := "charge"
var erratic_timer := 0.0

func _ready() -> void:
	add_to_group("enemies")
	call_deferred("_find_player")

func configure(hp_mult: float, dmg_mult: float, speed_mult: float, cooldown_seconds: float, archetype_id: String = "balordo") -> void:
	var arch: Dictionary = EnemyArchetypes.DATA.get(archetype_id, EnemyArchetypes.DATA["balordo"])
	behavior = arch.behavior
	radius_mult = arch.radius_mult
	scale = Vector3.ONE * radius_mult
	max_hp = BASE_MAX_HP * arch.hp_mult * hp_mult
	hp = max_hp
	attack_damage = BASE_ATTACK_DAMAGE * arch.damage_mult * dmg_mult
	speed = BASE_SPEED * arch.speed_mult * speed_mult
	attack_cooldown = max(cooldown_seconds * arch.cooldown_mult, MIN_ATTACK_COOLDOWN)
	_apply_color(arch.color)

func _apply_color(color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.1
	mat.roughness = 0.5
	_tint_recursive(visual_root, mat)

func _tint_recursive(node: Node, mat: Material) -> void:
	if node.name == "Head" or node.name == "Face":
		return
	if node is MeshInstance3D:
		node.set_surface_override_material(0, mat)
	for c in node.get_children():
		_tint_recursive(c, mat)

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta: float) -> void:
	if dead or player == null or not is_instance_valid(player):
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		else:
			velocity.y = 0.0
		velocity.x = move_toward(velocity.x, 0.0, speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 8.0 * delta)
		move_and_slide()
		return

	attack_cooldown_timer -= delta

	if behavior == "ranged":
		_process_ranged(delta)
	else:
		_process_melee(delta)

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= GRAVITY * delta

	move_and_slide()
	_animate_body(delta)

func _process_melee(delta: float) -> void:
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	var effective_range := ATTACK_RANGE * radius_mult

	if dist > effective_range:
		var move_dir := _compute_move_dir(to_player, delta)
		velocity.x = move_dir.x * speed
		velocity.z = move_dir.z * speed
		if move_dir.length() > 0.01:
			facing_pivot.look_at(facing_pivot.global_position + move_dir, Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 8.0 * delta)
		facing_pivot.look_at(facing_pivot.global_position + to_player.normalized(), Vector3.UP)
		if attack_cooldown_timer <= 0.0 and player.has_method("take_damage"):
			player.take_damage(attack_damage, self)
			attack_cooldown_timer = attack_cooldown
			_play_attack_swing()

func _compute_move_dir(to_player: Vector3, delta: float) -> Vector3:
	if behavior != "erratic":
		return to_player.normalized()

	erratic_timer -= delta
	if erratic_timer <= 0.0:
		var states := ["charge", "charge", "sidestep", "retreat"]
		erratic_state = states[randi() % states.size()]
		erratic_timer = randf_range(0.6, 1.4)

	var to_player_dir := to_player.normalized()
	match erratic_state:
		"sidestep":
			var side := Vector3(-to_player_dir.z, 0, to_player_dir.x)
			return side if (randi() % 2 == 0) else -side
		"retreat":
			return -to_player_dir
		_:
			return to_player_dir

func _process_ranged(delta: float) -> void:
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	var dir := to_player.normalized() if dist > 0.01 else Vector3.FORWARD

	var move_dir := Vector3.ZERO
	if dist < RANGED_PREFERRED * 0.7:
		move_dir = -dir
	elif dist > RANGED_PREFERRED * 1.15:
		move_dir = dir

	if move_dir.length() > 0.01:
		velocity.x = move_dir.x * speed
		velocity.z = move_dir.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 8.0 * delta)

	facing_pivot.look_at(facing_pivot.global_position + dir, Vector3.UP)

	if attack_cooldown_timer <= 0.0 and dist <= RANGED_MAX and player.has_method("take_damage"):
		_fire_projectile(dir)
		attack_cooldown_timer = attack_cooldown
		_play_attack_swing()

func _fire_projectile(dir: Vector3) -> void:
	var proj = ProjectileScene.instantiate()
	get_parent().add_child(proj)
	proj.global_position = global_position + Vector3(0, 1.2, 0) + dir * (0.8 * radius_mult)
	proj.travel = dir * RANGED_PROJECTILE_SPEED
	proj.damage = attack_damage
	proj.source = self

func _play_attack_swing() -> void:
	if arm_tween != null and arm_tween.is_valid():
		arm_tween.kill()
	right_shoulder.rotation.x = 0.0
	right_elbow.rotation.x = 0.0
	arm_tween = create_tween()
	arm_tween.tween_property(right_shoulder, "rotation:x", deg_to_rad(110.0), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	arm_tween.parallel().tween_property(right_elbow, "rotation:x", deg_to_rad(65.0), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	arm_tween.tween_property(right_shoulder, "rotation:x", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	arm_tween.parallel().tween_property(right_elbow, "rotation:x", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _animate_body(delta: float) -> void:
	var horiz := Vector2(velocity.x, velocity.z).length()
	if horiz > 0.3:
		walk_phase += delta * horiz * 3.0
		var swing := sin(walk_phase) * 0.45
		left_hip.rotation.x = swing
		right_hip.rotation.x = -swing
		left_shoulder.rotation.x = -swing * 0.6
		left_knee.rotation.x = -maxf(0.0, cos(walk_phase)) * 0.9
		right_knee.rotation.x = -maxf(0.0, -cos(walk_phase)) * 0.9
		left_elbow.rotation.x = -maxf(0.0, -cos(walk_phase)) * 0.4
		visual_root.position.y = absf(sin(walk_phase)) * 0.05
	else:
		left_hip.rotation.x = lerp(left_hip.rotation.x, 0.0, delta * 8.0)
		right_hip.rotation.x = lerp(right_hip.rotation.x, 0.0, delta * 8.0)
		left_shoulder.rotation.x = lerp(left_shoulder.rotation.x, 0.0, delta * 8.0)
		left_knee.rotation.x = lerp(left_knee.rotation.x, 0.0, delta * 8.0)
		right_knee.rotation.x = lerp(right_knee.rotation.x, 0.0, delta * 8.0)
		left_elbow.rotation.x = lerp(left_elbow.rotation.x, 0.0, delta * 8.0)
		visual_root.position.y = lerp(visual_root.position.y, 0.0, delta * 8.0)

func take_damage(amount: float, _source = null) -> void:
	if dead:
		return
	hp = max(hp - amount, 0.0)
	if hp <= 0.0:
		dead = true
		died.emit()
		queue_free()
