extends Control

@onready var password_panel: Control = $PasswordPanel
@onready var password_edit: LineEdit = $PasswordPanel/Scroll/Box/PasswordEdit
@onready var error_label: Label = $PasswordPanel/Scroll/Box/ErrorLabel
@onready var keyboard: GridContainer = $PasswordPanel/Scroll/Box/Keyboard

func _ready() -> void:
	$Box/StartButton.pressed.connect(_on_start_pressed)
	$Box/TutorialButton.pressed.connect(_on_tutorial_pressed)
	$CreatorButton.pressed.connect(_on_creator_pressed)
	$PasswordPanel/Scroll/Box/BackspaceButton.pressed.connect(_on_backspace_pressed)
	$PasswordPanel/Scroll/Box/ConfirmButton.pressed.connect(_on_confirm_pressed)
	$PasswordPanel/Scroll/Box/CancelButton.pressed.connect(_on_cancel_pressed)
	password_edit.text_submitted.connect(func(_t): _on_confirm_pressed())
	for key in keyboard.get_children():
		key.pressed.connect(_on_key_pressed.bind(key.text))
	_refresh_best_label()
	if CheckpointData.resumed_from_continue:
		$Box/StartButton.text = "Continua partita (Zona %d)" % CheckpointData.zone

func _refresh_best_label() -> void:
	if SaveData.best_zone <= 0:
		$Box/BestLabel.text = "Nessuna partita completata ancora"
	else:
		$Box/BestLabel.text = "Miglior risultato: Zona %d — %d€ guadagnati" % [SaveData.best_zone, SaveData.best_money]

func _on_start_pressed() -> void:
	DevMode.enabled = false
	if CheckpointData.resumed_from_continue:
		get_tree().change_scene_to_file("res://scenes/Home.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_tutorial_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Tutorial.tscn")

func _on_creator_pressed() -> void:
	error_label.text = ""
	password_edit.text = ""
	password_panel.visible = true
	password_edit.grab_focus()

func _on_cancel_pressed() -> void:
	password_panel.visible = false

func _on_key_pressed(letter: String) -> void:
	password_edit.text += letter
	password_edit.caret_column = password_edit.text.length()

func _on_backspace_pressed() -> void:
	if password_edit.text.length() > 0:
		password_edit.text = password_edit.text.substr(0, password_edit.text.length() - 1)
		password_edit.caret_column = password_edit.text.length()

func _on_confirm_pressed() -> void:
	if DevMode.check(password_edit.text):
		DevMode.enabled = true
		get_tree().change_scene_to_file("res://scenes/Main.tscn")
	else:
		error_label.text = "Password errata"
		password_edit.text = ""
		password_edit.grab_focus()
