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
const THROW_SPEED := 24.0
const BULLET_SPEED := 45.0
const ThrownWeaponScene := preload("res://scenes/ThrownWeapon.tscn")
const BulletScene := preload("res://scenes/Bullet.tscn")
const GrenadeScene := preload("res://scenes/Grenade.tscn")

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

var throwable_id := ""
var throwable_damage := 0.0
var throwable_cooldown := 0.5
var throwable_range := 14.0
var throwable_draw_time := 0.0
var throw_armed := false
var throw_cooldown_timer := 0.0
var throwable_grenade_type := ""
var throwable_explosion_radius := 3.0
var throwable_burn_duration := 0.0
var throwable_burn_dps := 0.0
var throwable_cluster_count := 0
var throwable_cluster_radius := 0.0
var active_sticky_grenade: Node3D = null

func equip_throwable(id: String, damage: float, cooldown: float, range_val: float, draw_time: float, grenade_type: String = "", explosion_radius: float = 3.0, burn_duration: float = 0.0, burn_dps: float = 0.0, cluster_count: int = 0, cluster_radius: float = 0.0) -> void:
	throwable_id = id
	throwable_damage = damage
	throwable_cooldown = cooldown
	throwable_range = range_val
	throwable_draw_time = draw_time
	throw_cooldown_timer = max(throw_cooldown_timer, draw_time)
	throw_armed = false
	throwable_grenade_type = grenade_type
	throwable_explosion_radius = explosion_radius
	throwable_burn_duration = burn_duration
	throwable_burn_dps = burn_dps
	throwable_cluster_count = cluster_count
	throwable_cluster_radius = cluster_radius

func unequip_throwable() -> void:
	throwable_id = ""
	throw_armed = false
	throwable_grenade_type = ""

func arm_throw() -> void:
	# Se una granata appiccicosa è già stata lanciata e attende l'ordine di
	# detonazione, questo stesso tasto la fa esplodere invece di armarne un'altra.
	if active_sticky_grenade != null and is_instance_valid(active_sticky_grenade):
		active_sticky_grenade.detonate()
		active_sticky_grenade = null
		return
	if throwable_id == "" or throw_cooldown_timer > 0.0:
		return
	if main != null and main.has_method("get_throwable_reserve_ammo") and main.get_throwable_reserve_ammo(throwable_id) <= 0:
		return
	throw_armed = true

func _throw_weapon(direction: Vector3) -> void:
	if throwable_id == "":
		return
	var reserve: int = main.get_throwable_reserve_ammo(throwable_id) if main != null and main.has_method("get_throwable_reserve_ammo") else 0
	if reserve <= 0:
		return
	if main != null and main.has_method("consume_throwable_reserve_ammo"):
		main.consume_throwable_reserve_ammo(throwable_id, 1)
	throw_cooldown_timer = throwable_cooldown
	var proj: Area3D
	if throwable_grenade_type != "":
		proj = GrenadeScene.instantiate()
		get_parent().add_child(proj)
		proj.grenade_type = throwable_grenade_type
		proj.explosion_radius = throwable_explosion_radius
		proj.burn_duration = throwable_burn_duration
		proj.burn_dps = throwable_burn_dps
		proj.cluster_count = throwable_cluster_count
		proj.cluster_radius = throwable_cluster_radius
		if throwable_grenade_type == "sticky":
			proj.stuck.connect(_on_grenade_stuck.bind(proj))
	else:
		proj = ThrownWeaponScene.instantiate()
		get_parent().add_child(proj)
	proj.global_position = global_position + Vector3(0, 1.0, 0) + direction * 1.0
	proj.travel = direction * THROW_SPEED
	proj.damage = throwable_damage
	proj.max_distance = throwable_range
	proj.source = self
	_burst_shots_remaining = 0

func _on_grenade_stuck(proj: Node3D) -> void:
	active_sticky_grenade = proj

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
	throw_cooldown_timer -= delta
	if firearm_flash_timer <= 0.0:
		firearm_flash.visible = false

	var aim: Vector2 = touch.aim_vector if touch != null else Vector2.ZERO
	var aiming := aim.length() > 0.15
	if aiming:
		last_aim_dir = Vector3(aim.x, 0, aim.y).normalized()
		facing_pivot.look_at(facing_pivot.global_position + last_aim_dir, Vector3.UP)

	var release_pending: bool = touch != null and touch.fire_release_pending
	if touch != null:
		touch.fire_release_pending = false

	# Il lancio armato ha priorità sull'arma da fuoco equipaggiata sullo stesso rilascio.
	if release_pending and throw_armed:
		_throw_weapon(last_aim_dir)
		throw_armed = false
		release_pending = false

	if firearm_id == "":
		return

	if firearm_reloading:
		firearm_reload_timer -= delta
		if firearm_reload_timer <= 0.0:
			_finish_reload()
		return

	if firearm_ammo_in_mag <= 0:
		_burst_shots_remaining = 0
		_start_reload()
		return

	if _burst_shots_remaining > 0:
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			_fire_firearm(_burst_aim_dir)
			_burst_shots_remaining -= 1
			_burst_timer = firearm_burst_delay
			if firearm_ammo_in_mag <= 0:
				_burst_shots_remaining = 0
		return

	if aiming and firearm_fire_mode == "auto" and firearm_fire_timer <= 0.0:
		var target := _find_enemy_in_aim_cone(last_aim_dir)
		if target != null:
			_fire_firearm(last_aim_dir)

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
	var proj: Area3D = BulletScene.instantiate()
	get_parent().add_child(proj)
	proj.global_position = global_position + Vector3(0, 1.0, 0) + aim_dir * 0.8
	proj.travel = aim_dir * BULLET_SPEED
	proj.damage = firearm_damage
	proj.max_distance = firearm_range
	proj.source = self

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
