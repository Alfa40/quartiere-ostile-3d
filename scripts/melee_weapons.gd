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
		"price_money": 260, "price_material": "legno", "price_amount": 4,
		"damage": 24.0, "cooldown": 0.42, "reach_mult": 1.05, "draw_time": 0.15,
	},
	"a_scatto": {
		"label": "A scatto", "category": "coltelli", "tier": 2,
		"price_money": 495, "price_material": "metallo", "price_amount": 6,
		"damage": 30.0, "cooldown": 0.38, "reach_mult": 1.05, "draw_time": 0.12,
	},
	"serramanico": {
		"label": "Serramanico", "category": "coltelli", "tier": 3,
		"price_money": 940, "price_material": "metallo", "price_amount": 10,
		"damage": 38.0, "cooldown": 0.35, "reach_mult": 1.10, "draw_time": 0.10,
	},
	"tattico": {
		"label": "Tattico", "category": "coltelli", "tier": 4,
		"price_money": 1785, "price_material": "metallo", "price_amount": 16,
		"damage": 48.0, "cooldown": 0.32, "reach_mult": 1.15, "draw_time": 0.08,
	},
	"rambo": {
		"label": "Coltellazzo di Rambo", "category": "coltelli", "tier": 5,
		"price_money": 3390, "price_material": "metallo", "price_amount": 26,
		"damage": 65.0, "cooldown": 0.30, "reach_mult": 1.25, "draw_time": 0.05,
	},

	"spada_giocattolo": {
		"label": "Spada giocattolo", "category": "spade", "tier": 1,
		"price_money": 420, "price_material": "legno", "price_amount": 4,
		"damage": 25.0, "cooldown": 0.40, "reach_mult": 1.20, "draw_time": 0.15, "knockback": 1.0,
	},
	"spada_da_scena": {
		"label": "Spada da scena", "category": "spade", "tier": 2,
		"price_money": 800, "price_material": "metallo", "price_amount": 6,
		"damage": 33.0, "cooldown": 0.38, "reach_mult": 1.25, "draw_time": 0.13, "knockback": 1.2,
	},
	"sciabola_arrugginita": {
		"label": "Sciabola arrugginita", "category": "spade", "tier": 3,
		"price_money": 1515, "price_material": "metallo", "price_amount": 10,
		"damage": 43.0, "cooldown": 0.36, "reach_mult": 1.30, "draw_time": 0.11, "knockback": 1.4,
	},
	"katana_da_allenamento": {
		"label": "Katana da allenamento", "category": "spade", "tier": 4,
		"price_money": 2880, "price_material": "metallo", "price_amount": 16,
		"damage": 56.0, "cooldown": 0.34, "reach_mult": 1.35, "draw_time": 0.09, "knockback": 1.6,
	},
	"spadone_leggendario": {
		"label": "Spadone leggendario", "category": "spade", "tier": 5,
		"price_money": 5475, "price_material": "metallo", "price_amount": 26,
		"damage": 76.0, "cooldown": 0.32, "reach_mult": 1.45, "draw_time": 0.06, "knockback": 1.8,
	},

	"mazza_baseball": {
		"label": "Mazza da baseball", "category": "mazze", "tier": 1,
		"price_money": 650, "price_material": "legno", "price_amount": 4,
		"damage": 41.0, "cooldown": 1.50, "reach_mult": 1.00, "draw_time": 0.20, "knockback": 2.0,
	},
	"spranga_ferro": {
		"label": "Spranga di ferro", "category": "mazze", "tier": 2,
		"price_money": 1235, "price_material": "metallo", "price_amount": 8,
		"damage": 53.0, "cooldown": 1.40, "reach_mult": 1.00, "draw_time": 0.18, "knockback": 2.3,
	},
	"mazza_chiodata": {
		"label": "Mazza chiodata", "category": "mazze", "tier": 3,
		"price_money": 2345, "price_material": "metallo", "price_amount": 12,
		"damage": 71.0, "cooldown": 1.35, "reach_mult": 1.05, "draw_time": 0.16, "knockback": 2.6,
	},
	"mazza_da_golf_rinforzata": {
		"label": "Mazza da golf rinforzata", "category": "mazze", "tier": 4,
		"price_money": 4460, "price_material": "metallo", "price_amount": 18,
		"damage": 92.0, "cooldown": 1.25, "reach_mult": 1.05, "draw_time": 0.14, "knockback": 2.9,
	},
	"mazza_da_guerra": {
		"label": "Mazza da guerra", "category": "mazze", "tier": 5,
		"price_money": 8470, "price_material": "metallo", "price_amount": 30,
		"damage": 127.0, "cooldown": 1.20, "reach_mult": 1.10, "draw_time": 0.10, "knockback": 3.2,
	},

	"martello_carpentiere": {
		"label": "Martello da carpentiere", "category": "martelli", "tier": 1,
		"price_money": 950, "price_material": "legno", "price_amount": 5,
		"damage": 58.0, "cooldown": 2.00, "reach_mult": 0.95, "draw_time": 0.25, "knockback": 1.8,
	},
	"martello_fabbro": {
		"label": "Martello da fabbro", "category": "martelli", "tier": 2,
		"price_money": 1805, "price_material": "metallo", "price_amount": 9,
		"damage": 76.0, "cooldown": 1.90, "reach_mult": 0.95, "draw_time": 0.22, "knockback": 2.2,
	},
	"mazzuolo_pesante": {
		"label": "Mazzuolo pesante", "category": "martelli", "tier": 3,
		"price_money": 3430, "price_material": "metallo", "price_amount": 14,
		"damage": 101.0, "cooldown": 1.85, "reach_mult": 1.00, "draw_time": 0.20, "knockback": 2.7,
	},
	"martello_demolizione": {
		"label": "Martello da demolizione", "category": "martelli", "tier": 4,
		"price_money": 6515, "price_material": "metallo", "price_amount": 20,
		"damage": 133.0, "cooldown": 1.75, "reach_mult": 1.00, "draw_time": 0.18, "knockback": 3.3,
	},
	"martello_da_guerra": {
		"label": "Martello da guerra", "category": "martelli", "tier": 5,
		"price_money": 12380, "price_material": "metallo", "price_amount": 34,
		"damage": 185.0, "cooldown": 1.70, "reach_mult": 1.05, "draw_time": 0.14, "knockback": 4.5,
	},

	"bastone_appuntito": {
		"label": "Bastone appuntito", "category": "lance", "tier": 1,
		"price_money": 100, "price_material": "legno", "price_amount": 4,
		"damage": 18.0, "cooldown": 0.50, "reach_mult": 1.40, "draw_time": 0.15, "knockback": 2.5,
	},
	"forca_giardino": {
		"label": "Forca da giardino", "category": "lance", "tier": 2,
		"price_money": 190, "price_material": "metallo", "price_amount": 6,
		"damage": 24.0, "cooldown": 0.48, "reach_mult": 1.50, "draw_time": 0.13, "knockback": 3.0,
	},
	"lancia_da_pesca": {
		"label": "Lancia da pesca", "category": "lance", "tier": 3,
		"price_money": 360, "price_material": "metallo", "price_amount": 10,
		"damage": 31.0, "cooldown": 0.45, "reach_mult": 1.60, "draw_time": 0.11, "knockback": 3.6,
	},
	"lancia_da_combattimento": {
		"label": "Lancia da combattimento", "category": "lance", "tier": 4,
		"price_money": 685, "price_material": "metallo", "price_amount": 16,
		"damage": 41.0, "cooldown": 0.42, "reach_mult": 1.75, "draw_time": 0.09, "knockback": 4.3,
	},
	"lancia_cerimoniale": {
		"label": "Lancia cerimoniale forgiata", "category": "lance", "tier": 5,
		"price_money": 1305, "price_material": "metallo", "price_amount": 26,
		"damage": 55.0, "cooldown": 0.40, "reach_mult": 1.90, "draw_time": 0.06, "knockback": 5.2,
	},
}

const UPGRADE_TRACK_ORDER := ["portata", "velocita", "danno", "estrazione", "respinta"]

# Solo le armi bianche abbastanza pesanti/grosse da spingere fisicamente un
# nemico colpito hanno l'effetto (e il potenziamento) di respinta: coltelli
# (leggeri, da punta) ne restano sprovvisti.
const KNOCKBACK_CATEGORIES := ["spade", "mazze", "martelli", "lance"]

# "max_effect" è il tetto asintotico dell'effetto (mai raggiunto del tutto,
# solo avvicinato): stesso tetto di potenza del vecchio sistema a 10 livelli
# (10 * il vecchio "per_level"), ma spalmato su molti più livelli con
# rendimenti decrescenti — vedi upgrade_effect() più sotto. "respinta" è
# volutamente diverso dagli altri: pochi livelli (max_level basso) ma un
# effetto che cresce molto più rapidamente (saturation_levels bassa) e un
# costo per livello più alto (cost_scale > 1) — un potenziamento più corto
# ma più "d'impatto" e più caro degli altri, non un'ennesima progressione
# a 50 livelli.
const UPGRADE_TRACKS := {
	"portata": {
		"label": "Portata", "desc": "Aumenta la portata dell'arma", "material": "legno",
		"max_effect": 0.30, "max_level": 50, "saturation_levels": 17.0, "cost_scale": 1.0,
	},
	"velocita": {
		"label": "Velocità d'attacco", "desc": "Riduce il tempo tra un attacco e l'altro", "material": "metallo",
		"max_effect": 0.20, "max_level": 50, "saturation_levels": 17.0, "cost_scale": 1.0,
	},
	"danno": {
		"label": "Danno", "desc": "Aumenta il danno dell'arma", "material": "metallo",
		"max_effect": 0.60, "max_level": 50, "saturation_levels": 17.0, "cost_scale": 1.0,
	},
	"estrazione": {
		"label": "Velocità di estrazione", "desc": "Riduce il tempo per sguainare l'arma", "material": "cablaggi",
		"max_effect": 0.80, "max_level": 50, "saturation_levels": 17.0, "cost_scale": 1.0,
	},
	"respinta": {
		"label": "Respinta", "desc": "Aumenta la forza con cui l'arma respinge i nemici colpiti", "material": "cablaggi",
		"max_effect": 1.4, "max_level": 15, "saturation_levels": 4.0, "cost_scale": 2.5,
	},
}

const UPGRADE_BASE_MONEY := 30
const UPGRADE_BASE_MAT := 3
# Il costo cresce con una potenza (non più esponenziale): resta un traguardo
# sempre più impegnativo ma senza esplodere a livelli molto alti, così il
# sistema regge facilmente centinaia di livelli se in futuro si alza il tetto.
const UPGRADE_COST_POWER := 1.7

static func weapon_price_money(weapon_id: String) -> int:
	return int(WEAPONS[weapon_id].price_money)

static func weapon_price_material(weapon_id: String) -> String:
	return String(WEAPONS[weapon_id].price_material)

static func weapon_price_amount(weapon_id: String) -> int:
	return int(WEAPONS[weapon_id].price_amount)

# Tracce di potenziamento disponibili per una specifica arma: tutte le armi
# bianche hanno portata/velocità/danno/estrazione, ma solo quelle abbastanza
# grosse (vedi KNOCKBACK_CATEGORIES) hanno anche la respinta.
static func weapon_upgrade_tracks(weapon_id: String) -> Array:
	var cat: String = String(WEAPONS[weapon_id].category)
	if KNOCKBACK_CATEGORIES.has(cat):
		return UPGRADE_TRACK_ORDER
	return ["portata", "velocita", "danno", "estrazione"]

static func upgrade_cost_money(weapon_id: String, level: int, track_id: String) -> int:
	var tier: int = WEAPONS[weapon_id].tier
	var scale: float = float(UPGRADE_TRACKS[track_id].cost_scale)
	return int(round(UPGRADE_BASE_MONEY * tier * scale * pow(level + 1, UPGRADE_COST_POWER)))

static func upgrade_cost_material(weapon_id: String, level: int, track_id: String) -> int:
	var tier: int = WEAPONS[weapon_id].tier
	var scale: float = float(UPGRADE_TRACKS[track_id].cost_scale)
	return int(round(UPGRADE_BASE_MAT * tier * scale * pow(level + 1, UPGRADE_COST_POWER)))

static func upgrade_is_maxed(level: int, track_id: String) -> bool:
	return level >= int(UPGRADE_TRACKS[track_id].max_level)

# Scala (in livelli) della curva a rendimenti decrescenti: più è alta, più
# lentamente l'effetto si avvicina al suo tetto massimo. Ogni traccia ha la
# propria scala/tetto (vedi UPGRADE_TRACKS) — "respinta" ne ha una molto
# più bassa apposta, per crescere più rapidamente e visibilmente nei suoi
# pochi livelli.
static func upgrade_effect(track_id: String, level: int) -> float:
	var t: Dictionary = UPGRADE_TRACKS[track_id]
	var max_effect: float = float(t.max_effect)
	var saturation: float = float(t.saturation_levels)
	return max_effect * (1.0 - exp(-float(level) / saturation))

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

# 0.0 per le armi troppo leggere/piccole per avere un effetto di respinta
# (vedi KNOCKBACK_CATEGORIES).
static func final_knockback(weapon_id: String, upgrades: Dictionary) -> float:
	var def: Dictionary = WEAPONS[weapon_id]
	if not def.has("knockback"):
		return 0.0
	var base: float = float(def.knockback)
	var level: int = upgrades.get("respinta", 0)
	return base * (1.0 + upgrade_effect("respinta", level))
