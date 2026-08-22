class_name Firearms
extends RefCounted

const CATEGORY_ORDER := ["pistole", "mitragliette", "mitra", "fucile_a_pompa", "cecchino"]

const CATEGORIES := {
	"pistole": {"label": "Pistole", "unlocked": true},
	"mitragliette": {"label": "Mitragliette", "unlocked": false},
	"mitra": {"label": "Mitra", "unlocked": false},
	"fucile_a_pompa": {"label": "Fucile a pompa", "unlocked": false},
	"cecchino": {"label": "Fucili da tiratore", "unlocked": false},
}

const CATEGORY_WEAPONS := {
	"pistole": ["pistola_aria_compressa", "revolver_arrugginito", "semiautomatica_9mm", "pistola_tattica", "magnum_44"],
	"mitragliette": [],
	"mitra": [],
	"fucile_a_pompa": [],
	"cecchino": [],
}

# fire_mode "auto": spara in automatico quando un nemico è nel cono di mira.
# fire_mode "single": spara un solo colpo al rilascio del joystick di mira.
const WEAPONS := {
	"pistola_aria_compressa": {
		"label": "Pistola ad aria compressa", "category": "pistole", "tier": 1, "fire_mode": "single",
		"price_money": 150, "price_material": "metallo", "price_amount": 8,
		"damage": 10.0, "fire_cooldown": 0.5, "magazine_size": 6, "range": 12.0, "reload_time": 1.4, "draw_time": 0.20,
		"ammo_pack_amount": 12, "ammo_pack_price_money": 20,
	},
	"revolver_arrugginito": {
		"label": "Revolver arrugginito", "category": "pistole", "tier": 2, "fire_mode": "single",
		"price_money": 260, "price_material": "metallo", "price_amount": 12,
		"damage": 22.0, "fire_cooldown": 0.65, "magazine_size": 6, "range": 14.0, "reload_time": 1.8, "draw_time": 0.18,
		"ammo_pack_amount": 10, "ammo_pack_price_money": 35,
	},
	"semiautomatica_9mm": {
		"label": "Semiautomatica 9mm", "category": "pistole", "tier": 3, "fire_mode": "auto",
		"price_money": 420, "price_material": "metallo", "price_amount": 18,
		"damage": 16.0, "fire_cooldown": 0.22, "magazine_size": 12, "range": 16.0, "reload_time": 1.3, "draw_time": 0.14,
		"ammo_pack_amount": 20, "ammo_pack_price_money": 40,
	},
	"pistola_tattica": {
		"label": "Pistola tattica", "category": "pistole", "tier": 4, "fire_mode": "auto",
		"price_money": 650, "price_material": "metallo", "price_amount": 24,
		"damage": 20.0, "fire_cooldown": 0.18, "magazine_size": 15, "range": 18.0, "reload_time": 1.1, "draw_time": 0.10,
		"ammo_pack_amount": 24, "ammo_pack_price_money": 55,
	},
	"magnum_44": {
		"label": "Magnum calibro .44", "category": "pistole", "tier": 5, "fire_mode": "single",
		"price_money": 1050, "price_material": "metallo", "price_amount": 32,
		"damage": 55.0, "fire_cooldown": 0.9, "magazine_size": 6, "range": 20.0, "reload_time": 2.0, "draw_time": 0.08,
		"ammo_pack_amount": 8, "ammo_pack_price_money": 70,
	},
}

const UPGRADE_TRACK_ORDER := ["portata", "velocita", "danno", "estrazione"]

const UPGRADE_TRACKS := {
	"portata": {"label": "Portata", "desc": "Aumenta la gittata dell'arma", "material": "legno", "per_level": 0.03},
	"velocita": {"label": "Cadenza di fuoco", "desc": "Riduce il tempo tra un colpo e l'altro", "material": "metallo", "per_level": 0.025},
	"danno": {"label": "Danno", "desc": "Aumenta il danno per colpo", "material": "metallo", "per_level": 0.06},
	"estrazione": {"label": "Velocità di estrazione", "desc": "Riduce il tempo per impugnare l'arma", "material": "cablaggi", "per_level": 0.08},
}

const UPGRADE_MAX_LEVEL := 10
const UPGRADE_BASE_MONEY := 35
const UPGRADE_BASE_MAT := 3
const UPGRADE_GROWTH := 1.3

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
	var base: float = WEAPONS[weapon_id].fire_cooldown
	var level: int = upgrades.get("velocita", 0)
	return max(base * (1.0 - upgrade_effect("velocita", level)), 0.05)

static func final_range(weapon_id: String, upgrades: Dictionary) -> float:
	var base: float = WEAPONS[weapon_id].range
	var level: int = upgrades.get("portata", 0)
	return base * (1.0 + upgrade_effect("portata", level))

static func final_draw_time(weapon_id: String, upgrades: Dictionary) -> float:
	var base: float = WEAPONS[weapon_id].draw_time
	var level: int = upgrades.get("estrazione", 0)
	return max(base * (1.0 - upgrade_effect("estrazione", level)), 0.0)
