class_name MeleeWeapons
extends RefCounted

const CATEGORY_ORDER := ["coltelli", "spade", "mazze", "martelli", "lance"]

const CATEGORIES := {
	"coltelli": {"label": "Coltelli", "unlocked": true},
	"spade": {"label": "Spade", "unlocked": false},
	"mazze": {"label": "Mazze", "unlocked": false},
	"martelli": {"label": "Martelli", "unlocked": false},
	"lance": {"label": "Lance", "unlocked": false},
}

const CATEGORY_WEAPONS := {
	"coltelli": ["coltello_cucina", "a_scatto", "serramanico", "tattico", "rambo"],
	"spade": [],
	"mazze": [],
	"martelli": [],
	"lance": [],
}

const WEAPONS := {
	"coltello_cucina": {
		"label": "Coltello da cucina", "category": "coltelli", "tier": 1,
		"price_money": 80, "price_material": "legno", "price_amount": 4,
		"damage": 24.0, "cooldown": 0.42, "reach_mult": 1.05, "draw_time": 0.15,
	},
	"a_scatto": {
		"label": "A scatto", "category": "coltelli", "tier": 2,
		"price_money": 180, "price_material": "metallo", "price_amount": 6,
		"damage": 30.0, "cooldown": 0.38, "reach_mult": 1.05, "draw_time": 0.12,
	},
	"serramanico": {
		"label": "Serramanico", "category": "coltelli", "tier": 3,
		"price_money": 320, "price_material": "metallo", "price_amount": 10,
		"damage": 38.0, "cooldown": 0.35, "reach_mult": 1.10, "draw_time": 0.10,
	},
	"tattico": {
		"label": "Tattico", "category": "coltelli", "tier": 4,
		"price_money": 520, "price_material": "metallo", "price_amount": 16,
		"damage": 48.0, "cooldown": 0.32, "reach_mult": 1.15, "draw_time": 0.08,
	},
	"rambo": {
		"label": "Coltellazzo di Rambo", "category": "coltelli", "tier": 5,
		"price_money": 900, "price_material": "metallo", "price_amount": 26,
		"damage": 65.0, "cooldown": 0.30, "reach_mult": 1.25, "draw_time": 0.05,
	},
}

const UPGRADE_TRACK_ORDER := ["portata", "velocita", "danno", "estrazione"]

const UPGRADE_TRACKS := {
	"portata": {"label": "Portata", "desc": "Aumenta la portata dell'arma", "material": "legno", "per_level": 0.03},
	"velocita": {"label": "Velocità d'attacco", "desc": "Riduce il tempo tra un attacco e l'altro", "material": "metallo", "per_level": 0.02},
	"danno": {"label": "Danno", "desc": "Aumenta il danno dell'arma", "material": "metallo", "per_level": 0.06},
	"estrazione": {"label": "Velocità di estrazione", "desc": "Riduce il tempo per sguainare l'arma", "material": "cablaggi", "per_level": 0.08},
}

const UPGRADE_MAX_LEVEL := 10
const UPGRADE_BASE_MONEY := 30
const UPGRADE_BASE_MAT := 3
const UPGRADE_GROWTH := 1.28

static func weapon_price_money(weapon_id: String) -> int:
	return int(WEAPONS[weapon_id].price_money)

static func weapon_price_material(weapon_id: String) -> String:
	return String(WEAPONS[weapon_id].price_material)

static func weapon_price_amount(weapon_id: String) -> int:
	return int(WEAPONS[weapon_id].price_amount)

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
	var base: float = WEAPONS[weapon_id].cooldown
	var level: int = upgrades.get("velocita", 0)
	return max(base * (1.0 - upgrade_effect("velocita", level)), 0.08)

static func final_reach_mult(weapon_id: String, upgrades: Dictionary) -> float:
	var base: float = WEAPONS[weapon_id].reach_mult
	var level: int = upgrades.get("portata", 0)
	return base * (1.0 + upgrade_effect("portata", level))

static func final_draw_time(weapon_id: String, upgrades: Dictionary) -> float:
	var base: float = WEAPONS[weapon_id].draw_time
	var level: int = upgrades.get("estrazione", 0)
	return max(base * (1.0 - upgrade_effect("estrazione", level)), 0.0)
