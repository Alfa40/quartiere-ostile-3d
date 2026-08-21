extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthBar
@onready var hp_text: Label = $HealthBar/HPText
@onready var zone_label: Label = $ZoneLabel
@onready var money_label: Label = $MoneyLabel
@onready var message_label: Label = $MessageLabel
@onready var pause_panel: Control = $PausePanel
@onready var pause_stats_label: Label = $PausePanel/Scroll/Box/StatsLabel
@onready var pause_inventory_label: Label = $PausePanel/Scroll/Box/InventoryLabel
@onready var gameover_panel: Control = $GameOverPanel
@onready var gameover_stats_label: Label = $GameOverPanel/Scroll/Box/StatsLabel
@onready var pause_button: Button = $PauseButton

var main: Node = null

const HEALTH_BAR_HEIGHT_PORTRAIT := 54.0
const HEALTH_BAR_HEIGHT_LANDSCAPE := 30.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	main = get_parent()
	pause_panel.visible = false
	gameover_panel.visible = false
	$PausePanel/Scroll/Box/ResumeButton.pressed.connect(_on_resume_pressed)
	$PausePanel/Scroll/Box/RestartButton.pressed.connect(_on_restart_pressed)
	$PausePanel/Scroll/Box/MainMenuButton.pressed.connect(_on_main_menu_pressed)
	$GameOverPanel/Scroll/Box/RestartButton.pressed.connect(_on_restart_pressed)
	$GameOverPanel/Scroll/Box/MainMenuButton.pressed.connect(_on_main_menu_pressed)
	pause_button.pressed.connect(toggle_pause)
	get_viewport().size_changed.connect(_update_health_bar_shape)
	_update_health_bar_shape()

func _update_health_bar_shape() -> void:
	var vp := get_viewport().get_visible_rect().size
	var is_landscape := vp.x > vp.y
	var height := HEALTH_BAR_HEIGHT_LANDSCAPE if is_landscape else HEALTH_BAR_HEIGHT_PORTRAIT
	health_bar.offset_bottom = health_bar.offset_top + height

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			if gameover_panel.visible:
				return
			toggle_pause()

func toggle_pause() -> void:
	if gameover_panel.visible:
		return
	set_paused(not get_tree().paused)

func set_paused(value: bool) -> void:
	get_tree().paused = value
	pause_panel.visible = value
	pause_button.visible = not value
	if value:
		pause_stats_label.text = main.get_stats_text()
		pause_inventory_label.text = main.get_inventory_text()

func show_game_over() -> void:
	get_tree().paused = true
	gameover_stats_label.text = main.get_stats_text()
	gameover_panel.visible = true
	pause_button.visible = false

func _on_resume_pressed() -> void:
	set_paused(false)

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	if not DevMode.enabled:
		SaveData.report_run(main.zone, int(main.money))
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func on_player_hp_changed(current: float, max_hp: float) -> void:
	health_bar.max_value = max_hp
	health_bar.value = current
	hp_text.text = "%d / %d" % [int(current), int(max_hp)]

func show_message(text: String) -> void:
	message_label.text = text

func update_zone(zone: int, zone_name: String) -> void:
	zone_label.text = "Zona %d — %s" % [zone, zone_name]

func update_money(amount: float) -> void:
	if DevMode.enabled:
		money_label.text = "Soldi: ∞"
	else:
		money_label.text = "Soldi: %d€" % int(amount)
