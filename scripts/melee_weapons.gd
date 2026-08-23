class_name MeleeWeapons
extends RefCounted

const CATEGORY_ORDER := ["coltelli", "spade", "mazze", "martelli", "lance"]

const CATEGORIES := {
	"coltelli": {"label": "Coltelli", "unlocked": true},
	"spade": {"label": "Spade", "unlocked": true},
	"mazze": {"label": "Mazze", "unlocked": true},
	"martelli": {"label": "Martelli", "unlocked": true},
	"lance": {"label": "Lance", "unlocked": true},
}

const CATEGORY_WEAPONS := {
	"coltelli": ["coltello_cucina", "a_scatto", "serramanico", "tattico", "rambo"],
	"spade": ["spada_giocattolo", "spada_da_scena", "sciabola_arrugginita", "katana_da_allenamento", "spadone_leggendario"],
	"mazze": ["mazza_baseball", "spranga_ferro", "mazza_chiodata", "mazza_da_golf_rinforzata", "mazza_da_guerra"],
	"martelli": ["martello_carpentiere", "martello_fabbro", "mazzuolo_pesante", "martello_demolizione", "martello_da_guerra"],
	"lance": ["bastone_appuntito", "forca_giardino", "lancia_da_pesca", "lancia_da_combattimento", "lancia_cerimoniale"],
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

	"spada_giocattolo": {
		"label": "Spada giocattolo", "category": "spade", "tier": 1,
		"price_money": 90, "price_material": "legno", "price_amount": 4,
		"damage": 22.0, "cooldown": 0.40, "reach_mult": 1.20, "draw_time": 0.15,
	},
	"spada_da_scena": {
		"label": "Spada da scena", "category": "spade", "tier": 2,
		"price_money": 190, "price_material": "metallo", "price_amount": 6,
		"damage": 28.0, "cooldown": 0.38, "reach_mult": 1.25, "draw_time": 0.13,
	},
	"sciabola_arrugginita": {
		"label": "Sciabola arrugginita", "category": "spade", "tier": 3,
		"price_money": 340, "price_material": "metallo", "price_amount": 10,
		"damage": 36.0, "cooldown": 0.36, "reach_mult": 1.30, "draw_time": 0.11,
	},
	"katana_da_allenamento": {
		"label": "Katana da allenamento", "category": "spade", "tier": 4,
		"price_money": 560, "price_material": "metallo", "price_amount": 16,
		"damage": 46.0, "cooldown": 0.34, "reach_mult": 1.35, "draw_time": 0.09,
	},
	"spadone_leggendario": {
		"label": "Spadone leggendario", "category": "spade", "tier": 5,
		"price_money": 950, "price_material": "metallo", "price_amount": 26,
		"damage": 62.0, "cooldown": 0.32, "reach_mult": 1.45, "draw_time": 0.06,
	},

	"mazza_baseball": {
		"label": "Mazza da baseball", "category": "mazze", "tier": 1,
		"price_money": 100, "price_material": "legno", "price_amount": 4,
		"damage": 30.0, "cooldown": 0.55, "reach_mult": 1.00, "draw_time": 0.20,
	},
	"spranga_ferro": {
		"label": "Spranga di ferro", "category": "mazze", "tier": 2,
		"price_money": 210, "price_material": "metallo", "price_amount": 8,
		"damage": 38.0, "cooldown": 0.52, "reach_mult": 1.00, "draw_time": 0.18,
	},
	"mazza_chiodata": {
		"label": "Mazza chiodata", "category": "mazze", "tier": 3,
		"price_money": 380, "price_material": "metallo", "price_amount": 12,
		"damage": 50.0, "cooldown": 0.50, "reach_mult": 1.05, "draw_time": 0.16,
	},
	"mazza_da_golf_rinforzata": {
		"label": "Mazza da golf rinforzata", "category": "mazze", "tier": 4,
		"price_money": 600, "price_material": "metallo", "price_amount": 18,
		"damage": 62.0, "cooldown": 0.47, "reach_mult": 1.05, "draw_time": 0.14,
	},
	"mazza_da_guerra": {
		"label": "Mazza da guerra", "category": "mazze", "tier": 5,
		"price_money": 1000, "price_material": "metallo", "price_amount": 30,
		"damage": 85.0, "cooldown": 0.45, "reach_mult": 1.10, "draw_time": 0.10,
	},

	"martello_carpentiere": {
		"label": "Martello da carpentiere", "category": "martelli", "tier": 1,
		"price_money": 110, "price_material": "legno", "price_amount": 5,
		"damage": 40.0, "cooldown": 0.65, "reach_mult": 0.95, "draw_time": 0.25,
	},
	"martello_fabbro": {
		"label": "Martello da fabbro", "category": "martelli", "tier": 2,
		"price_money": 230, "price_material": "metallo", "price_amount": 9,
		"damage": 52.0, "cooldown": 0.62, "reach_mult": 0.95, "draw_time": 0.22,
	},
	"mazzuolo_pesante": {
		"label": "Mazzuolo pesante", "category": "martelli", "tier": 3,
		"price_money": 420, "price_material": "metallo", "price_amount": 14,
		"damage": 68.0, "cooldown": 0.60, "reach_mult": 1.00, "draw_time": 0.20,
	},
	"martello_demolizione": {
		"label": "Martello da demolizione", "category": "martelli", "tier": 4,
		"price_money": 680, "price_material": "metallo", "price_amount": 20,
		"damage": 88.0, "cooldown": 0.57, "reach_mult": 1.00, "draw_time": 0.18,
	},
	"martello_da_guerra": {
		"label": "Martello da guerra", "category": "martelli", "tier": 5,
		"price_money": 1100, "price_material": "metallo", "price_amount": 34,
		"damage": 120.0, "cooldown": 0.55, "reach_mult": 1.05, "draw_time": 0.14,
	},

	"bastone_appuntito": {
		"label": "Bastone appuntito", "category": "lance", "tier": 1,
		"price_money": 85, "price_material": "legno", "price_amount": 4,
		"damage": 18.0, "cooldown": 0.40, "reach_mult": 1.40, "draw_time": 0.15,
	},
	"forca_giardino": {
		"label": "Forca da giardino", "category": "lance", "tier": 2,
		"price_money": 185, "price_material": "metallo", "price_amount": 6,
		"damage": 24.0, "cooldown": 0.38, "reach_mult": 1.50, "draw_time": 0.13,
	},
	"lancia_da_pesca": {
		"label": "Lancia da pesca", "category": "lance", "tier": 3,
		"price_money": 330, "price_material": "metallo", "price_amount": 10,
		"damage": 32.0, "cooldown": 0.36, "reach_mult": 1.60, "draw_time": 0.11,
	},
	"lancia_da_combattimento": {
		"label": "Lancia da combattimento", "category": "lance", "tier": 4,
		"price_money": 540, "price_material": "metallo", "price_amount": 16,
		"damage": 42.0, "cooldown": 0.34, "reach_mult": 1.75, "draw_time": 0.09,
	},
	"lancia_cerimoniale": {
		"label": "Lancia cerimoniale forgiata", "category": "lance", "tier": 5,
		"price_money": 920, "price_material": "metallo", "price_amount": 26,
		"damage": 58.0, "cooldown": 0.32, "reach_mult": 1.90, "draw_time": 0.06,
	},
}

const UPGRADE_TRACK_ORDER := ["portata", "velocita", "danno", "estrazione"]

# "max_effect" è il tetto asintotico dell'effetto (mai raggiunto del tutto,
# solo avvicinato): stesso tetto di potenza del vecchio sistema a 10 livelli
# (10 * il vecchio "per_level"), ma spalmato su molti più livelli con
# rendimenti decrescenti — vedi upgrade_effect() più sotto.
const UPGRADE_TRACKS := {
	"portata": {"label": "Portata", "desc": "Aumenta la portata dell'arma", "material": "legno", "max_effect": 0.30},
	"velocita": {"label": "Velocità d'attacco", "desc": "Riduce il tempo tra un attacco e l'altro", "material": "metallo", "max_effect": 0.20},
	"danno": {"label": "Danno", "desc": "Aumenta il danno dell'arma", "material": "metallo", "max_effect": 0.60},
	"estrazione": {"label": "Velocità di estrazione", "desc": "Riduce il tempo per sguainare l'arma", "material": "cablaggi", "max_effect": 0.80},
}

const UPGRADE_MAX_LEVEL := 50
const UPGRADE_BASE_MONEY := 30
const UPGRADE_BASE_MAT := 3
# Il costo cresce con una potenza (non più esponenziale): resta un traguardo
# sempre più impegnativo ma senza esplodere a livelli molto alti, così il
# sistema regge facilmente centinaia di livelli se in futuro si alza il tetto.
const UPGRADE_COST_POWER := 1.7
# Scala (in livelli) della curva a rendimenti decrescenti: più è alta, più
# lentamente l'effetto si avvicina al suo tetto massimo. A UPGRADE_MAX_LEVEL
# si è già oltre il 94% del tetto, quindi l'utilità di ogni livello aggiuntivo
# resta sempre positiva ma via via più piccola — mai un salto grande in un
# solo livello, e ogni tier di livelli superiore aggiunge sempre meno del
# precedente.
const UPGRADE_SATURATION_LEVELS := 17.0

static func weapon_price_money(weapon_id: String) -> int:
	return int(WEAPONS[weapon_id].price_money)

static func weapon_price_material(weapon_id: String) -> String:
	return String(WEAPONS[weapon_id].price_material)

static func weapon_price_amount(weapon_id: String) -> int:
	return int(WEAPONS[weapon_id].price_amount)

static func upgrade_cost_money(weapon_id: String, level: int) -> int:
	var tier: int = WEAPONS[weapon_id].tier
	return int(round(UPGRADE_BASE_MONEY * tier * pow(level + 1, UPGRADE_COST_POWER)))

static func upgrade_cost_material(weapon_id: String, level: int) -> int:
	var tier: int = WEAPONS[weapon_id].tier
	return int(round(UPGRADE_BASE_MAT * tier * pow(level + 1, UPGRADE_COST_POWER)))

static func upgrade_is_maxed(level: int) -> bool:
	return level >= UPGRADE_MAX_LEVEL

static func upgrade_effect(track_id: String, level: int) -> float:
	var max_effect: float = float(UPGRADE_TRACKS[track_id].max_effect)
	return max_effect * (1.0 - exp(-float(level) / UPGRADE_SATURATION_LEVELS))

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
