class_name Throwables
extends RefCounted

const CATEGORY_ORDER := ["armi_bianche_lancio", "granate_esplosive", "granate_speciali"]

const CATEGORIES := {
	"armi_bianche_lancio": {"label": "Armi bianche da lancio", "unlocked": true},
	"granate_esplosive": {"label": "Granate esplosive", "unlocked": false},
	"granate_speciali": {"label": "Granate speciali", "unlocked": false},
}

const CATEGORY_WEAPONS := {
	"armi_bianche_lancio": ["coltello_da_lancio", "pugnale_da_lancio", "accetta_da_lancio", "stella_ninja", "ascia_battaglia_lancio"],
	"granate_esplosive": [],
	"granate_speciali": [],
}

# Le armi da lancio si lanciano al rilascio del joystick di mira dopo aver
# premuto il tasto "arma il lancio", nella direzione puntata in quel momento.
const WEAPONS := {
	"coltello_da_lancio": {
		"label": "Coltello da lancio", "category": "armi_bianche_lancio", "tier": 1,
		"price_money": 200, "price_material": "legno", "price_amount": 8,
		"damage": 20.0, "throw_cooldown": 0.5, "range": 14.0, "draw_time": 0.15,
		"ammo_pack_amount": 10, "ammo_pack_price_money": 25,
	},
	"pugnale_da_lancio": {
		"label": "Pugnale da lancio", "category": "armi_bianche_lancio", "tier": 2,
		"price_money": 350, "price_material": "metallo", "price_amount": 10,
		"damage": 28.0, "throw_cooldown": 0.45, "range": 15.0, "draw_time": 0.13,
		"ammo_pack_amount": 10, "ammo_pack_price_money": 38,
	},
	"accetta_da_lancio": {
		"label": "Accetta da lancio", "category": "armi_bianche_lancio", "tier": 3,
		"price_money": 550, "price_material": "metallo", "price_amount": 16,
		"damage": 42.0, "throw_cooldown": 0.55, "range": 13.0, "draw_time": 0.18,
		"ammo_pack_amount": 8, "ammo_pack_price_money": 50,
	},
	"stella_ninja": {
		"label": "Stella ninja", "category": "armi_bianche_lancio", "tier": 4,
		"price_money": 780, "price_material": "metallo", "price_amount": 20,
		"damage": 32.0, "throw_cooldown": 0.35, "range": 16.0, "draw_time": 0.10,
		"ammo_pack_amount": 12, "ammo_pack_price_money": 60,
	},
	"ascia_battaglia_lancio": {
		"label": "Ascia da battaglia da lancio", "category": "armi_bianche_lancio", "tier": 5,
		"price_money": 1150, "price_material": "metallo", "price_amount": 30,
		"damage": 65.0, "throw_cooldown": 0.7, "range": 14.0, "draw_time": 0.20,
		"ammo_pack_amount": 8, "ammo_pack_price_money": 75,
	},
}

const UPGRADE_TRACK_ORDER := ["portata", "velocita", "danno", "estrazione"]

const UPGRADE_TRACKS := {
	"portata": {"label": "Portata", "desc": "Aumenta la gittata del lancio", "material": "legno", "per_level": 0.03},
	"velocita": {"label": "Velocità di lancio", "desc": "Riduce il tempo tra un lancio e l'altro", "material": "metallo", "per_level": 0.025},
	"danno": {"label": "Danno", "desc": "Aumenta il danno per colpo", "material": "metallo", "per_level": 0.06},
	"estrazione": {"label": "Velocità di estrazione", "desc": "Riduce il tempo per impugnare l'arma", "material": "cablaggi", "per_level": 0.08},
}

const UPGRADE_MAX_LEVEL := 10
const UPGRADE_BASE_MONEY := 32
const UPGRADE_BASE_MAT := 3
const UPGRADE_GROWTH := 1.28

static func upgrade_cost_money(weapon_id: String, level: int) -> int:
	var tier: int = WEAPONS[weapon_id].tier
	return int(round(UPGRADE_BASE_MONEY * tier * pow(UPGRADE_GROWTH, level)))

static func upgrade_cost_material(weapon_id: String, level: int) -> int:
	var tier: int = WEAPONS[weapon_id].tier
	return int(round(UPGRADE_BASE_MAT * tier * pow(UPGRADE_GROWTH, level)))

static func upgrade_is_maxed(level: int) -> bool:
	return level >= UPGRADE_MAX_LEVEL

static func upgrade_effect(track_id: String, level: int) -> float:
	return level * float(UPGRADE_TRACKS[track_id].per_level)

static func final_damage(weapon_id: String, upgrades: Dictionary) -> float:
	var base: float = WEAPONS[weapon_id].damage
	var level: int = upgrades.get("danno", 0)
	return base * (1.0 + upgrade_effect("danno", level))

static func final_cooldown(weapon_id: String, upgrades: Dictionary) -> float:
	var base: float = WEAPONS[weapon_id].throw_cooldown
	var level: int = upgrades.get("velocita", 0)
	return max(base * (1.0 - upgrade_effect("velocita", level)), 0.1)

static func final_range(weapon_id: String, upgrades: Dictionary) -> float:
	var base: float = WEAPONS[weapon_id].range
	var level: int = upgrades.get("portata", 0)
	return base * (1.0 + upgrade_effect("portata", level))

static func final_draw_time(weapon_id: String, upgrades: Dictionary) -> float:
	var base: float = WEAPONS[weapon_id].draw_time
	var level: int = upgrades.get("estrazione", 0)
	return max(base * (1.0 - upgrade_effect("estrazione", level)), 0.0)
