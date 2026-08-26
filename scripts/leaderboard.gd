extends Node

# Client per la classifica globale: identità anonima persistita (nessun
# sistema di account nel gioco), nickname scelto dal player, invio "fire and
# forget" del risultato corrente e lettura della classifica per la UI.
#
# NOTA: verificare che API_BASE corrisponda all'URL reale del servizio Render
# una volta effettuato il deploy (il nome del servizio potrebbe non
# corrispondere esattamente al sottodominio assegnato da Render).
const API_BASE := "https://crazy-town.onrender.com"

const PLAYER_ID_PATH := "user://player_id.txt"
const NICKNAME_PATH := "user://nickname.txt"
const MAX_NICKNAME_LEN := 20
const ID_CHARS := "0123456789abcdef"
const ID_LENGTH := 32

signal leaderboard_loaded(entries: Array)
signal leaderboard_failed()

var player_id := ""
var nickname := ""

func _ready() -> void:
	randomize()
	_load_or_create_player_id()
	_load_nickname()

func _load_or_create_player_id() -> void:
	if FileAccess.file_exists(PLAYER_ID_PATH):
		var f := FileAccess.open(PLAYER_ID_PATH, FileAccess.READ)
		if f != null:
			player_id = f.get_as_text().strip_edges()
			f.close()
	if player_id == "":
		player_id = _generate_player_id()
		var f := FileAccess.open(PLAYER_ID_PATH, FileAccess.WRITE)
		if f != null:
			f.store_string(player_id)
			f.close()

func _generate_player_id() -> String:
	var id := ""
	for i in range(ID_LENGTH):
		id += ID_CHARS[randi() % ID_CHARS.length()]
	return id

func _load_nickname() -> void:
	if FileAccess.file_exists(NICKNAME_PATH):
		var f := FileAccess.open(NICKNAME_PATH, FileAccess.READ)
		if f != null:
			nickname = f.get_as_text().strip_edges()
			f.close()

func has_nickname() -> bool:
	return nickname != ""

func set_nickname(new_name: String) -> void:
	nickname = new_name.strip_edges().substr(0, MAX_NICKNAME_LEN)
	var f := FileAccess.open(NICKNAME_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(nickname)
		f.close()

# Invio "fire and forget": la classifica è un accessorio, un fallimento di
# rete non deve mai bloccare o rallentare la partita in corso.
func submit(zone: int, money: int) -> void:
	if player_id == "" or nickname == "":
		return
	var payload := {"player_id": player_id, "nickname": nickname, "zone": zone, "money": money}
	var body := JSON.stringify(payload)
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_r, _c, _h, _b): http.queue_free())
	var err := http.request(API_BASE + "/leaderboard/submit", ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)
	if err != OK:
		http.queue_free()

func fetch_leaderboard() -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_fetch_completed.bind(http))
	var err := http.request(API_BASE + "/leaderboard")
	if err != OK:
		http.queue_free()
		leaderboard_failed.emit()

func _on_fetch_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		leaderboard_failed.emit()
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_DICTIONARY or typeof(data.get("entries", null)) != TYPE_ARRAY:
		leaderboard_failed.emit()
		return
	leaderboard_loaded.emit(data.entries)
