class_name Throwables
extends RefCounted

const CATEGORY_ORDER := ["armi_bianche_lancio", "granate_esplosive", "granate_speciali"]

const CATEGORIES := {
	"armi_bianche_lancio": {"label": "Armi bianche da lancio", "unlocked": true},
	"granate_esplosive": {"label": "Granate esplosive", "unlocked": true},
	"granate_speciali": {"label": "Granate speciali", "unlocked": true},
}

const CATEGORY_WEAPONS := {
	"armi_bianche_lancio": ["coltello_da_lancio", "pugnale_da_lancio", "accetta_da_lancio", "stella_ninja", "ascia_battaglia_lancio"],
	"granate_esplosive": ["molotov", "granata", "granata_appiccicosa", "granata_a_grappolo"],
	"granate_speciali": ["granata_fumogena", "granata_stordente", "granata_puzzosa"],
}

# Le armi da lancio si lanciano al rilascio del joystick di mira dopo aver
# premuto il tasto "arma il lancio", nella direzione puntata in quel momento.
const WEAPONS := {
	"coltello_da_lancio": {
		"label": "Coltello da lancio", "category": "armi_bianche_lancio", "tier": 1,
		"price_money": 200, "price_material": "legno", "price_amount": 8,
		"damage": 20.0, "throw_cooldown": 0.5, "range": 14.0, "draw_time": 0.15,
		"ammo_pack_price_money": 25,
	},
	"pugnale_da_lancio": {
		"label": "Pugnale da lancio", "category": "armi_bianche_lancio", "tier": 2,
		"price_money": 350, "price_material": "metallo", "price_amount": 10,
		"damage": 28.0, "throw_cooldown": 0.45, "range": 15.0, "draw_time": 0.13,
		"ammo_pack_price_money": 38,
	},
	"accetta_da_lancio": {
		"label": "Accetta da lancio", "category": "armi_bianche_lancio", "tier": 3,
		"price_money": 550, "price_material": "metallo", "price_amount": 16,
		"damage": 42.0, "throw_cooldown": 0.55, "range": 13.0, "draw_time": 0.18,
		"ammo_pack_price_money": 50,
	},
	"stella_ninja": {
		"label": "Stella ninja", "category": "armi_bianche_lancio", "tier": 4,
		"price_money": 780, "price_material": "metallo", "price_amount": 20,
		"damage": 32.0, "throw_cooldown": 0.35, "range": 16.0, "draw_time": 0.10,
		"ammo_pack_price_money": 60,
	},
	"ascia_battaglia_lancio": {
		"label": "Ascia da battaglia da lancio", "category": "armi_bianche_lancio", "tier": 5,
		"price_money": 1150, "price_material": "metallo", "price_amount": 30,
		"damage": 65.0, "throw_cooldown": 0.7, "range": 14.0, "draw_time": 0.20,
		"ammo_pack_price_money": 75,
	},
	# Le granate esplosive non colpiscono un solo nemico: esplodono ad area
	# all'impatto (o a fine gittata) e ognuna ha un comportamento unico
	# gestito da scripts/grenade_projectile.gd tramite il campo "grenade_type".
	"molotov": {
		"label": "Molotov", "category": "granate_esplosive", "tier": 1,
		"price_money": 500, "price_material": "legno", "price_amount": 20,
		"damage": 15.0, "throw_cooldown": 1.6, "range": 12.0, "draw_time": 0.3,
		"ammo_pack_price_money": 90,
		"grenade_type": "molotov", "explosion_radius": 3.0,
		"burn_duration": 5.0, "burn_dps": 8.0,
	},
	"granata": {
		"label": "Granata", "category": "granate_esplosive", "tier": 2,
		"price_money": 900, "price_material": "metallo", "price_amount": 35,
		"damage": 55.0, "throw_cooldown": 2.0, "range": 12.0, "draw_time": 0.35,
		"ammo_pack_price_money": 120,
		"grenade_type": "frag", "explosion_radius": 4.0,
	},
	"granata_appiccicosa": {
		"label": "Granata appiccicosa", "category": "granate_esplosive", "tier": 3,
		"price_money": 1400, "price_material": "metallo", "price_amount": 55,
		"damage": 75.0, "throw_cooldown": 2.4, "range": 11.0, "draw_time": 0.4,
		"ammo_pack_price_money": 160,
		"grenade_type": "sticky", "explosion_radius": 4.5,
	},
	"granata_a_grappolo": {
		"label": "Granata a grappolo", "category": "granate_esplosive", "tier": 4,
		"price_money": 2200, "price_material": "metallo", "price_amount": 90,
		"damage": 35.0, "throw_cooldown": 2.8, "range": 10.0, "draw_time": 0.45,
		"ammo_pack_price_money": 230,
		"grenade_type": "cluster", "explosion_radius": 2.5,
		"cluster_count": 4, "cluster_radius": 3.2,
	},
	# Le granate speciali non fanno danno diretto: creano un'area con un
	# effetto non letale (visibilità ridotta o danno costante nel tempo) o
	# stordiscono sul colpo i nemici presenti nell'area di esplosione.
	"granata_fumogena": {
		"label": "Granata fumogena", "category": "granate_speciali", "tier": 1,
		"price_money": 700, "price_material": "metallo", "price_amount": 30,
		"damage": 0.0, "throw_cooldown": 1.8, "range": 12.0, "draw_time": 0.3,
		"ammo_pack_price_money": 100,
		"grenade_type": "fumogena", "explosion_radius": 5.0, "burn_duration": 7.0,
	},
	"granata_stordente": {
		"label": "Granata stordente", "category": "granate_speciali", "tier": 2,
		"price_money": 1100, "price_material": "metallo", "price_amount": 45,
		"damage": 0.0, "throw_cooldown": 2.0, "range": 11.0, "draw_time": 0.35,
		"ammo_pack_price_money": 130,
		"grenade_type": "stordente", "explosion_radius": 4.0, "stun_duration": 2.5,
	},
	"granata_puzzosa": {
		"label": "Granata puzzosa", "category": "granate_speciali", "tier": 3,
		"price_money": 1500, "price_material": "metallo", "price_amount": 60,
		"damage": 0.0, "throw_cooldown": 2.2, "range": 11.0, "draw_time": 0.35,
		"ammo_pack_price_money": 150,
		"grenade_type": "puzzosa", "explosion_radius": 3.5,
		"burn_duration": 10.0, "burn_dps": 6.0,
	},
}

const UPGRADE_TRACK_ORDER := ["portata", "velocita", "danno", "estrazione", "mira", "scorta"]

const UPGRADE_TRACKS := {
	"portata": {"label": "Portata", "desc": "Aumenta la gittata del lancio", "material": "legno", "per_level": 0.03},
	"velocita": {"label": "Velocità di lancio", "desc": "Riduce il tempo tra un lancio e l'altro", "material": "metallo", "per_level": 0.025},
	"danno": {"label": "Danno", "desc": "Aumenta il danno per colpo", "material": "metallo", "per_level": 0.06},
	"estrazione": {"label": "Velocità di estrazione", "desc": "Riduce il tempo per impugnare l'arma", "material": "cablaggi", "per_level": 0.08},
	"mira": {"label": "Mira", "desc": "Allunga la linea di mira e aumenta la precisione del lancio", "material": "cablaggi", "per_level": 0.08},
	"scorta": {"label": "Scorta", "desc": "Aumenta di 1 il numero massimo di questa arma da lancio che puoi portare con te", "material": "cablaggi", "per_level": 1.0},
}

const BASE_RESERVE_CAP := 1

static func final_reserve_cap(weapon_id: String, upgrades: Dictionary) -> int:
	var level: int = upgrades.get("scorta", 0)
	return BASE_RESERVE_CAP + int(upgrade_effect("scorta", level))

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

const AIM_LINE_BASE_LENGTH := 6.0

static func final_aim_line_length(_weapon_id: String, upgrades: Dictionary) -> float:
	var level: int = upgrades.get("mira", 0)
	return AIM_LINE_BASE_LENGTH * (1.0 + upgrade_effect("mira", level))
