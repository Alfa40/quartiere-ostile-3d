extends Node3D

# Prima parte del tutorial giocabile obbligatorio (solo al primissimo avvio
# del gioco): movimento, distruzione di un ostacolo (materiali), due nemici
# diversi, poi la porta della prima casa (banco della casa + armi da fuoco).

const WaypointScene := preload("res://scenes/Waypoint.tscn")
const EnemyScene := preload("res://scenes/Enemy.tscn")
const AlberoScene := preload("res://scenes/Albero.tscn")

# Soldi/materiali donati entrando in casa: pochi, bastano solo per la
# pistola più forte già presente sul banco (la Magnum, 1050€ + 32 metallo),
# con un margine minimo.
const HOUSE_MONEY_GRANT := 1150
const HOUSE_MATERIAL_GRANT := 45

@onready var hud = $HUD
@onready var player = $Player
@onready var door_trigger: Area3D = $DoorTrigger

var steps: Array = []
var step_index := 0
var _door_ready := false

func _ready() -> void:
	player.hp_changed.connect(hud.on_player_hp_changed)
	door_trigger.body_entered.connect(_on_door_entered)
	steps = [
		{"type": "move", "pos": Vector3(0, 0, 10), "text": "Benvenuto! Muoviti con il joystick (o WASD) fino al punto luminoso"},
		{"type": "move", "pos": Vector3(-6, 0, 4), "text": "Ottimo. Ora vai verso il prossimo punto"},
		{"type": "destroy", "scene": AlberoScene, "pos": Vector3(0, 0, -1), "hp": 80.0, "text": "Avvicinati e premi il tasto rosso (o Spazio) per colpire: distruggi l'albero e raccogli legno"},
		{"type": "kill", "archetype": "balordo", "pos": Vector3(0, 0, -7), "text": "Un nemico! Colpiscilo per sconfiggerlo e proseguire"},
		{"type": "kill", "archetype": "nervoso", "pos": Vector3(0, 0, -13), "text": "Un altro nemico, più rapido: eliminalo per continuare"},
		{"type": "walk_to_house", "text": "Bene! Ora raggiungi la casa davanti a te"},
	]
	_start_step()

func _start_step() -> void:
	if step_index >= steps.size():
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
		"destroy":
			var obj = step.scene.instantiate()
			obj.position = step.pos
			obj.max_hp = step.hp
			add_child(obj)
			obj.destroyed.connect(_advance_step)
		"kill":
			var enemy = EnemyScene.instantiate()
			enemy.position = step.pos
			add_child(enemy)
			enemy.configure(1.0, 1.0, 1.0, 1.0, String(step.archetype))
			enemy.died.connect(_advance_step)
		"walk_to_house":
			_door_ready = true

func _advance_step() -> void:
	# Pausa di 2s a fine di ogni passo: lascia al player il tempo di leggere
	# e ambientarsi prima che compaia il prossimo obiettivo.
	await get_tree().create_timer(2.0).timeout
	step_index += 1
	_start_step()

func _on_door_entered(body: Node3D) -> void:
	if not _door_ready or not body.is_in_group("player"):
		return
	_door_ready = false
	hud.set_objective("")
	hud.set_progress(0, 0)
	CheckpointData.start_new_game(1)
	CheckpointData.money = HOUSE_MONEY_GRANT
	CheckpointData.materials = {"legno": HOUSE_MATERIAL_GRANT, "metallo": HOUSE_MATERIAL_GRANT, "cablaggi": HOUSE_MATERIAL_GRANT}
	# Salvato subito: se il gioco viene chiuso proprio qui e riaperto, si deve
	# ritrovare i soldi/materiali appena donati, non ripartire da zero.
	CheckpointData.save_checkpoint(1, int(CheckpointData.money), CheckpointData.materials, CheckpointData.upgrades)
	TutorialProgress.set_stage("house1")
	get_tree().change_scene_to_file("res://scenes/IntroHouse1.tscn")
