extends Node3D

@onready var hud = $HUD
@onready var player = $Player

var enemies_remaining := 0

func _ready() -> void:
	player.hp_changed.connect(hud.on_player_hp_changed)
	player.died.connect(_on_player_died)

	var enemies := get_tree().get_nodes_in_group("enemies")
	enemies_remaining = enemies.size()
	for enemy in enemies:
		enemy.died.connect(_on_enemy_died)

func _process(_delta: float) -> void:
	if Input.is_physical_key_pressed(KEY_R):
		get_tree().reload_current_scene()

func _on_enemy_died() -> void:
	enemies_remaining -= 1
	if enemies_remaining <= 0:
		hud.show_message("Quartiere ripulito! Premi R per rigiocare.")
	else:
		hud.show_message("Nemico sconfitto — ne restano %d. R per riavviare." % enemies_remaining)

func _on_player_died() -> void:
	hud.show_message("Sei stato steso. Premi R per riprovare.")
