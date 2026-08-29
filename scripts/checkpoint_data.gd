extends Node

const Throwables := preload("res://scripts/throwables.gd")

# Intervallo tra un checkpoint e il successivo, a soglie: più fitto nelle
# prime zone (più semplice prendere confidenza col gioco), poi via via più
# largo. Scenarios.gd usa esattamente le stesse soglie per i confini degli
# scenari (vedi Scenarios._next_checkpoint_zone), i due sistemi devono
# restare sincronizzati.
const CHECKPOINT_INTERVAL_TIER1 := 20
const CHECKPOINT_TIER1_END := 100
const CHECKPOINT_INTERVAL_TIER2 := 30
const CHECKPOINT_TIER2_END := 250
const CHECKPOINT_INTERVAL_TIER3 := 50

# Fino a SLOT_COUNT partite separate, ognuna con il proprio checkpoint e il
# proprio salvataggio "riprendi partita", in cartelle indipendenti.
const SLOT_COUNT := 3
const SLOT_DIR_FORMAT := "user://saves/slot_%d/"
const CHECKPOINT_FILENAME := "checkpoint.json"
const CONTINUE_SAVE_FILENAME := "continue_save.json"

# Slot speciale e completamente separato per la Modalità Creator: usa una
# cartella propria (fuori dalla numerazione 1..SLOT_COUNT), così una partita
# creator non tocca mai i salvataggi né le statistiche/record delle partite
# normali.
const CREATOR_SLOT := -1
const CREATOR_SLOT_DIR := "user://saves/creator/"

# Percorsi del vecchio salvataggio unico (pre-multi-partita): usati solo per
# migrare automaticamente i progressi esistenti nello Slot 1 alla prima
# apertura del gioco dopo l'aggiornamento.
const LEGACY_CHECKPOINT_PATH := "user://checkpoint.json"
const LEGACY_CONTINUE_SAVE_PATH := "user://continue_save.json"

# 0 = nessuno slot ancora scelto (menu principale); 1..SLOT_COUNT = partita
# attiva. Tutte le funzioni di salvataggio/caricamento operano sullo slot
# corrente.
var current_slot := 0

# true se il caricamento dello slot corrente ha trovato un salvataggio
# "riprendi partita" più recente del checkpoint: in quel caso si deve far
# ripartire il player da casa invece che nel parco.
var resumed_from_continue := false

const DEFAULT_UPGRADES := {
	"scarpe": 0,
	"salute": 0,
	"saccheggio": 0,
	"sicurezza": 0,
	"zaino": 0,
}

const DEFAULT_EQUIPPED_WEAPON := "pugni"

var zone := 1
var money := 0
var materials := {"legno": 0, "metallo": 0, "cablaggi": 0}
var upgrades := DEFAULT_UPGRADES.duplicate()
# Vita del player persistita tra una zona e l'altra: entrare in casa non la
# ripristina più al massimo, resta quella con cui si è arrivati (vedi
# main.gd:_apply_upgrade_effects). 100.0 di default per una partita nuova.
var hp := 100.0
# Fame del player, persistita come la vita: cala col tempo di gioco attivo
# (solo con la cucina acquistata, vedi main.gd:_update_hunger) e si
# ricarica mangiando al tavolo della cucina. 100.0 = piena, nessuna penalità
# di velocità.
var hunger := 100.0
var placed_benches := []
var owned_weapons := {}
var weapon_upgrades := {}
var equipped_weapon := DEFAULT_EQUIPPED_WEAPON
var owned_firearms := {}
var firearm_upgrades := {}
var firearm_ammo := {}
var equipped_firearm := ""
var owned_throwables := {}
var throwable_upgrades := {}
var throwable_ammo := {}
# Al massimo un'arma da lancio equipaggiata per categoria (armi bianche da
# lancio, granate esplosive, granate speciali): {categoria: id_arma}.
var equipped_throwables := {}
# Tra le armi da lancio equipaggiate, quella attualmente "in mano" (armabile
# e lanciabile sul campo tramite i tasti arma/lancio).
var equipped_throwable := ""
var house_tier := 0
# Piatti cucinati al forno della cucina ma non ancora mangiati: {id_piatto:
# quantità}. Il tavolo funziona da magazzino, vedi recipes.gd.
var kitchen_stored_food := {}
# Funghi raccolti nel campo da gioco: {id_fungo: quantità}, vedi
# mushrooms.gd (varietà/rarità) e fungo.gd (raccolta sul campo). Sono
# l'ingrediente extra richiesto per cucinare, oltre a soldi e legno.
var mushrooms := {}
# Livello della luce della casa (0 = non acquistata): vedi house_light.gd.
# Determina il raggio del cerchio di luce che il buio della "tempesta" non
# può sovrastare attorno alla casa.
var house_light_level := 0
# Posizione del banco della casa nella griglia del piano terra: di default
# occupa le celle 0:0/1:0 (posizione originale), ma il player può spostarlo
# con lo stesso sistema di posizionamento degli altri banchi.
var house_bench_orientation := "h"
var house_bench_col_idx := 0
var house_bench_row_idx := 0

# Colori scelti dal player all'Armadio, come stringa esadecimale
# (Color.to_html(false)); vuoto = usa il colore di default del tier/corpo.
var player_body_color := ""
var house_wall_color := ""
var house_roof_color := ""
var house_door_color := ""

# Statistiche cumulative dell'intera partita, dalla zona 1: a differenza di
# zone/money/materiali (che un checkpoint riporta indietro all'ultimo
# traguardo superato in caso di morte), queste non tornano mai indietro —
# _apply_state() le aggiorna solo verso l'alto (max), così un game over
# mostra sempre il totale giocato, non solo l'ultimo tentativo dall'ultimo
# checkpoint.
var stats_zone_reached := 1
var stats_money_earned := 0
var stats_enemies_defeated := 0
var stats_playtime_sec := 0.0

func _ready() -> void:
	_migrate_legacy_save_to_slot_1()

# --- Percorsi per slot ---

func _slot_dir(slot: int) -> String:
	if slot == CREATOR_SLOT:
		return CREATOR_SLOT_DIR
	return SLOT_DIR_FORMAT % slot

func _slot_checkpoint_path(slot: int) -> String:
	return _slot_dir(slot) + CHECKPOINT_FILENAME

func _slot_continue_path(slot: int) -> String:
	return _slot_dir(slot) + CONTINUE_SAVE_FILENAME

# --- Migrazione dal vecchio salvataggio unico ---

func _migrate_legacy_save_to_slot_1() -> void:
	var slot1_checkpoint := _slot_checkpoint_path(1)
	if FileAccess.file_exists(slot1_checkpoint) or FileAccess.file_exists(_slot_continue_path(1)):
		return
	var had_legacy := false
	if FileAccess.file_exists(LEGACY_CHECKPOINT_PATH):
		DirAccess.make_dir_recursive_absolute(_slot_dir(1))
		var data = _read_json(LEGACY_CHECKPOINT_PATH)
		if typeof(data) == TYPE_DICTIONARY:
			_write_json(slot1_checkpoint, data)
			had_legacy = true
		DirAccess.remove_absolute(LEGACY_CHECKPOINT_PATH)
	if FileAccess.file_exists(LEGACY_CONTINUE_SAVE_PATH):
		DirAccess.make_dir_recursive_absolute(_slot_dir(1))
		var data2 = _read_json(LEGACY_CONTINUE_SAVE_PATH)
		if typeof(data2) == TYPE_DICTIONARY:
			_write_json(_slot_continue_path(1), data2)
			had_legacy = true
		DirAccess.remove_absolute(LEGACY_CONTINUE_SAVE_PATH)
	if had_legacy:
		print("CheckpointData: migrata la partita esistente nello Slot 1.")

# --- Anteprima di uno slot per il menu di selezione (non tocca lo stato live) ---

func slot_info(slot: int) -> Dictionary:
	var data = _read_json(_slot_continue_path(slot))
	if typeof(data) != TYPE_DICTIONARY:
		data = _read_json(_slot_checkpoint_path(slot))
	if typeof(data) != TYPE_DICTIONARY:
		return {"empty": true}
	return {
		"empty": false,
		"zone": int(data.get("zone", 1)),
		"money": int(data.get("money", 0)),
		"house_tier": int(data.get("house_tier", 0)),
	}

func slot_has_save(slot: int) -> bool:
	return FileAccess.file_exists(_slot_checkpoint_path(slot)) or FileAccess.file_exists(_slot_continue_path(slot))

# --- Selezione partita ---

# Carica lo slot scelto (se ha già dati) e lo rende quello attivo. Da
# chiamare dal menu principale prima di entrare in Home.tscn/Main.tscn.
func select_slot(slot: int) -> void:
	current_slot = slot
	_reset_to_defaults()
	load_checkpoint()
	resumed_from_continue = false
	if has_continue_save():
		load_continue()
		resumed_from_continue = true

# Azzera lo slot scelto (cancella eventuali salvataggi precedenti) e lo
# rende quello attivo, pronta per una partita nuova.
func start_new_game(slot: int) -> void:
	current_slot = slot
	_reset_to_defaults()
	resumed_from_continue = false
	if FileAccess.file_exists(_slot_checkpoint_path(slot)):
		DirAccess.remove_absolute(_slot_checkpoint_path(slot))
	if FileAccess.file_exists(_slot_continue_path(slot)):
		DirAccess.remove_absolute(_slot_continue_path(slot))

func _reset_to_defaults() -> void:
	zone = 1
	money = 0
	materials = {"legno": 0, "metallo": 0, "cablaggi": 0}
	upgrades = DEFAULT_UPGRADES.duplicate()
	hp = 100.0
	hunger = 100.0
	placed_benches = []
	owned_weapons = {}
	weapon_upgrades = {}
	equipped_weapon = DEFAULT_EQUIPPED_WEAPON
	owned_firearms = {}
	firearm_upgrades = {}
	firearm_ammo = {}
	equipped_firearm = ""
	owned_throwables = {}
	throwable_upgrades = {}
	throwable_ammo = {}
	equipped_throwables = {}
	equipped_throwable = ""
	house_tier = 0
	kitchen_stored_food = {}
	mushrooms = {}
	house_light_level = 0
	house_bench_orientation = "h"
	house_bench_col_idx = 0
	house_bench_row_idx = 0
	player_body_color = ""
	house_wall_color = ""
	house_roof_color = ""
	house_door_color = ""
	stats_zone_reached = 1
	stats_money_earned = 0
	stats_enemies_defeated = 0
	stats_playtime_sec = 0.0

# --- Checkpoint / salvataggio "riprendi partita" per lo slot corrente ---

func load_checkpoint() -> void:
	var data = _read_json(_slot_checkpoint_path(current_slot))
	if typeof(data) != TYPE_DICTIONARY:
		# Nessun checkpoint salvato ancora (zona < 50): la zona 1 è essa
		# stessa un checkpoint implicito, quindi si torna allo stato di
		# partenza invece di lasciare intatto qualunque progresso "riprendi
		# partita" più recente accumulato nel frattempo — altrimenti
		# "ricomincia dall'ultimo checkpoint" prima della zona 50 tornerebbe
		# all'ultima visita a casa invece che alla zona 1.
		_reset_to_defaults()
		return
	_apply_state(data)

func has_continue_save() -> bool:
	return FileAccess.file_exists(_slot_continue_path(current_slot))

func load_continue() -> void:
	var data = _read_json(_slot_continue_path(current_slot))
	if typeof(data) != TYPE_DICTIONARY:
		return
	_apply_state(data)

func clear_continue_save() -> void:
	var path := _slot_continue_path(current_slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func _read_json(path: String):
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	return data

func _apply_state(data: Dictionary) -> void:
	zone = int(data.get("zone", 1))
	money = int(data.get("money", 0))
	hp = float(data.get("hp", 100.0))
	hunger = float(data.get("hunger", 100.0))
	var mats = data.get("materials", {})
	if typeof(mats) == TYPE_DICTIONARY:
		for k in materials.keys():
			materials[k] = int(mats.get(k, 0))
	var ups = data.get("upgrades", {})
	if typeof(ups) == TYPE_DICTIONARY:
		for k in upgrades.keys():
			upgrades[k] = int(ups.get(k, 0))
	var benches = data.get("placed_benches", [])
	placed_benches = benches.duplicate(true) if typeof(benches) == TYPE_ARRAY else []
	var owned = data.get("owned_weapons", {})
	owned_weapons = owned.duplicate() if typeof(owned) == TYPE_DICTIONARY else {}
	var wups = data.get("weapon_upgrades", {})
	weapon_upgrades = wups.duplicate(true) if typeof(wups) == TYPE_DICTIONARY else {}
	equipped_weapon = String(data.get("equipped_weapon", DEFAULT_EQUIPPED_WEAPON))
	var owned_f = data.get("owned_firearms", {})
	owned_firearms = owned_f.duplicate() if typeof(owned_f) == TYPE_DICTIONARY else {}
	var fups = data.get("firearm_upgrades", {})
	firearm_upgrades = fups.duplicate(true) if typeof(fups) == TYPE_DICTIONARY else {}
	var fammo = data.get("firearm_ammo", {})
	firearm_ammo = fammo.duplicate() if typeof(fammo) == TYPE_DICTIONARY else {}
	equipped_firearm = String(data.get("equipped_firearm", ""))
	var owned_t = data.get("owned_throwables", {})
	owned_throwables = owned_t.duplicate() if typeof(owned_t) == TYPE_DICTIONARY else {}
	var tups = data.get("throwable_upgrades", {})
	throwable_upgrades = tups.duplicate(true) if typeof(tups) == TYPE_DICTIONARY else {}
	var tammo = data.get("throwable_ammo", {})
	throwable_ammo = tammo.duplicate() if typeof(tammo) == TYPE_DICTIONARY else {}
	equipped_throwable = String(data.get("equipped_throwable", ""))
	var eqt = data.get("equipped_throwables", null)
	if typeof(eqt) == TYPE_DICTIONARY:
		equipped_throwables = eqt.duplicate()
	elif equipped_throwable != "" and Throwables.WEAPONS.has(equipped_throwable):
		# Salvataggio precedente a quando l'equip era diviso per categoria:
		# ricostruisco il caricamento a partire dall'unica arma equipaggiata.
		var cat: String = String(Throwables.WEAPONS[equipped_throwable].category)
		equipped_throwables = {cat: equipped_throwable}
	else:
		equipped_throwables = {}
	house_tier = int(data.get("house_tier", 0))
	var food = data.get("kitchen_stored_food", {})
	kitchen_stored_food = food.duplicate() if typeof(food) == TYPE_DICTIONARY else {}
	var mush = data.get("mushrooms", {})
	mushrooms = mush.duplicate() if typeof(mush) == TYPE_DICTIONARY else {}
	house_light_level = int(data.get("house_light_level", 0))
	house_bench_orientation = String(data.get("house_bench_orientation", "h"))
	house_bench_col_idx = int(data.get("house_bench_col_idx", 0))
	house_bench_row_idx = int(data.get("house_bench_row_idx", 0))
	player_body_color = String(data.get("player_body_color", ""))
	house_wall_color = String(data.get("house_wall_color", ""))
	house_roof_color = String(data.get("house_roof_color", ""))
	house_door_color = String(data.get("house_door_color", ""))
	# max invece di sovrascrivere: un checkpoint più vecchio (o un continue
	# save invalidato dalla morte) non deve mai far tornare indietro le
	# statistiche cumulative della partita.
	stats_zone_reached = int(data.get("stats_zone_reached", 1))
	stats_money_earned = int(data.get("stats_money_earned", 0))
	stats_enemies_defeated = int(data.get("stats_enemies_defeated", 0))
	stats_playtime_sec = float(data.get("stats_playtime_sec", 0.0))

func set_live_state(current_zone: int, current_money: int, current_materials: Dictionary, current_upgrades: Dictionary, current_hp: float = -1.0, current_hunger: float = -1.0, current_mushrooms = null) -> void:
	zone = current_zone
	money = current_money
	materials = current_materials.duplicate()
	upgrades = current_upgrades.duplicate()
	if current_hp >= 0.0:
		hp = current_hp
	if current_hunger >= 0.0:
		hunger = current_hunger
	if current_mushrooms != null:
		mushrooms = current_mushrooms.duplicate()

func _state_dict() -> Dictionary:
	return {
		"zone": zone,
		"money": money,
		"hp": hp,
		"hunger": hunger,
		"materials": materials,
		"upgrades": upgrades,
		"placed_benches": placed_benches,
		"owned_weapons": owned_weapons,
		"weapon_upgrades": weapon_upgrades,
		"equipped_weapon": equipped_weapon,
		"owned_firearms": owned_firearms,
		"firearm_upgrades": firearm_upgrades,
		"firearm_ammo": firearm_ammo,
		"equipped_firearm": equipped_firearm,
		"owned_throwables": owned_throwables,
		"throwable_upgrades": throwable_upgrades,
		"throwable_ammo": throwable_ammo,
		"equipped_throwable": equipped_throwable,
		"equipped_throwables": equipped_throwables,
		"house_tier": house_tier,
		"kitchen_stored_food": kitchen_stored_food,
		"mushrooms": mushrooms,
		"house_light_level": house_light_level,
		"house_bench_orientation": house_bench_orientation,
		"house_bench_col_idx": house_bench_col_idx,
		"house_bench_row_idx": house_bench_row_idx,
		"player_body_color": player_body_color,
		"house_wall_color": house_wall_color,
		"house_roof_color": house_roof_color,
		"house_door_color": house_door_color,
		"stats_zone_reached": stats_zone_reached,
		"stats_money_earned": stats_money_earned,
		"stats_enemies_defeated": stats_enemies_defeated,
		"stats_playtime_sec": stats_playtime_sec,
	}

func _write_json(path: String, payload: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(payload))
	f.close()

# Checkpoint ogni 50 zone: resta l'unico fallback usato in caso di morte
# (vedi _on_player_died in main.gd), invariato, solo ora per-slot. La vita
# salvata qui è sempre quella piena (vedi il chiamante in main.gd, passa
# player.max_hp): un checkpoint deve sempre far ripartire a vita piena dopo
# una morte, non con la vita residua di quando fu salvato.
func save_checkpoint(current_zone: int, current_money: int, current_materials: Dictionary, current_upgrades: Dictionary, current_hp: float, current_mushrooms: Dictionary = {}) -> void:
	# Vita E fame sempre piene: un checkpoint deve far ripartire "puliti"
	# dopo una morte, non con la fame residua di quando fu salvato.
	set_live_state(current_zone, current_money, current_materials, current_upgrades, current_hp, 100.0, current_mushrooms)
	_write_json(_slot_checkpoint_path(current_slot), _state_dict())

# Salvataggio "riprendi partita": scritto da home.gd ogni volta che il
# player entra in casa (zone/money/materials/upgrades sono già stati
# sincronizzati da main.gd tramite set_live_state prima del cambio scena).
func save_continue() -> void:
	_write_json(_slot_continue_path(current_slot), _state_dict())

func is_checkpoint_zone(zone_num: int) -> bool:
	if zone_num <= CHECKPOINT_TIER1_END:
		return zone_num % CHECKPOINT_INTERVAL_TIER1 == 0
	elif zone_num <= CHECKPOINT_TIER2_END:
		return (zone_num - CHECKPOINT_TIER1_END) % CHECKPOINT_INTERVAL_TIER2 == 0
	else:
		return (zone_num - CHECKPOINT_TIER2_END) % CHECKPOINT_INTERVAL_TIER3 == 0
