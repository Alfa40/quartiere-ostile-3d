extends Control

func _ready() -> void:
	$Box/StartButton.pressed.connect(_on_start_pressed)
	_refresh_best_label()

func _refresh_best_label() -> void:
	if SaveData.best_zone <= 0:
		$Box/BestLabel.text = "Nessuna partita completata ancora"
	else:
		$Box/BestLabel.text = "Miglior risultato: Zona %d — %d€ guadagnati" % [SaveData.best_zone, SaveData.best_money]

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
