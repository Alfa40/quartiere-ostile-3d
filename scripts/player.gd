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
@onready var firearm_flash: MeshInstance3D = $FacingPivot/FirearmFlash
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

const AIM_CONE_DEGREES := 32.0
const FIREARM_FLASH_TIME := 0.08

var firearm_id := ""
var firearm_fire_mode := "auto"
var firearm_damage := 0.0
var firearm_cooldown := 0.5
var firearm_range := 14.0
var firearm_draw_time := 0.0
var firearm_magazine_size := 0
var firearm_reload_time := 1.0
var firearm_burst_count := 1
var firearm_burst_delay := 0.0

var firearm_ammo_in_mag := 0
var firearm_fire_timer := 0.0
var firearm_reload_timer := 0.0
var firearm_reloading := false
var firearm_flash_timer := 0.0
var last_aim_dir := Vector3(0, 0, -1)
var _burst_shots_remaining := 0
var _burst_timer := 0.0
var _burst_aim_dir := Vector3(0, 0, -1)

func equip_firearm(id: String, damage: float, cooldown: float, range_val: float, draw_time: float, magazine_size: int, reload_time: float, fire_mode: String, burst_count: int = 1, burst_delay: float = 0.0) -> void:
	firearm_id = id
	firearm_damage = damage
	firearm_cooldown = cooldown
	firearm_range = range_val
	firearm_draw_time = draw_time
	firearm_magazine_size = magazine_size
	firearm_reload_time = reload_time
	firearm_fire_mode = fire_mode
	firearm_burst_count = burst_count
	firearm_burst_delay = burst_delay
	firearm_ammo_in_mag = magazine_size
	firearm_reloading = false
	firearm_reload_timer = 0.0
	firearm_fire_timer = max(firearm_fire_timer, draw_time)
	_burst_shots_remaining = 0
	_burst_timer = 0.0

func unequip_firearm() -> void:
	firearm_id = ""
	firearm_ammo_in_mag = 0
	firearm_reloading = false
	_burst_shots_remaining = 0

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
	_handle_firearm(delta)
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

func _handle_firearm(delta: float) -> void:
	firearm_fire_timer -= delta
	firearm_flash_timer -= delta
	if firearm_flash_timer <= 0.0:
		firearm_flash.visible = false

	if firearm_id == "":
		if touch != null:
			touch.fire_release_pending = false
		return

	if firearm_reloading:
		firearm_reload_timer -= delta
		if firearm_reload_timer <= 0.0:
			_finish_reload()
		if touch != null:
			touch.fire_release_pending = false
		return

	if firearm_ammo_in_mag <= 0:
		if touch != null:
			touch.fire_release_pending = false
		_burst_shots_remaining = 0
		_start_reload()
		return

	if _burst_shots_remaining > 0:
		if touch != null:
			touch.fire_release_pending = false
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			_fire_firearm(_burst_aim_dir)
			_burst_shots_remaining -= 1
			_burst_timer = firearm_burst_delay
			if firearm_ammo_in_mag <= 0:
				_burst_shots_remaining = 0
		return

	var aim: Vector2 = touch.aim_vector if touch != null else Vector2.ZERO
	var aiming := aim.length() > 0.15

	if aiming:
		var aim_dir := Vector3(aim.x, 0, aim.y).normalized()
		last_aim_dir = aim_dir
		facing_pivot.look_at(facing_pivot.global_position + aim_dir, Vector3.UP)
		if firearm_fire_mode == "auto" and firearm_fire_timer <= 0.0:
			var target := _find_enemy_in_aim_cone(aim_dir)
			if target != null:
				_fire_firearm(aim_dir)

	var release_pending: bool = touch != null and touch.fire_release_pending
	if touch != null:
		touch.fire_release_pending = false
	if release_pending and firearm_fire_timer <= 0.0:
		if firearm_fire_mode == "single":
			_fire_firearm(last_aim_dir)
		elif firearm_fire_mode == "burst":
			_burst_aim_dir = last_aim_dir
			_fire_firearm(_burst_aim_dir)
			_burst_shots_remaining = firearm_burst_count - 1
			_burst_timer = firearm_burst_delay

func _find_enemy_in_aim_cone(aim_dir: Vector3) -> Node3D:
	var best: Node3D = null
	var best_dist := INF
	var cos_limit := cos(deg_to_rad(AIM_CONE_DEGREES))
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Node3D):
			continue
		var to_enemy: Vector3 = enemy.global_position - global_position
		to_enemy.y = 0.0
		var dist := to_enemy.length()
		if dist > firearm_range or dist < 0.001:
			continue
		var dot := aim_dir.dot(to_enemy.normalized())
		if dot < cos_limit:
			continue
		if dist < best_dist:
			best_dist = dist
			best = enemy
	return best

func _fire_firearm(aim_dir: Vector3) -> void:
	firearm_ammo_in_mag -= 1
	firearm_fire_timer = firearm_cooldown
	firearm_flash_timer = FIREARM_FLASH_TIME
	firearm_flash.visible = true
	var target := _find_enemy_in_aim_cone(aim_dir)
	if target != null and target.has_method("take_damage"):
		target.take_damage(firearm_damage, self)

func _start_reload() -> void:
	if firearm_reloading:
		return
	firearm_reloading = true
	firearm_reload_timer = firearm_reload_time

func _finish_reload() -> void:
	firearm_reloading = false
	var reserve: int = main.get_firearm_reserve_ammo(firearm_id) if main != null and main.has_method("get_firearm_reserve_ammo") else 0
	var loaded: int = min(firearm_magazine_size, reserve)
	firearm_ammo_in_mag = loaded
	if main != null and main.has_method("consume_firearm_reserve_ammo"):
		main.consume_firearm_reserve_ammo(firearm_id, loaded)

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
