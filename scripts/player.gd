extends CharacterBody3D

const BASE_SPEED := 6.0
const GRAVITY := 20.0
const BASE_ATTACK_DAMAGE := 20.0
const BASE_ATTACK_COOLDOWN := 0.45
const FLASH_TIME := 0.12
# Leggera vibrazione tattile quando il player subisce danni (dispositivi
# mobili con supporto Vibration API; su iOS Safari non ha effetto per un
# limite della piattaforma, non del gioco).
const DAMAGE_VIBRATE_MS := 60

signal hp_changed(current: float, max_hp: float)
signal died
# Emesso quando un'arma "pesante" (mazze/martelli in mischia, lanciagranate/
# lanciarazzi da fuoco — vedi is_melee_heavy/is_firearm_heavy, impostati da
# main.gd in base all'arma equipaggiata) colpisce o spara: main.gd lo
# ascolta per consumare un po' più fame (vedi HUNGER_HEAVY_HIT_COST).
signal heavy_hit_landed

@onready var facing_pivot: Node3D = $FacingPivot
@onready var attack_area: Area3D = $FacingPivot/AttackArea
@onready var attack_flash: MeshInstance3D = $FacingPivot/AttackArea/Flash
@onready var firearm_flash: MeshInstance3D = $FacingPivot/FirearmFlash
@onready var aim_line: MeshInstance3D = $FacingPivot/AimLine
@onready var firearm_bar: Node3D = $StatusBars/FirearmBar
@onready var firearm_bar_fill: MeshInstance3D = $StatusBars/FirearmBar/FillPivot/Fill
@onready var touch = get_node_or_null("../HUD/TouchControls")
@onready var main = get_parent()

const STATUS_BAR_WIDTH := 0.7

@onready var anim_player: AnimationPlayer = $FacingPivot/VisualRoot/CharacterModel/AnimationPlayer
@onready var body_mesh: MeshInstance3D = get_node("FacingPivot/VisualRoot/CharacterModel/character-male-a/Skeleton3D/body-mesh")

var max_hp := 100.0
var hp := 100.0
var speed_mult := 1.0
var attack_damage := BASE_ATTACK_DAMAGE
var attack_cooldown := BASE_ATTACK_COOLDOWN
# Forza della respinta sui nemici colpiti in mischia: 0 per pugni/coltelli e
# per le armi bianche troppo leggere per averla (vedi
# MeleeWeapons.KNOCKBACK_CATEGORIES).
var attack_knockback := 0.0
var attack_reach_mult := 1.0:
	set(value):
		attack_reach_mult = value
		if is_inside_tree():
			attack_area.scale = Vector3.ONE * value
var facing := Vector3(0, 0, -1)
var attack_cooldown_timer := 0.0
var flash_timer := 0.0
var dead := false

# Fame (vedi main.gd, _update_hunger): moltiplicatori ricalcolati ogni
# frame in base al livello attuale di fame, 1.0 a fame piena. hunger_
# speed_mult moltiplica direttamente la velocità di movimento (0.6 a fame
# zero = -40%); hunger_time_mult è il reciproco (fino a ~1.667) e va
# applicato quando un cooldown/tempo di estrazione viene AVVIATO, non
# mentre è già in conto alla rovescia — così un'azione già iniziata non
# rallenta o accelera a metà per un cambio di fame nel frattempo.
var hunger_speed_mult := 1.0
var hunger_time_mult := 1.0
# Impostati da main.gd in base alla categoria dell'arma mischia/da fuoco
# attualmente equipaggiata (vedi _apply_weapon_stats/_apply_firearm_stats):
# mazze/martelli in mischia, lanciagranate/lanciarazzi da fuoco.
var is_melee_heavy := false
var is_firearm_heavy := false

const AIM_CONE_DEGREES := 32.0
const FIREARM_FLASH_TIME := 0.08
const THROW_SPEED := 24.0
const DEFAULT_AIM_LINE_LENGTH := 6.0
const ThrownWeaponScene := preload("res://scenes/ThrownWeapon.tscn")
const BulletScene := preload("res://scenes/Bullet.tscn")
const GrenadeScene := preload("res://scenes/Grenade.tscn")
const LobbedGrenadeScene := preload("res://scenes/LobbedGrenade.tscn")
const ARC_GRAVITY := 20.0
# L'angolo di lancio delle granate (a mano o da lanciagranate) dipende da
# quanto tempo si tiene ferma la mira senza interromperla (last_aim_hold_frac,
# azzerato ogni volta che si smette di mirare): appena si comincia a mirare
# l'angolo è basso e la granata cade quasi subito; tenendo la mira ferma
# l'angolo sale fino a un massimo a mo' di mortaio, lenta ma vicina. La
# potenza di lancio resta fissa (derivata dalla gittata potenziabile
# "Portata"), è solo l'angolo a variare.
const LOB_MIN_ANGLE_DEGREES := 8.0
const LOB_MAX_ANGLE_DEGREES := 82.0
const AIM_MAGNITUDE_DEADZONE := 0.15
const ARC_LINE_SEGMENTS := 10
# L'arma resta "in mano" (pronta, ricarica/tempo tra i colpi in corso) finché
# il player mira di tanto in tanto; dopo tanti secondi consecutivi senza mai
# toccare il joystick di mira viene riposta: ricarica e cooldown si
# congelano, e la volta successiva che si mira serve di nuovo il tempo di
# estrazione, come alla prima equipaggiata.
const HOLSTER_TIMEOUT := 15.0

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
var firearm_bullet_speed := 40.0
var firearm_spread_degrees := 2.0
var firearm_pellet_count := 1
var firearm_pellet_spread_degrees := 0.0
var firearm_aim_line_length := DEFAULT_AIM_LINE_LENGTH
# "bullet" (proiettile normale), "grenade_straight" (granata dritta come i
# lanciarazzi), "grenade_lobbed" (granata a parabola con rimbalzo, come i
# lanciagranate). Le armi esplosive/speciali riusano gli stessi tipi di
# granata (frag/molotov/cluster/stordente/fumogena/puzzosa) delle armi da lancio.
var firearm_projectile_type := "bullet"
var firearm_grenade_type := ""
var firearm_explosion_radius := 3.0
var firearm_burn_duration := 0.0
var firearm_burn_dps := 0.0
var firearm_cluster_count := 0
var firearm_cluster_radius := 0.0
var firearm_stun_duration := 0.0

var firearm_ammo_in_mag := 0
var firearm_fire_timer := 0.0
var firearm_reload_timer := 0.0
var firearm_reloading := false
var firearm_flash_timer := 0.0
var last_aim_dir := Vector3(0, 0, -1)
# Non è "quanto è spinto lo stick di mira" ma "da quanto tempo si sta
# mirando ininterrottamente" (vedi _handle_firearm): l'angolo dei lanci a
# parabola sale più si tiene ferma la mira, non più la si spinge a fondo.
var last_aim_hold_frac := 0.0
var _aim_hold_time := 0.0
const AIM_HOLD_MAX_TIME := 1.2
var _burst_shots_remaining := 0
var _burst_timer := 0.0
var _burst_aim_dir := Vector3(0, 0, -1)
var _burst_aim_hold_frac := 0.0
var _arc_line_segments: Array = []
var weapon_holstered := true
var holster_timer := 0.0

func equip_firearm(id: String, damage: float, cooldown: float, range_val: float, draw_time: float, magazine_size: int, reload_time: float, fire_mode: String, burst_count: int = 1, burst_delay: float = 0.0, bullet_speed: float = 40.0, spread_degrees: float = 2.0, pellet_count: int = 1, pellet_spread_degrees: float = 0.0, aim_line_length: float = DEFAULT_AIM_LINE_LENGTH, projectile_type: String = "bullet", grenade_type: String = "", explosion_radius: float = 3.0, burn_duration: float = 0.0, burn_dps: float = 0.0, cluster_count: int = 0, cluster_radius: float = 0.0, stun_duration: float = 0.0) -> void:
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
	firearm_bullet_speed = bullet_speed
	firearm_spread_degrees = spread_degrees
	firearm_pellet_count = pellet_count
	firearm_pellet_spread_degrees = pellet_spread_degrees
	firearm_aim_line_length = aim_line_length
	firearm_projectile_type = projectile_type
	firearm_grenade_type = grenade_type
	firearm_explosion_radius = explosion_radius
	firearm_burn_duration = burn_duration
	firearm_burn_dps = burn_dps
	firearm_cluster_count = cluster_count
	firearm_cluster_radius = cluster_radius
	firearm_stun_duration = stun_duration
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
var throwable_stun_duration := 0.0
var throwable_aim_line_length := DEFAULT_AIM_LINE_LENGTH
var active_sticky_grenade: Node3D = null

func equip_throwable(id: String, damage: float, cooldown: float, range_val: float, draw_time: float, grenade_type: String = "", explosion_radius: float = 3.0, burn_duration: float = 0.0, burn_dps: float = 0.0, cluster_count: int = 0, cluster_radius: float = 0.0, aim_line_length: float = DEFAULT_AIM_LINE_LENGTH, stun_duration: float = 0.0) -> void:
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
	throwable_aim_line_length = aim_line_length
	throwable_stun_duration = stun_duration

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

func _throw_weapon(direction: Vector3, magnitude: float = 1.0) -> void:
	if throwable_id == "":
		return
	var reserve: int = main.get_throwable_reserve_ammo(throwable_id) if main != null and main.has_method("get_throwable_reserve_ammo") else 0
	if reserve <= 0:
		return
	if main != null and main.has_method("consume_throwable_reserve_ammo"):
		main.consume_throwable_reserve_ammo(throwable_id, 1)
	throw_cooldown_timer = throwable_cooldown * hunger_time_mult
	var proj: Area3D
	if throwable_grenade_type != "":
		# Le granate lanciate a mano seguono la stessa logica a parabola dei
		# lanciagranate: stessa scena, stesso angolo derivato dal joystick.
		proj = LobbedGrenadeScene.instantiate()
		get_parent().add_child(proj)
		proj.grenade_type = throwable_grenade_type
		proj.explosion_radius = throwable_explosion_radius
		proj.burn_duration = throwable_burn_duration
		proj.burn_dps = throwable_burn_dps
		proj.cluster_count = throwable_cluster_count
		proj.cluster_radius = throwable_cluster_radius
		proj.stun_duration = throwable_stun_duration
		if throwable_grenade_type == "sticky":
			proj.stuck.connect(_on_grenade_stuck.bind(proj))
		proj.global_position = global_position + Vector3(0, 1.0, 0) + direction * 0.8
		var angle_rad := _lob_angle_from_magnitude(magnitude)
		var speed: float = sqrt(max(throwable_range, 1.0) * ARC_GRAVITY)
		proj.arc_velocity = direction * (speed * cos(angle_rad)) + Vector3(0, speed * sin(angle_rad), 0)
	else:
		proj = ThrownWeaponScene.instantiate()
		get_parent().add_child(proj)
		proj.global_position = global_position + Vector3(0, 1.0, 0) + direction * 1.0
		proj.travel = direction * THROW_SPEED
		proj.max_distance = throwable_range
	proj.damage = throwable_damage
	proj.source = self
	_burst_shots_remaining = 0

func _on_grenade_stuck(proj: Node3D) -> void:
	active_sticky_grenade = proj

func _ready() -> void:
	add_to_group("player")
	hp_changed.emit(hp, max_hp)
	if CheckpointData.player_body_color != "":
		apply_body_color(Color(CheckpointData.player_body_color))

# Solo il mesh del corpo (non della testa, che condivide la stessa texture
# "colormap" del modello Kenney): un duplicato del materiale originale così
# la texture resta intatta e il colore scelto si moltiplica sopra, invece
# di sostituirla con un colore piatto.
func apply_body_color(color: Color) -> void:
	var base_mat: StandardMaterial3D = body_mesh.mesh.surface_get_material(0)
	var mat: StandardMaterial3D = base_mat.duplicate()
	mat.albedo_color = color
	body_mesh.set_surface_override_material(0, mat)

func face_direction(dir: Vector3) -> void:
	if dir.length() < 0.0001:
		return
	facing = dir.normalized()
	facing_pivot.look_at(facing_pivot.global_position + facing, Vector3.UP)

func _physics_process(delta: float) -> void:
	if dead:
		velocity.y -= GRAVITY * delta
		move_and_slide()
		return

	_handle_movement(delta)
	_handle_attack(delta)
	_handle_firearm(delta)
	_animate_body(delta)
	_update_status_bars()

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
		velocity.x = facing.x * BASE_SPEED * speed_mult * hunger_speed_mult
		velocity.z = facing.z * BASE_SPEED * speed_mult * hunger_speed_mult
	else:
		velocity.x = move_toward(velocity.x, 0.0, BASE_SPEED * speed_mult * hunger_speed_mult * 8.0 * _delta)
		velocity.z = move_toward(velocity.z, 0.0, BASE_SPEED * speed_mult * hunger_speed_mult * 8.0 * _delta)

func _handle_attack(delta: float) -> void:
	attack_cooldown_timer -= delta
	flash_timer -= delta
	if flash_timer <= 0.0:
		attack_flash.visible = false

	var attack_pressed: bool = Input.is_physical_key_pressed(KEY_SPACE) or (touch != null and touch.attack_held)
	if attack_pressed and attack_cooldown_timer <= 0.0:
		attack_cooldown_timer = attack_cooldown * hunger_time_mult
		flash_timer = FLASH_TIME
		attack_flash.visible = true
		_play_attack_swing()
		var landed_hit := false
		for body in attack_area.get_overlapping_bodies():
			if (body.is_in_group("enemies") or body.is_in_group("park_objects") or body.is_in_group("night_gods")) and body.has_method("take_damage"):
				body.take_damage(attack_damage, self)
				landed_hit = true
				if attack_knockback > 0.0 and body.is_in_group("enemies") and body.has_method("apply_knockback"):
					var push_dir: Vector3 = body.global_position - global_position
					body.apply_knockback(push_dir, attack_knockback)
		if landed_hit and is_melee_heavy:
			heavy_hit_landed.emit()

func _handle_firearm(delta: float) -> void:
	firearm_flash_timer -= delta
	if firearm_flash_timer <= 0.0:
		firearm_flash.visible = false

	var aim: Vector2 = touch.aim_vector if touch != null else Vector2.ZERO
	var aiming := aim.length() > AIM_MAGNITUDE_DEADZONE
	if aiming:
		last_aim_dir = Vector3(aim.x, 0, aim.y).normalized()
		_aim_hold_time = min(_aim_hold_time + delta, AIM_HOLD_MAX_TIME)
		last_aim_hold_frac = clampf(_aim_hold_time / AIM_HOLD_MAX_TIME, 0.0, 1.0)
		facing_pivot.look_at(facing_pivot.global_position + last_aim_dir, Vector3.UP)
	else:
		_aim_hold_time = 0.0

	if firearm_id != "" or throwable_id != "":
		if aiming:
			if weapon_holstered:
				firearm_fire_timer = max(firearm_fire_timer, firearm_draw_time * hunger_time_mult)
				throw_cooldown_timer = max(throw_cooldown_timer, throwable_draw_time * hunger_time_mult)
			weapon_holstered = false
			holster_timer = HOLSTER_TIMEOUT
		elif not weapon_holstered:
			holster_timer -= delta
			if holster_timer <= 0.0:
				weapon_holstered = true

	if not weapon_holstered:
		firearm_fire_timer -= delta
		throw_cooldown_timer -= delta

	if aiming and (firearm_id != "" or throwable_id != ""):
		# Il lancio armato (se presente) ha priorità di anteprima sull'arma
		# da fuoco, stessa priorità usata al momento del rilascio.
		var lobbed_range := 0.0
		var use_arc := false
		if throw_armed and throwable_grenade_type != "":
			use_arc = true
			lobbed_range = throwable_range
		elif firearm_id != "" and firearm_projectile_type == "grenade_lobbed" and not throw_armed:
			use_arc = true
			lobbed_range = firearm_range
		if use_arc:
			aim_line.visible = false
			var angle_rad := _lob_angle_from_magnitude(last_aim_hold_frac)
			var speed: float = sqrt(max(lobbed_range, 1.0) * ARC_GRAVITY)
			_update_arc_aim_line(angle_rad, speed)
		else:
			_hide_arc_aim_line()
			var line_length := DEFAULT_AIM_LINE_LENGTH
			if firearm_id != "":
				line_length = max(line_length, firearm_aim_line_length)
			if throwable_id != "":
				line_length = max(line_length, throwable_aim_line_length)
			aim_line.visible = true
			aim_line.scale = Vector3(1.0, 1.0, line_length)
			aim_line.position = Vector3(0, 1.0, -line_length * 0.5)
	else:
		aim_line.visible = false
		_hide_arc_aim_line()

	var release_pending: bool = touch != null and touch.fire_release_pending
	if touch != null:
		touch.fire_release_pending = false

	# Il lancio armato ha priorità sull'arma da fuoco equipaggiata sullo stesso rilascio.
	if release_pending and throw_armed:
		_throw_weapon(last_aim_dir, last_aim_hold_frac)
		throw_armed = false
		release_pending = false

	if firearm_id == "":
		return

	# L'arma da fuoco resta inutilizzabile solo mentre un'arma da lancio è
	# effettivamente armata (pronta a essere lanciata al rilascio del
	# joystick di mira), non semplicemente perché una è equipaggiata: prima
	# un'arma da lancio equipaggiata ma non armata bloccava per sempre
	# l'arma da fuoco, un vero e proprio blocco del sistema di mira.
	if throw_armed:
		return

	# Riposta: niente ricarica né sparo finché non si torna a mirare (a quel
	# punto scatta di nuovo il tempo di estrazione, gestito sopra).
	if weapon_holstered:
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
			_fire_firearm(_burst_aim_dir, _burst_aim_hold_frac)
			_burst_shots_remaining -= 1
			_burst_timer = firearm_burst_delay
			if firearm_ammo_in_mag <= 0:
				_burst_shots_remaining = 0
		return

	if aiming and firearm_fire_mode == "auto" and firearm_fire_timer <= 0.0:
		var target := _find_enemy_in_aim_cone(last_aim_dir)
		if target != null:
			_fire_firearm(last_aim_dir, last_aim_hold_frac)

	if release_pending and firearm_fire_timer <= 0.0:
		if firearm_fire_mode == "single":
			_fire_firearm(last_aim_dir, last_aim_hold_frac)
		elif firearm_fire_mode == "burst":
			_burst_aim_dir = last_aim_dir
			_burst_aim_hold_frac = last_aim_hold_frac
			_fire_firearm(_burst_aim_dir, _burst_aim_hold_frac)
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

func _fire_firearm(aim_dir: Vector3, aim_hold_frac: float = 1.0) -> void:
	firearm_ammo_in_mag -= 1
	firearm_fire_timer = firearm_cooldown * hunger_time_mult
	firearm_flash_timer = FIREARM_FLASH_TIME
	if is_firearm_heavy:
		heavy_hit_landed.emit()
	match firearm_projectile_type:
		"grenade_straight":
			_fire_grenade_straight(aim_dir)
		"grenade_lobbed":
			_fire_grenade_lobbed(aim_dir, aim_hold_frac)
		_:
			_fire_bullets(aim_dir)

func _fire_bullets(aim_dir: Vector3) -> void:
	var shots: int = max(firearm_pellet_count, 1)
	var half_spread: float = (firearm_pellet_spread_degrees if shots > 1 else firearm_spread_degrees) * 0.5
	for i in range(shots):
		var dir := aim_dir
		if half_spread > 0.0:
			dir = aim_dir.rotated(Vector3.UP, deg_to_rad(randf_range(-half_spread, half_spread)))
		var proj: Area3D = BulletScene.instantiate()
		get_parent().add_child(proj)
		proj.global_position = global_position + Vector3(0, 1.0, 0) + dir * 0.8
		proj.travel = dir * firearm_bullet_speed
		proj.damage = firearm_damage
		proj.max_distance = firearm_range
		proj.source = self

func _configure_firearm_grenade(proj: Area3D) -> void:
	proj.grenade_type = firearm_grenade_type
	proj.explosion_radius = firearm_explosion_radius
	proj.burn_duration = firearm_burn_duration
	proj.burn_dps = firearm_burn_dps
	proj.cluster_count = firearm_cluster_count
	proj.cluster_radius = firearm_cluster_radius
	proj.stun_duration = firearm_stun_duration
	proj.damage = firearm_damage
	proj.source = self

func _fire_grenade_straight(aim_dir: Vector3) -> void:
	var proj: Area3D = GrenadeScene.instantiate()
	_configure_firearm_grenade(proj)
	get_parent().add_child(proj)
	proj.global_position = global_position + Vector3(0, 1.0, 0) + aim_dir * 0.8
	proj.travel = aim_dir * firearm_bullet_speed
	proj.max_distance = firearm_range

func _fire_grenade_lobbed(aim_dir: Vector3, aim_hold_frac: float = 1.0) -> void:
	var proj: Area3D = LobbedGrenadeScene.instantiate()
	_configure_firearm_grenade(proj)
	get_parent().add_child(proj)
	proj.global_position = global_position + Vector3(0, 1.0, 0) + aim_dir * 0.8
	# Potenza di lancio fissa, derivata dalla gittata potenziabile con
	# "Portata" (v² = R_max·g, la gittata massima che si otterrebbe
	# esattamente a 45°); l'angolo invece dipende da quanto tempo si è tenuta
	# ferma la mira (aim_hold_frac): R(θ) = R_max·sin(2θ) — mira appena
	# iniziata o tenuta a lungo danno entrambe poca gittata (rispettivamente
	# un tiro basso e rapido, o un mortaio lento), a metà tempo di carica
	# (45°) la gittata è massima.
	var angle_rad := _lob_angle_from_magnitude(aim_hold_frac)
	var speed: float = sqrt(max(firearm_range, 1.0) * ARC_GRAVITY)
	var horizontal_speed: float = speed * cos(angle_rad)
	var vertical_speed: float = speed * sin(angle_rad)
	proj.arc_velocity = aim_dir * horizontal_speed + Vector3(0, vertical_speed, 0)

func _lob_angle_from_magnitude(magnitude: float) -> float:
	var m: float = clampf(magnitude, 0.0, 1.0)
	var angle_deg: float = LOB_MIN_ANGLE_DEGREES + m * (LOB_MAX_ANGLE_DEGREES - LOB_MIN_ANGLE_DEGREES)
	return deg_to_rad(angle_deg)

func _ensure_arc_line_segments() -> void:
	if not _arc_line_segments.is_empty():
		return
	for i in range(ARC_LINE_SEGMENTS):
		var seg := MeshInstance3D.new()
		seg.mesh = aim_line.mesh
		seg.set_surface_override_material(0, aim_line.get_surface_override_material(0))
		seg.visible = false
		facing_pivot.add_child(seg)
		_arc_line_segments.append(seg)

# Disegna un'anteprima curva della parabola (invece della linea di mira
# dritta) campionando la stessa fisica usata dal proiettile reale, dal
# lancio fino al primo contatto col terreno.
func _update_arc_aim_line(angle_rad: float, speed: float) -> void:
	_ensure_arc_line_segments()
	var horizontal_speed: float = speed * cos(angle_rad)
	var vertical_speed: float = speed * sin(angle_rad)
	var t_flight: float = (2.0 * vertical_speed / ARC_GRAVITY) if vertical_speed > 0.0 else 0.0
	if t_flight <= 0.0:
		_hide_arc_aim_line()
		return
	var points: Array[Vector3] = []
	for i in range(ARC_LINE_SEGMENTS + 1):
		var t: float = t_flight * float(i) / float(ARC_LINE_SEGMENTS)
		var z: float = -horizontal_speed * t
		var y: float = 1.0 + vertical_speed * t - 0.5 * ARC_GRAVITY * t * t
		points.append(Vector3(0, y, z))
	for i in range(ARC_LINE_SEGMENTS):
		var seg: MeshInstance3D = _arc_line_segments[i]
		var p0: Vector3 = points[i]
		var p1: Vector3 = points[i + 1]
		var seg_vec: Vector3 = p1 - p0
		var seg_len: float = seg_vec.length()
		seg.visible = true
		seg.position = (p0 + p1) * 0.5
		seg.scale = Vector3(1.0, 1.0, max(seg_len, 0.001))
		if seg_len > 0.0001:
			seg.rotation = Vector3(atan2(seg_vec.y, -seg_vec.z), 0, 0)

func _hide_arc_aim_line() -> void:
	for seg in _arc_line_segments:
		seg.visible = false

func _start_reload() -> void:
	if firearm_reloading:
		return
	firearm_reloading = true
	firearm_reload_timer = firearm_reload_time * hunger_time_mult

func _finish_reload() -> void:
	firearm_reloading = false
	var reserve: int = main.get_firearm_reserve_ammo(firearm_id) if main != null and main.has_method("get_firearm_reserve_ammo") else 0
	var loaded: int = min(firearm_magazine_size, reserve)
	firearm_ammo_in_mag = loaded
	if main != null and main.has_method("consume_firearm_reserve_ammo"):
		main.consume_firearm_reserve_ammo(firearm_id, loaded)

const ATTACK_ANIMS := ["attack-melee-left", "attack-melee-right"]

func _play_attack_swing() -> void:
	anim_player.play(ATTACK_ANIMS[randi() % ATTACK_ANIMS.size()])

# Un solo AnimationPlayer guida tutto lo scheletro: mentre un'animazione di
# attacco è in corso non va interrotta per tornare a cammino/riposo, che
# riprende da soli non appena l'attacco finisce (le clip di attacco non
# sono in loop, vedi ATTACK_ANIMS).
func _animate_body(_delta: float) -> void:
	if anim_player.current_animation in ATTACK_ANIMS and anim_player.is_playing():
		return
	var horiz := Vector2(velocity.x, velocity.z).length()
	anim_player.play("walk" if horiz > 0.3 else "idle")

func _update_status_bars() -> void:
	if touch != null:
		touch.attack_ready_frac = 1.0 - clamp(attack_cooldown_timer / max(attack_cooldown, 0.001), 0.0, 1.0)

	if firearm_id == "":
		firearm_bar.visible = false
	else:
		firearm_bar.visible = true
		var frac: float
		if firearm_reloading:
			frac = 1.0 - clamp(firearm_reload_timer / max(firearm_reload_time, 0.001), 0.0, 1.0)
		else:
			frac = 1.0 - clamp(firearm_fire_timer / max(firearm_cooldown, 0.001), 0.0, 1.0)
		_set_bar_fill(firearm_bar_fill, frac)

func _set_bar_fill(fill: MeshInstance3D, frac: float) -> void:
	var f: float = clamp(frac, 0.0, 1.0)
	fill.scale.x = f
	fill.position.x = STATUS_BAR_WIDTH * f * 0.5

func take_damage(amount: float, _source = null) -> void:
	if dead or DevMode.enabled:
		return
	hp = max(hp - amount, 0.0)
	hp_changed.emit(hp, max_hp)
	Input.vibrate_handheld(DAMAGE_VIBRATE_MS)
	if main != null and main.hud != null and main.hud.has_method("flash_damage"):
		main.hud.flash_damage(amount, max_hp)
	if main != null and main.has_method("on_player_damaged"):
		main.on_player_damaged(amount)
	if hp <= 0.0:
		dead = true
		died.emit()

func apply_draw_delay(delay: float) -> void:
	attack_cooldown_timer = max(attack_cooldown_timer, delay * hunger_time_mult)

func heal(fraction: float) -> void:
	if dead:
		return
	hp = min(hp + max_hp * fraction, max_hp)
	hp_changed.emit(hp, max_hp)
