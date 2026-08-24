extends Control

@onready var password_panel: Control = $PasswordPanel
@onready var password_edit: LineEdit = $PasswordPanel/Scroll/Box/PasswordEdit
@onready var error_label: Label = $PasswordPanel/Scroll/Box/ErrorLabel
@onready var keyboard: GridContainer = $PasswordPanel/Scroll/Box/Keyboard
@onready var confirm_reset_panel: Control = $ConfirmResetPanel

var _pending_reset_slot := 0

# Estratta a parte (pura, nessun cambio scena) per poterla testare senza
# innescare un vero change_scene_to_file.
static func intro_redirect_scene_path() -> String:
	match TutorialProgress.intro_stage:
		"house1":
			return "res://scenes/IntroHouse1.tscn"
		"field2":
			return "res://scenes/IntroField2.tscn"
		"house2":
			return "res://scenes/IntroHouse2.tscn"
		_:
			return "res://scenes/IntroField1.tscn"

func _ready() -> void:
	# Tutorial giocabile obbligatorio al primissimo avvio del gioco: finché
	# non è stato completato, il menu normale resta bloccato e si riprende
	# sempre dal passo in cui il player si era fermato.
	if not TutorialProgress.is_done():
		# Ogni stage dopo "field1" presuppone lo slot 1 (creato entrando nella
		# prima casa) già selezionato, coi suoi progressi ricaricati.
		if TutorialProgress.intro_stage != "field1":
			CheckpointData.select_slot(1)
		# Deferito: chiamare change_scene_to_file mentre questo stesso nodo è
		# ancora nel bel mezzo del proprio _ready() (la scena iniziale appena
		# caricata) può entrare in conflitto con l'albero della scena.
		get_tree().call_deferred("change_scene_to_file", intro_redirect_scene_path())
		return

	$Box/TutorialButton.pressed.connect(_on_tutorial_pressed)
	$Box/SettingsButton.pressed.connect(_on_settings_pressed)
	$CreatorButton.pressed.connect(_on_creator_pressed)
	$PasswordPanel/Scroll/Box/BackspaceButton.pressed.connect(_on_backspace_pressed)
	$PasswordPanel/Scroll/Box/ConfirmButton.pressed.connect(_on_confirm_pressed)
	$PasswordPanel/Scroll/Box/CancelButton.pressed.connect(_on_cancel_pressed)
	password_edit.text_submitted.connect(func(_t): _on_confirm_pressed())
	for key in keyboard.get_children():
		key.pressed.connect(_on_key_pressed.bind(key.text))

	for slot in range(1, CheckpointData.SLOT_COUNT + 1):
		var row := get_node("Box/SlotsBox/Slot_%d" % slot)
		(row.get_node("ActionButton") as Button).pressed.connect(_on_slot_action_pressed.bind(slot))
		(row.get_node("ResetButton") as Button).pressed.connect(_on_slot_reset_pressed.bind(slot))
	$ConfirmResetPanel/Box/ConfirmButton.pressed.connect(_on_confirm_reset_pressed)
	$ConfirmResetPanel/Box/CancelButton.pressed.connect(_on_cancel_reset_pressed)

	_refresh_best_label()
	_refresh_slots()

func _refresh_best_label() -> void:
	if SaveData.best_zone <= 0:
		$Box/BestLabel.text = "Nessuna partita completata ancora"
	else:
		$Box/BestLabel.text = "Miglior risultato: Zona %d — %d€ guadagnati" % [SaveData.best_zone, SaveData.best_money]

func _refresh_slots() -> void:
	for slot in range(1, CheckpointData.SLOT_COUNT + 1):
		var row := get_node("Box/SlotsBox/Slot_%d" % slot)
		var info: Label = row.get_node("InfoLabel")
		var action_btn: Button = row.get_node("ActionButton")
		var reset_btn: Button = row.get_node("ResetButton")
		var data: Dictionary = CheckpointData.slot_info(slot)
		if data.empty:
			info.text = "Partita %d: vuota" % slot
			action_btn.text = "Nuova partita"
			reset_btn.visible = false
		else:
			info.text = "Partita %d: Zona %d — %d€" % [slot, int(data.zone), int(data.money)]
			action_btn.text = "Continua"
			reset_btn.visible = true

func _on_slot_action_pressed(slot: int) -> void:
	DevMode.enabled = false
	var data: Dictionary = CheckpointData.slot_info(slot)
	if data.empty:
		CheckpointData.start_new_game(slot)
		get_tree().change_scene_to_file("res://scenes/Main.tscn")
	else:
		CheckpointData.select_slot(slot)
		if CheckpointData.resumed_from_continue:
			get_tree().change_scene_to_file("res://scenes/Home.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_slot_reset_pressed(slot: int) -> void:
	_pending_reset_slot = slot
	confirm_reset_panel.visible = true

func _on_confirm_reset_pressed() -> void:
	confirm_reset_panel.visible = false
	if _pending_reset_slot <= 0:
		return
	CheckpointData.start_new_game(_pending_reset_slot)
	_pending_reset_slot = 0
	_refresh_slots()

func _on_cancel_reset_pressed() -> void:
	confirm_reset_panel.visible = false
	_pending_reset_slot = 0

func _on_tutorial_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Tutorial.tscn")

func _on_settings_pressed() -> void:
	$SettingsPanel.open()

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
		password_panel.visible = false
		# La Modalità Creator vive nel proprio slot isolato (mai 1..SLOT_COUNT):
		# così le partite create/continuate in creator non toccano mai i
		# salvataggi né le statistiche/record delle partite normali.
		var data: Dictionary = CheckpointData.slot_info(CheckpointData.CREATOR_SLOT)
		if data.empty:
			CheckpointData.start_new_game(CheckpointData.CREATOR_SLOT)
		else:
			CheckpointData.select_slot(CheckpointData.CREATOR_SLOT)
		DevMode.enabled = true
		if CheckpointData.resumed_from_continue:
			get_tree().change_scene_to_file("res://scenes/Home.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/Main.tscn")
	else:
		error_label.text = "Password errata"
		password_edit.text = ""
		password_edit.grab_focus()
