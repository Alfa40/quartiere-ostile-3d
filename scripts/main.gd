extends Node3D

const EnemyScene := preload("res://scenes/Enemy.tscn")

const BASE_ENEMIES := 5
const PER_ZONE := 2
const MAX_ENEMIES_PER_ZONE := 16
const MAX_CONCURRENT := 6
const SPAWN_INTERVAL := 0.9

const HP_PER_ZONE := 0.033
const DAMAGE_PER_ZONE := 0.023
const SPEED_PER_ZONE := 0.018
const COOLDOWN_FACTOR_PER_ZONE := 0.011
const MIN_COOLDOWN := 0.35
const MONEY_PER_ZONE := 0.025
const BASE_ENEMY_COOLDOWN := 1.0

const ZONE_NAMES := [
	"Ai margini del quartiere", "Vicoli stretti", "Cortili abbandonati",
	"Il blocco centrale", "Zona rossa", "Il fondo del quartiere",
	"Oltre i confini conosciuti", "Il centro città in fiamme",
	"Le torri abbandonate", "L'ultimo isolato",
]

const SPAWN_POINTS := [
	Vector3(0, 0, -18), Vector3(-18, 0, -10), Vector3(18, 0, -10),
	Vector3(-18, 0, 10), Vector3(18, 0, 10), Vector3(0, 0, -12),
]

@onready var hud = $HUD
@onready var player = $Player

var zone := 1
var money := 0.0
var enemies_defeated := 0
var run_start_msec := 0

var zone_enemies_total := 0
var zone_enemies_spawned := 0
var zone_enemies_alive := 0
var spawn_timer := 0.0
var zone_transitioning := false

func _ready() -> void:
	run_start_msec = Time.get_ticks_msec()
	player.hp_changed.connect(hud.on_player_hp_changed)
	player.died.connect(_on_player_died)
	hud.update_money(money)
	_start_zone()

func _start_zone() -> void:
	zone_transitioning = false
	zone_enemies_total = min(BASE_ENEMIES + PER_ZONE * (zone - 1), MAX_ENEMIES_PER_ZONE)
	zone_enemies_spawned = 0
	zone_enemies_alive = 0
	spawn_timer = 0.0
	var zone_name: String = ZONE_NAMES[min(zone - 1, ZONE_NAMES.size() - 1)]
	hud.update_zone(zone, zone_name)
	hud.show_message("Zona %d iniziata: ripulisci il quartiere!" % zone)
	SaveData.report_run(zone, int(money))

func _process(delta: float) -> void:
	if Input.is_physical_key_pressed(KEY_R):
		get_tree().paused = false
		get_tree().reload_current_scene()

	if zone_transitioning or player.dead:
		return

	if zone_enemies_spawned < zone_enemies_total:
		spawn_timer -= delta
		if spawn_timer <= 0.0 and zone_enemies_alive < MAX_CONCURRENT:
			_spawn_enemy()
			spawn_timer = SPAWN_INTERVAL

func _spawn_enemy() -> void:
	var enemy = EnemyScene.instantiate()
	add_child(enemy)
	enemy.position = SPAWN_POINTS[randi() % SPAWN_POINTS.size()]

	var hp_mult := 1.0 + HP_PER_ZONE * (zone - 1)
	var dmg_mult := 1.0 + DAMAGE_PER_ZONE * (zone - 1)
	var speed_mult := 1.0 + SPEED_PER_ZONE * (zone - 1)
	var cooldown: float = max(BASE_ENEMY_COOLDOWN * (1.0 - COOLDOWN_FACTOR_PER_ZONE * (zone - 1)), MIN_COOLDOWN)
	enemy.configure(hp_mult, dmg_mult, speed_mult, cooldown)
	enemy.died.connect(_on_enemy_died)

	zone_enemies_spawned += 1
	zone_enemies_alive += 1

func _on_enemy_died() -> void:
	zone_enemies_alive -= 1
	enemies_defeated += 1
	var money_mult := 1.0 + MONEY_PER_ZONE * (zone - 1)
	var reward := roundi(randf_range(10.0, 18.0) * money_mult)
	money += reward
	hud.update_money(money)
	hud.show_message("Nemico sconfitto (+%d€)" % reward)

	if zone_enemies_spawned >= zone_enemies_total and zone_enemies_alive <= 0 and not zone_transitioning:
		_complete_zone()

func _complete_zone() -> void:
	zone_transitioning = true
	hud.show_message("Zona %d ripulita! Prossima zona in arrivo..." % zone)
	await get_tree().create_timer(2.5, false).timeout
	zone += 1
	_start_zone()

func _on_player_died() -> void:
	hud.show_message("Sei stato steso.")
	SaveData.report_run(zone, int(money))
	hud.show_game_over()

func get_stats_text() -> String:
	var elapsed_sec := int((Time.get_ticks_msec() - run_start_msec) / 1000.0)
	var minutes := elapsed_sec / 60
	var seconds := elapsed_sec % 60
	return "Zona raggiunta: %d\nSoldi guadagnati: %d€\nNemici sconfitti: %d\nTempo: %02d:%02d" % [zone, int(money), enemies_defeated, minutes, seconds]
