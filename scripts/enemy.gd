extends CharacterBody3D

const BASE_SPEED := 3.2
const BASE_MAX_HP := 40.0
const BASE_ATTACK_DAMAGE := 8.0
const BASE_ATTACK_COOLDOWN := 1.0
const ATTACK_RANGE := 1.6
const GRAVITY := 20.0

signal died

@onready var facing_pivot: Node3D = $FacingPivot

var speed := BASE_SPEED
var max_hp := BASE_MAX_HP
var hp := BASE_MAX_HP
var attack_damage := BASE_ATTACK_DAMAGE
var attack_cooldown := BASE_ATTACK_COOLDOWN

var attack_cooldown_timer := 0.0
var dead := false
var player: Node3D = null

func _ready() -> void:
	add_to_group("enemies")
	call_deferred("_find_player")

func configure(hp_mult: float, dmg_mult: float, speed_mult: float, cooldown_seconds: float) -> void:
	max_hp = BASE_MAX_HP * hp_mult
	hp = max_hp
	attack_damage = BASE_ATTACK_DAMAGE * dmg_mult
	speed = BASE_SPEED * speed_mult
	attack_cooldown = cooldown_seconds

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

	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()

	if dist > ATTACK_RANGE:
		var dir := to_player.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		facing_pivot.look_at(facing_pivot.global_position + dir, Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 8.0 * delta)
		facing_pivot.look_at(facing_pivot.global_position + to_player.normalized(), Vector3.UP)
		if attack_cooldown_timer <= 0.0 and player.has_method("take_damage"):
			player.take_damage(attack_damage, self)
			attack_cooldown_timer = attack_cooldown

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= GRAVITY * delta

	move_and_slide()

func take_damage(amount: float, _source = null) -> void:
	if dead:
		return
	hp = max(hp - amount, 0.0)
	if hp <= 0.0:
		dead = true
		died.emit()
		queue_free()
