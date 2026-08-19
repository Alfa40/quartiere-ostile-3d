extends CanvasLayer

@onready var hp_label: Label = $HPLabel
@onready var zone_label: Label = $ZoneLabel
@onready var money_label: Label = $MoneyLabel
@onready var message_label: Label = $MessageLabel
@onready var pause_panel: Control = $PausePanel
@onready var pause_stats_label: Label = $PausePanel/Box/StatsLabel
@onready var gameover_panel: Control = $GameOverPanel
@onready var gameover_stats_label: Label = $GameOverPanel/Box/StatsLabel

var main: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	main = get_parent()
	pause_panel.visible = false
	gameover_panel.visible = false
	$PausePanel/Box/ResumeButton.pressed.connect(_on_resume_pressed)
	$PausePanel/Box/RestartButton.pressed.connect(_on_restart_pressed)
	$PausePanel/Box/MainMenuButton.pressed.connect(_on_main_menu_pressed)
	$GameOverPanel/Box/RestartButton.pressed.connect(_on_restart_pressed)
	$GameOverPanel/Box/MainMenuButton.pressed.connect(_on_main_menu_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			if gameover_panel.visible:
				return
			toggle_pause()

func toggle_pause() -> void:
	set_paused(not get_tree().paused)

func set_paused(value: bool) -> void:
	get_tree().paused = value
	pause_panel.visible = value
	if value:
		pause_stats_label.text = main.get_stats_text()

func show_game_over() -> void:
	get_tree().paused = true
	gameover_stats_label.text = main.get_stats_text()
	gameover_panel.visible = true

func _on_resume_pressed() -> void:
	set_paused(false)

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	SaveData.report_run(main.zone, int(main.money))
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func on_player_hp_changed(current: float, max_hp: float) -> void:
	hp_label.text = "HP: %d / %d" % [int(current), int(max_hp)]

func show_message(text: String) -> void:
	message_label.text = text

func update_zone(zone: int, zone_name: String) -> void:
	zone_label.text = "Zona %d — %s" % [zone, zone_name]

func update_money(amount: float) -> void:
	money_label.text = "Soldi: %d€" % int(amount)
