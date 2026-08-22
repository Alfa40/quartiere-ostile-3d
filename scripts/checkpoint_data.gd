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
var equipped_throwable := ""

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
	}))
	f.close()

func is_checkpoint_zone(zone_num: int) -> bool:
	return zone_num % CHECKPOINT_INTERVAL == 0
