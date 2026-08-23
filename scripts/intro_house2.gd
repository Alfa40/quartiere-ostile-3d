extends Node3D

# Interno della casa dell'npc, ultimo passo del tutorial giocabile
# obbligatorio: qui l'npc dona (narrativamente) la tenda e il banco della
# casa, entrambi già sempre posseduti fin dall'inizio del gioco vero — non
# c'è altro stato da sbloccare. Il player esce da solo: una volta fuori il
# tutorial è concluso e comincia il gioco vero, nel quartiere davanti alla
# propria tenda.

@onready var door_trigger: Area3D = $DoorTrigger

func _ready() -> void:
	door_trigger.body_entered.connect(_on_door_entered)

func _on_door_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	TutorialProgress.set_stage("done")
	# Il gioco vero comincia sempre da zero: i soldi/materiali donati per il
	# tutorial e la pistola comprata al banco (solo per farla provare) non
	# devono passare alla partita reale.
	CheckpointData.money = 0
	CheckpointData.materials = {"legno": 0, "metallo": 0, "cablaggi": 0}
	CheckpointData.owned_firearms = {}
	CheckpointData.firearm_upgrades = {}
	CheckpointData.firearm_ammo = {}
	CheckpointData.equipped_firearm = ""
	CheckpointData.save_checkpoint(CheckpointData.zone, 0, CheckpointData.materials, CheckpointData.upgrades)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
