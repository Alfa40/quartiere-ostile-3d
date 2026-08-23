extends Node3D

const WaypointScene := preload("res://scenes/Waypoint.tscn")
const EnemyScene := preload("res://scenes/Enemy.tscn")
const AlberoScene := preload("res://scenes/Albero.tscn")
const LampioneScene := preload("res://scenes/Lampione.tscn")
const Firearms := preload("res://scripts/firearms.gd")
const Throwables := preload("res://scripts/throwables.gd")

const SECTIONS := {
	"movement": [
		{"type": "move", "pos": Vector3(0, 0, -8), "text": "Muoviti in avanti fino al punto luminoso"},
		{"type": "move", "pos": Vector3(-8, 0, -8), "text": "Ora vai a sinistra"},
		{"type": "move", "pos": Vector3(-8, 0, 0), "text": "Infine avvicinati a quest'ultimo punto"},
	],
	"attack": [
		{"type": "kill", "pos": Vector3(0, 0, -6), "text": "Sconfiggi il nemico: avvicinati e premi Spazio (o il pulsante rosso)"},
		{"type": "kill", "pos": Vector3(5, 0, -5), "text": "Un altro nemico: eliminalo"},
		{"type": "kill", "pos": Vector3(-5, 0, -5), "text": "Ultimo nemico: finiscilo"},
	],
	"materials": [
		{"type": "destroy", "scene": AlberoScene, "pos": Vector3(0, 0, -6), "hp": 80.0, "text": "Distruggi l'albero a colpi per ottenere legno"},
		{"type": "destroy", "scene": LampioneScene, "pos": Vector3(0, 0, -6), "hp": 60.0, "text": "Distruggi il lampione per ottenere metallo e cablaggi"},
	],
	"throwables": [
		{
			"type": "kill_with_throwable", "throwable_id": "granata", "pos": Vector3(0, 0, -8),
			"text": "Hai una granata! Tocca \"Lancia\" per armarla, poi mira col joystick a destra e rilascia per lanciarla: elimina il nemico",
		},
	],
	"explosives": [
		{
			"type": "kill_with_firearm", "firearm_id": "lanciagranate_improvvisato", "pos": Vector3(0, 0, -8),
			"text": "Hai un lanciagranate! Mira col joystick a destra e rilascia per sparare: elimina il nemico",
		},
	],
}

@onready var hud = $HUD
@onready var player = $Player
@onready var touch_controls = $HUD/TouchControls
@onready var throw_arm_button: Button = $HUD/ThrowArmButton

var steps: Array = []
var step_index := 0

func _ready() -> void:
	hud.exit_pressed.connect(_on_exit)
	player.hp_changed.connect(hud.on_player_hp_changed)
	throw_arm_button.pressed.connect(_on_throw_arm_pressed)
	steps = SECTIONS.get(TutorialState.section, SECTIONS["movement"])
	_start_step()

func _start_step() -> void:
	if step_index >= steps.size():
		hud.show_complete()
		return
	var step: Dictionary = steps[step_index]
	hud.set_objective(step.text)
	hud.set_progress(step_index + 1, steps.size())
	match step.type:
		"move":
			var wp = WaypointScene.instantiate()
			wp.position = step.pos
			add_child(wp)
			wp.reached.connect(_advance_step)
		"kill":
			var enemy = EnemyScene.instantiate()
			enemy.position = step.pos
			add_child(enemy)
			enemy.configure(1.0, 1.0, 1.0, 1.0)
			enemy.died.connect(_advance_step)
		"destroy":
			var obj = step.scene.instantiate()
			obj.position = step.pos
			obj.max_hp = step.hp
			add_child(obj)
			obj.destroyed.connect(_advance_step)
		"kill_with_throwable":
			touch_controls.aim_enabled = true
			throw_arm_button.visible = true
			_equip_practice_throwable(String(step.throwable_id))
			var enemy = EnemyScene.instantiate()
			enemy.position = step.pos
			add_child(enemy)
			enemy.configure(1.0, 1.0, 1.0, 1.0)
			enemy.died.connect(_advance_step)
		"kill_with_firearm":
			touch_controls.aim_enabled = true
			_equip_practice_firearm(String(step.firearm_id))
			var enemy = EnemyScene.instantiate()
			enemy.position = step.pos
			add_child(enemy)
			enemy.configure(1.0, 1.0, 1.0, 1.0)
			enemy.died.connect(_advance_step)

func _equip_practice_throwable(tid: String) -> void:
	var tups := {}
	var def: Dictionary = Throwables.WEAPONS[tid]
	player.equip_throwable(
		tid,
		Throwables.final_damage(tid, tups),
		Throwables.final_cooldown(tid, tups),
		Throwables.final_range(tid, tups),
		Throwables.final_draw_time(tid, tups),
		String(def.get("grenade_type", "")),
		float(def.get("explosion_radius", 3.0)),
		float(def.get("burn_duration", 0.0)),
		float(def.get("burn_dps", 0.0)),
		int(def.get("cluster_count", 0)),
		float(def.get("cluster_radius", 0.0)),
		Throwables.final_aim_line_length(tid, tups),
		float(def.get("stun_duration", 0.0)),
	)

func _equip_practice_firearm(fid: String) -> void:
	var fups := {}
	var def: Dictionary = Firearms.WEAPONS[fid]
	player.equip_firearm(
		fid,
		Firearms.final_damage(fid, fups),
		Firearms.final_cooldown(fid, fups),
		Firearms.final_range(fid, fups),
		Firearms.final_draw_time(fid, fups),
		int(def.magazine_size),
		float(def.reload_time),
		String(def.fire_mode),
		int(def.get("burst_count", 1)),
		float(def.get("burst_delay", 0.0)),
		Firearms.bullet_speed(fid),
		Firearms.final_spread_degrees(fid, fups),
		Firearms.pellet_count(fid),
		Firearms.final_pellet_spread_degrees(fid, fups),
		Firearms.final_aim_line_length(fid, fups),
		String(def.get("projectile_type", "bullet")),
		String(def.get("grenade_type", "")),
		float(def.get("explosion_radius", 3.0)),
		float(def.get("burn_duration", 0.0)),
		float(def.get("burn_dps", 0.0)),
		int(def.get("cluster_count", 0)),
		float(def.get("cluster_radius", 0.0)),
		float(def.get("stun_duration", 0.0)),
	)

# Munizioni infinite durante la pratica: qui si impara a mirare/armare/
# sparare/lanciare, non a gestire la scorta.
func get_firearm_reserve_ammo(_fid: String) -> int:
	return 999

func consume_firearm_reserve_ammo(_fid: String, _amount: int) -> void:
	pass

func get_throwable_reserve_ammo(_tid: String) -> int:
	return 999

func consume_throwable_reserve_ammo(_tid: String, _amount: int) -> void:
	pass

func _on_throw_arm_pressed() -> void:
	if player.active_sticky_grenade != null and is_instance_valid(player.active_sticky_grenade):
		player.arm_throw()
		return
	if player.throw_armed:
		player.throw_armed = false
		return
	player.arm_throw()

func _advance_step() -> void:
	step_index += 1
	_start_step()

func _on_exit() -> void:
	get_tree().change_scene_to_file("res://scenes/Tutorial.tscn")
