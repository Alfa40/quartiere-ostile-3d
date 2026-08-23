extends Node

const Throwables := preload("res://scripts/throwables.gd")

const CHECKPOINT_INTERVAL := 50
const SAVE_PATH := "user://checkpoint.json"
# Salvataggio "riprendi partita", scritto ogni volta che il player entra in
# casa: separato dal checkpoint ogni 50 zone (che resta il fallback in caso
# di morte, invariato). Permette di chiudere il gioco e riprendere da casa
# anche a giorni di distanza, ricominciando dalla zona non ancora completata.
const CONTINUE_SAVE_PATH := "user://continue_save.json"

# true se all'avvio è stato trovato e caricato un salvataggio "riprendi
# partita" più recente del checkpoint: in quel caso il menu principale deve
# far ripartire il player da casa invece che nel parco.
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

func _ready() -> void:
	load_checkpoint()
	if has_continue_save():
		load_continue()
		resumed_from_continue = true

func load_checkpoint() -> void:
	var data = _read_json(SAVE_PATH)
	if typeof(data) != TYPE_DICTIONARY:
		return
	_apply_state(data)

func has_continue_save() -> bool:
	return FileAccess.file_exists(CONTINUE_SAVE_PATH)

func load_continue() -> void:
	var data = _read_json(CONTINUE_SAVE_PATH)
	if typeof(data) != TYPE_DICTIONARY:
		return
	_apply_state(data)

func clear_continue_save() -> void:
	if FileAccess.file_exists(CONTINUE_SAVE_PATH):
		DirAccess.remove_absolute(CONTINUE_SAVE_PATH)

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

func set_live_state(current_zone: int, current_money: int, current_materials: Dictionary, current_upgrades: Dictionary) -> void:
	zone = current_zone
	money = current_money
	materials = current_materials.duplicate()
	upgrades = current_upgrades.duplicate()

func _state_dict() -> Dictionary:
	return {
		"zone": zone,
		"money": money,
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
	}

func _write_json(path: String, payload: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(payload))
	f.close()

# Checkpoint ogni 50 zone: resta l'unico fallback usato in caso di morte
# (vedi _on_player_died in main.gd), invariato.
func save_checkpoint(current_zone: int, current_money: int, current_materials: Dictionary, current_upgrades: Dictionary) -> void:
	set_live_state(current_zone, current_money, current_materials, current_upgrades)
	_write_json(SAVE_PATH, _state_dict())

# Salvataggio "riprendi partita": scritto da home.gd ogni volta che il
# player entra in casa (zone/money/materials/upgrades sono già stati
# sincronizzati da main.gd tramite set_live_state prima del cambio scena).
func save_continue() -> void:
	_write_json(CONTINUE_SAVE_PATH, _state_dict())

func is_checkpoint_zone(zone_num: int) -> bool:
	return zone_num % CHECKPOINT_INTERVAL == 0
