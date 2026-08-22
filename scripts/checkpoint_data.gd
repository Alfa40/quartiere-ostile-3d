extends Node

const CHECKPOINT_INTERVAL := 50
const SAVE_PATH := "user://checkpoint.json"

const DEFAULT_UPGRADES := {
	"scarpe": 0,
	"salute": 0,
	"saccheggio": 0,
	"sicurezza": 0,
	"zaino": 0,
}

var zone := 1
var money := 0
var materials := {"legno": 0, "metallo": 0, "cablaggi": 0}
var upgrades := DEFAULT_UPGRADES.duplicate()

func _ready() -> void:
	load_checkpoint()

func load_checkpoint() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return
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

func set_live_state(current_zone: int, current_money: int, current_materials: Dictionary, current_upgrades: Dictionary) -> void:
	zone = current_zone
	money = current_money
	materials = current_materials.duplicate()
	upgrades = current_upgrades.duplicate()

func save_checkpoint(current_zone: int, current_money: int, current_materials: Dictionary, current_upgrades: Dictionary) -> void:
	set_live_state(current_zone, current_money, current_materials, current_upgrades)
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"zone": zone,
		"money": money,
		"materials": materials,
		"upgrades": upgrades,
	}))
	f.close()

func is_checkpoint_zone(zone_num: int) -> bool:
	return zone_num % CHECKPOINT_INTERVAL == 0
