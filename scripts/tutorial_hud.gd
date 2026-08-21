extends CanvasLayer

signal exit_pressed

@onready var health_bar: ProgressBar = $HealthBar
@onready var hp_text: Label = $HealthBar/HPText
@onready var objective_label: Label = $ObjectiveLabel
@onready var progress_label: Label = $ProgressLabel
@onready var complete_panel: Control = $CompletePanel

const HEALTH_BAR_HEIGHT_PORTRAIT := 70.0
const HEALTH_BAR_HEIGHT_LANDSCAPE := 30.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	complete_panel.visible = false
	$ExitButton.pressed.connect(func(): exit_pressed.emit())
	$CompletePanel/Box/BackButton.pressed.connect(func(): exit_pressed.emit())
	get_viewport().size_changed.connect(_update_health_bar_shape)
	_update_health_bar_shape()

func _update_health_bar_shape() -> void:
	var vp := get_viewport().get_visible_rect().size
	var is_landscape := vp.x > vp.y
	var height := HEALTH_BAR_HEIGHT_LANDSCAPE if is_landscape else HEALTH_BAR_HEIGHT_PORTRAIT
	health_bar.offset_bottom = health_bar.offset_top + height

func on_player_hp_changed(current: float, max_hp: float) -> void:
	health_bar.max_value = max_hp
	health_bar.value = current
	hp_text.text = "%d / %d" % [int(current), int(max_hp)]

func set_objective(text: String) -> void:
	objective_label.text = text

func set_progress(current: int, total: int) -> void:
	progress_label.text = "Passo %d di %d" % [current, total]

func show_complete() -> void:
	objective_label.text = ""
	progress_label.text = ""
	complete_panel.visible = true
