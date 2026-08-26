extends Control

@onready var password_panel: Control = $PasswordPanel
@onready var password_edit: LineEdit = $PasswordPanel/Scroll/Box/PasswordEdit
@onready var error_label: Label = $PasswordPanel/Scroll/Box/ErrorLabel
@onready var keyboard: GridContainer = $PasswordPanel/Scroll/Box/Keyboard
@onready var confirm_reset_panel: Control = $ConfirmResetPanel

@onready var nickname_screen: Control = $NicknameScreen
@onready var nickname_edit: LineEdit = $NicknameScreen/Scroll/Box/NicknameEdit
@onready var nickname_error_label: Label = $NicknameScreen/Scroll/Box/ErrorLabel
@onready var nickname_keyboard: GridContainer = $NicknameScreen/Scroll/Box/Keyboard
@onready var nickname_cancel_button: Button = $NicknameScreen/Scroll/Box/CancelButton

@onready var leaderboard_screen: Control = $LeaderboardScreen
@onready var leaderboard_status_label: Label = $LeaderboardScreen/Box/StatusLabel
@onready var leaderboard_list: VBoxContainer = $LeaderboardScreen/Box/Scroll/List

var _pending_reset_slot := 0
# true finché il player non ha ancora scelto un nickname al primissimo avvio:
# in quel caso _continue_ready() (il resto della normale inizializzazione del
# menu) resta in sospeso finché la schermata nickname non viene confermata.
var _nickname_gate_pending := false

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
	_wire_nickname_screen()
	_wire_leaderboard_screen()

	# Nickname obbligatorio al primissimo avvio (nessun sistema di account
	# nel gioco): finché non viene scelto, il resto dell'inizializzazione del
	# menu resta in sospeso, stesso principio del tutorial obbligatorio qui
	# sotto.
	if not Leaderboard.has_nickname():
		_nickname_gate_pending = true
		_open_nickname_screen(false)
		return

	_continue_ready()

func _continue_ready() -> void:
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
	$Box/LeaderboardButton.pressed.connect(_on_leaderboard_pressed)
	$CreatorButton.pressed.connect(_on_creator_pressed)
	$NicknameButton.pressed.connect(_on_change_nickname_pressed)
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

# --- Nickname (classifica globale) ---

func _wire_nickname_screen() -> void:
	for key in nickname_keyboard.get_children():
		key.pressed.connect(_on_nickname_key_pressed.bind(key))
	var space_key: Button = $NicknameScreen/Scroll/Box/Key_Space
	space_key.pressed.connect(_on_nickname_key_pressed.bind(space_key))
	$NicknameScreen/Scroll/Box/BackspaceButton.pressed.connect(_on_nickname_backspace_pressed)
	$NicknameScreen/Scroll/Box/ConfirmButton.pressed.connect(_on_nickname_confirm_pressed)
	nickname_cancel_button.pressed.connect(_on_nickname_cancel_pressed)
	nickname_edit.text_submitted.connect(func(_t): _on_nickname_confirm_pressed())

func _open_nickname_screen(cancellable: bool) -> void:
	nickname_edit.text = Leaderboard.nickname
	nickname_error_label.text = ""
	nickname_cancel_button.visible = cancellable
	nickname_screen.visible = true
	nickname_edit.grab_focus()

func _on_change_nickname_pressed() -> void:
	_open_nickname_screen(true)

func _on_nickname_key_pressed(key: Button) -> void:
	if nickname_edit.text.length() >= 20:
		return
	var ch: String = " " if key.name == "Key_Space" else key.text
	nickname_edit.text += ch
	nickname_edit.caret_column = nickname_edit.text.length()

func _on_nickname_backspace_pressed() -> void:
	if nickname_edit.text.length() > 0:
		nickname_edit.text = nickname_edit.text.substr(0, nickname_edit.text.length() - 1)
		nickname_edit.caret_column = nickname_edit.text.length()

func _on_nickname_confirm_pressed() -> void:
	var trimmed := nickname_edit.text.strip_edges()
	if trimmed.length() == 0:
		nickname_error_label.text = "Inserisci un nickname"
		return
	Leaderboard.set_nickname(trimmed)
	nickname_screen.visible = false
	if _nickname_gate_pending:
		_nickname_gate_pending = false
		_continue_ready()

func _on_nickname_cancel_pressed() -> void:
	nickname_screen.visible = false

# --- Classifica globale ---

func _wire_leaderboard_screen() -> void:
	$LeaderboardScreen/Box/CloseButton.pressed.connect(_on_leaderboard_close_pressed)
	Leaderboard.leaderboard_loaded.connect(_on_leaderboard_loaded)
	Leaderboard.leaderboard_failed.connect(_on_leaderboard_failed)

func _on_leaderboard_pressed() -> void:
	for child in leaderboard_list.get_children():
		child.queue_free()
	leaderboard_status_label.text = "Caricamento..."
	leaderboard_status_label.visible = true
	leaderboard_screen.visible = true
	Leaderboard.fetch_leaderboard()

func _on_leaderboard_close_pressed() -> void:
	leaderboard_screen.visible = false

func _on_leaderboard_loaded(entries: Array) -> void:
	if not leaderboard_screen.visible:
		return
	for child in leaderboard_list.get_children():
		child.queue_free()
	if entries.is_empty():
		leaderboard_status_label.text = "Nessun risultato ancora."
		leaderboard_status_label.visible = true
		return
	leaderboard_status_label.visible = false
	for entry in entries:
		var row := Label.new()
		var rank: int = int(entry.get("rank", 0))
		var nick: String = String(entry.get("nickname", "?"))
		var zone: int = int(entry.get("zone", 0))
		var money: int = int(entry.get("money", 0))
		row.text = "%d. %s — Zona %d — %d€" % [rank, nick, zone, money]
		row.add_theme_font_size_override("font_size", 28)
		row.add_theme_color_override("font_color", Color(0.92, 0.93, 0.95, 1))
		leaderboard_list.add_child(row)

func _on_leaderboard_failed() -> void:
	if not leaderboard_screen.visible:
		return
	leaderboard_status_label.text = "Impossibile caricare la classifica. Riprova più tardi."
	leaderboard_status_label.visible = true
