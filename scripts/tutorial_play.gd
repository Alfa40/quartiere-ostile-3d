extends Node3D

const WaypointScene := preload("res://scenes/Waypoint.tscn")
const EnemyScene := preload("res://scenes/Enemy.tscn")
const AlberoScene := preload("res://scenes/Albero.tscn")
const LampioneScene := preload("res://scenes/Lampione.tscn")

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
}

@onready var hud = $HUD
@onready var player = $Player

var steps: Array = []
var step_index := 0

func _ready() -> void:
	hud.exit_pressed.connect(_on_exit)
	player.hp_changed.connect(hud.on_player_hp_changed)
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

func _advance_step() -> void:
	step_index += 1
	_start_step()

func _on_exit() -> void:
	get_tree().change_scene_to_file("res://scenes/Tutorial.tscn")
