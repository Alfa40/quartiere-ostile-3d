extends CharacterBody3D

const BASE_SPEED := 6.0
const GRAVITY := 20.0
const BASE_ATTACK_DAMAGE := 20.0
const BASE_ATTACK_COOLDOWN := 0.45
const FLASH_TIME := 0.12

signal hp_changed(current: float, max_hp: float)
signal died

@onready var facing_pivot: Node3D = $FacingPivot
@onready var attack_area: Area3D = $FacingPivot/AttackArea
@onready var attack_flash: MeshInstance3D = $FacingPivot/AttackArea/Flash
@onready var touch = get_node_or_null("../HUD/TouchControls")
@onready var main = get_parent()

@onready var visual_root: Node3D = $FacingPivot/VisualRoot
@onready var right_shoulder: Node3D = $FacingPivot/VisualRoot/RightShoulder
@onready var right_elbow: Node3D = $FacingPivot/VisualRoot/RightShoulder/RightElbow
@onready var left_shoulder: Node3D = $FacingPivot/VisualRoot/LeftShoulder
@onready var left_elbow: Node3D = $FacingPivot/VisualRoot/LeftShoulder/LeftElbow
@onready var left_hip: Node3D = $FacingPivot/VisualRoot/LeftHip
@onready var left_knee: Node3D = $FacingPivot/VisualRoot/LeftHip/LeftKnee
@onready var right_hip: Node3D = $FacingPivot/VisualRoot/RightHip
@onready var right_knee: Node3D = $FacingPivot/VisualRoot/RightHip/RightKnee

var max_hp := 100.0
var hp := 100.0
var speed_mult := 1.0
var attack_damage := BASE_ATTACK_DAMAGE
var attack_cooldown := BASE_ATTACK_COOLDOWN
var attack_reach_mult := 1.0:
	set(value):
		attack_reach_mult = value
		if is_inside_tree():
			attack_area.scale = Vector3.ONE * value
var facing := Vector3(0, 0, -1)
var attack_cooldown_timer := 0.0
var flash_timer := 0.0
var dead := false
var walk_phase := 0.0
var arm_tween: Tween = null

func _ready() -> void:
	add_to_group("player")
	hp_changed.emit(hp, max_hp)

func _physics_process(delta: float) -> void:
	if dead:
		velocity.y -= GRAVITY * delta
		move_and_slide()
		return

	_handle_movement(delta)
	_handle_attack(delta)
	_animate_body(delta)

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= GRAVITY * delta

	move_and_slide()

func _handle_movement(_delta: float) -> void:
	var input_dir := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		input_dir.z -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		input_dir.z += 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		input_dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		input_dir.x += 1.0

	if touch != null:
		var tv: Vector2 = touch.move_vector
		if tv.length() > 0.15:
			input_dir.x += tv.x
			input_dir.z += tv.y

	if input_dir.length() > 0.01:
		input_dir = input_dir.normalized()
		facing = input_dir
		facing_pivot.look_at(facing_pivot.global_position + facing, Vector3.UP)
		velocity.x = facing.x * BASE_SPEED * speed_mult
		velocity.z = facing.z * BASE_SPEED * speed_mult
	else:
		velocity.x = move_toward(velocity.x, 0.0, BASE_SPEED * speed_mult * 8.0 * _delta)
		velocity.z = move_toward(velocity.z, 0.0, BASE_SPEED * speed_mult * 8.0 * _delta)

func _handle_attack(delta: float) -> void:
	attack_cooldown_timer -= delta
	flash_timer -= delta
	if flash_timer <= 0.0:
		attack_flash.visible = false

	var attack_pressed: bool = Input.is_physical_key_pressed(KEY_SPACE) or (touch != null and touch.attack_held)
	if attack_pressed and attack_cooldown_timer <= 0.0:
		attack_cooldown_timer = attack_cooldown
		flash_timer = FLASH_TIME
		attack_flash.visible = true
		_play_attack_swing()
		for body in attack_area.get_overlapping_bodies():
			if (body.is_in_group("enemies") or body.is_in_group("park_objects")) and body.has_method("take_damage"):
				body.take_damage(attack_damage, self)

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
	if dead or DevMode.enabled:
		return
	hp = max(hp - amount, 0.0)
	hp_changed.emit(hp, max_hp)
	if main != null and main.has_method("on_player_damaged"):
		main.on_player_damaged(amount)
	if hp <= 0.0:
		dead = true
		died.emit()

func apply_draw_delay(delay: float) -> void:
	attack_cooldown_timer = max(attack_cooldown_timer, delay)

func heal(fraction: float) -> void:
	if dead:
		return
	hp = min(hp + max_hp * fraction, max_hp)
	hp_changed.emit(hp, max_hp)
