extends CanvasLayer

@onready var hp_label: Label = $HPLabel
@onready var message_label: Label = $MessageLabel

func on_player_hp_changed(current: float, max_hp: float) -> void:
	hp_label.text = "HP: %d / %d" % [int(current), int(max_hp)]

func show_message(text: String) -> void:
	message_label.text = text
