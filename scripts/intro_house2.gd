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
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
