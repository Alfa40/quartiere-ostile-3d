extends Area3D

const GrenadeUtils := preload("res://scripts/grenade_utils.gd")
const FireZoneScene := preload("res://scenes/FireZone.tscn")
const BlindZoneScene := preload("res://scenes/BlindZone.tscn")
const StinkZoneScene := preload("res://scenes/StinkZone.tscn")
const ExplosionFlashScene := preload("res://scenes/ExplosionFlash.tscn")

const FLASH_COLOR_DAMAGE := Color(1.0, 0.55, 0.2, 0.85)
const FLASH_COLOR_STUN := Color(0.75, 0.85, 1.0, 0.85)

signal stuck

var travel := Vector3.ZERO
var damage := 20.0
var max_distance := 12.0
var source: Node = null

# "frag" (solo danno ad area), "molotov" (danno ad area + zona infuocata),
# "sticky" (si appiccica e detona solo quando richiamata da detonate()),
# "cluster" (esplosione centrale + più sotto-esplosioni attorno),
# "fumogena" (nessun danno, crea una nube che acceca i nemici al suo interno),
# "stordente" (nessun danno, stordisce sul colpo i nemici presenti nell'area),
# "puzzosa" (nessun danno da impatto, crea un'area con danno costante nel tempo).
var grenade_type := "frag"
var explosion_radius := 3.0
var burn_duration := 0.0
var burn_dps := 0.0
var cluster_count := 0
var cluster_radius := 0.0
var stun_duration := 0.0

var _traveled := 0.0
var _stuck := false
var _stuck_body: Node3D = null
var _stuck_offset := Vector3.ZERO

func _ready() -> void:
	collision_layer = 0
	collision_mask = 4
	monitoring = true
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _stuck:
		if _stuck_body != null and is_instance_valid(_stuck_body):
			global_position = _stuck_body.global_position + _stuck_offset
		return
	var step := travel * delta
	global_position += step
	_traveled += step.length()
	if _traveled >= max_distance:
		_arrive()

func _on_body_entered(body: Node3D) -> void:
	if _stuck:
		return
	if grenade_type == "sticky" and body.is_in_group("enemies"):
		_stuck_body = body
	_arrive()

func _arrive() -> void:
	if grenade_type == "sticky":
		_stuck = true
		travel = Vector3.ZERO
		if _stuck_body != null and is_instance_valid(_stuck_body):
			_stuck_offset = global_position - _stuck_body.global_position
		stuck.emit()
		return
	_explode()

func detonate() -> void:
	_explode()

func _explode() -> void:
	match grenade_type:
		"cluster":
			_explode_cluster()
		"molotov":
			GrenadeUtils.explode_damage(get_tree(), global_position, explosion_radius, damage, source)
			_spawn_flash(global_position, FLASH_COLOR_DAMAGE)
			_spawn_fire_zone()
		"fumogena":
			_spawn_blind_zone()
		"stordente":
			_apply_stun_aoe()
			_spawn_flash(global_position, FLASH_COLOR_STUN)
		"puzzosa":
			if damage > 0.0:
				GrenadeUtils.explode_damage(get_tree(), global_position, explosion_radius, damage, source)
			_spawn_stink_zone()
		"sticky", "frag", _:
			GrenadeUtils.explode_damage(get_tree(), global_position, explosion_radius, damage, source)
			_spawn_flash(global_position, FLASH_COLOR_DAMAGE)
	queue_free()

func _explode_cluster() -> void:
	var center := global_position
	GrenadeUtils.explode_damage(get_tree(), center, explosion_radius, damage, source)
	_spawn_flash(center, FLASH_COLOR_DAMAGE)
	for i in range(cluster_count):
		var angle := (TAU / float(cluster_count)) * float(i)
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * cluster_radius
		var sub_pos := center + offset
		GrenadeUtils.explode_damage(get_tree(), sub_pos, explosion_radius, damage, source)
		_spawn_flash(sub_pos, FLASH_COLOR_DAMAGE)

func _spawn_flash(pos: Vector3, color: Color) -> void:
	var flash: Node3D = ExplosionFlashScene.instantiate()
	flash.radius = explosion_radius
	flash.color = color
	get_parent().add_child(flash)
	flash.global_position = pos

func _spawn_fire_zone() -> void:
	var zone: Node3D = FireZoneScene.instantiate()
	zone.radius = explosion_radius
	zone.duration = burn_duration
	zone.dps = burn_dps
	zone.source = source
	get_parent().add_child(zone)
	zone.global_position = global_position

func _spawn_stink_zone() -> void:
	var zone: Node3D = StinkZoneScene.instantiate()
	zone.radius = explosion_radius
	zone.duration = burn_duration
	zone.dps = burn_dps
	zone.source = source
	get_parent().add_child(zone)
	zone.global_position = global_position

func _spawn_blind_zone() -> void:
	var zone: Node3D = BlindZoneScene.instantiate()
	zone.radius = explosion_radius
	zone.duration = burn_duration
	get_parent().add_child(zone)
	zone.global_position = global_position

func _apply_stun_aoe() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node3D and enemy.has_method("apply_stun"):
			if enemy.global_position.distance_to(global_position) <= explosion_radius:
				enemy.apply_stun(stun_duration)
