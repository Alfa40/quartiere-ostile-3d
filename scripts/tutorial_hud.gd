extends CanvasLayer

signal exit_pressed

@onready var hp_label: Label = $HPLabel
@onready var objective_label: Label = $ObjectiveLabel
@onready var progress_label: Label = $ProgressLabel
@onready var complete_panel: Control = $CompletePanel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	complete_panel.visible = false
	$ExitButton.pressed.connect(func(): exit_pressed.emit())
	$CompletePanel/Box/BackButton.pressed.connect(func(): exit_pressed.emit())

func on_player_hp_changed(current: float, max_hp: float) -> void:
	hp_label.text = "HP: %d / %d" % [int(current), int(max_hp)]

func set_objective(text: String) -> void:
	objective_label.text = text

func set_progress(current: int, total: int) -> void:
	progress_label.text = "Passo %d di %d" % [current, total]

func show_complete() -> void:
	objective_label.text = ""
	progress_label.text = ""
	complete_panel.visible = true
