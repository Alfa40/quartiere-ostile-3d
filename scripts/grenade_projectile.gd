extends Area3D

const GrenadeUtils := preload("res://scripts/grenade_utils.gd")
const FireZoneScene := preload("res://scenes/FireZone.tscn")
const BlindZoneScene := preload("res://scenes/BlindZone.tscn")
const StinkZoneScene := preload("res://scenes/StinkZone.tscn")

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

func _ready() -> void:
	collision_layer = 0
	collision_mask = 4
	monitoring = true
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _stuck:
		return
	var step := travel * delta
	global_position += step
	_traveled += step.length()
	if _traveled >= max_distance:
		_arrive()

func _on_body_entered(_body: Node3D) -> void:
	if _stuck:
		return
	_arrive()

func _arrive() -> void:
	if grenade_type == "sticky":
		_stuck = true
		travel = Vector3.ZERO
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
			_spawn_fire_zone()
		"fumogena":
			_spawn_blind_zone()
		"stordente":
			_apply_stun_aoe()
		"puzzosa":
			if damage > 0.0:
				GrenadeUtils.explode_damage(get_tree(), global_position, explosion_radius, damage, source)
			_spawn_stink_zone()
		_:
			GrenadeUtils.explode_damage(get_tree(), global_position, explosion_radius, damage, source)
	queue_free()

func _explode_cluster() -> void:
	var center := global_position
	GrenadeUtils.explode_damage(get_tree(), center, explosion_radius, damage, source)
	for i in range(cluster_count):
		var angle := (TAU / float(cluster_count)) * float(i)
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * cluster_radius
		GrenadeUtils.explode_damage(get_tree(), center + offset, explosion_radius, damage, source)

func _spawn_fire_zone() -> void:
	var zone: Node3D = FireZoneScene.instantiate()
	get_parent().add_child(zone)
	zone.global_position = global_position
	zone.radius = explosion_radius
	zone.duration = burn_duration
	zone.dps = burn_dps
	zone.source = source

func _spawn_stink_zone() -> void:
	var zone: Node3D = StinkZoneScene.instantiate()
	get_parent().add_child(zone)
	zone.global_position = global_position
	zone.radius = explosion_radius
	zone.duration = burn_duration
	zone.dps = burn_dps
	zone.source = source

func _spawn_blind_zone() -> void:
	var zone: Node3D = BlindZoneScene.instantiate()
	get_parent().add_child(zone)
	zone.global_position = global_position
	zone.radius = explosion_radius
	zone.duration = burn_duration

func _apply_stun_aoe() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node3D and enemy.has_method("apply_stun"):
			if enemy.global_position.distance_to(global_position) <= explosion_radius:
				enemy.apply_stun(stun_duration)
