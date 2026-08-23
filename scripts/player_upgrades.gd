class_name PlayerUpgrades
extends RefCounted

# Stessa curva a rendimenti decrescenti dei potenziamenti delle armi (vedi
# melee_weapons.gd/firearms.gd/throwables.gd): "max_effect" è il tetto
# asintotico dell'effetto (mai raggiunto del tutto, solo avvicinato),
# calibrato per coincidere col vecchio tetto a 10 livelli (10 * il vecchio
# "per_level"), ma spalmato su MAX_LEVEL livelli con rendimenti via via più
# piccoli — niente salto di potenza, solo una salita molto più graduale ed
# estendibile a molti più livelli.
const DEFS := {
	"scarpe": {
		"label": "Scarpe migliori", "desc": "Aumenta la velocità di movimento",
		"material": "metallo", "base_money": 40, "base_mat": 3, "max_effect": 0.45,
	},
	"salute": {
		"label": "Salute", "desc": "Aumenta la vita massima",
		"material": "legno", "base_money": 55, "base_mat": 4, "max_effect": 400.0,
	},
	"saccheggio": {
		"label": "Saccheggio", "desc": "Aumenta i soldi guadagnati dai nemici",
		"material": "cablaggi", "base_money": 45, "base_mat": 3, "max_effect": 0.6,
	},
	"sicurezza": {
		"label": "Sicurezza", "desc": "Riduce i soldi rubati dai nemici",
		"material": "metallo", "base_money": 50, "base_mat": 3, "max_effect": 0.9,
	},
	"zaino": {
		"label": "Zaino", "desc": "Aumenta i materiali ottenuti dagli oggetti",
		"material": "legno", "base_money": 45, "base_mat": 3, "max_effect": 0.8,
	},
}

const ORDER := ["scarpe", "salute", "saccheggio", "sicurezza", "zaino"]

const MAX_LEVEL := 100
# Il costo cresce con una potenza (non più esponenziale): stesso schema dei
# potenziamenti delle armi, resta impegnativo ma non esplode a livelli alti.
const COST_POWER := 1.7
# Scala (in livelli) della curva a rendimenti decrescenti: a MAX_LEVEL si è
# già oltre il 94% del tetto massimo, stesso rapporto usato per le armi.
const SATURATION_LEVELS := 34.0

static func cost_money(id: String, level: int) -> int:
	var d: Dictionary = DEFS[id]
	return int(round(float(d.base_money) * pow(level + 1, COST_POWER)))

static func cost_material(id: String, level: int) -> int:
	var d: Dictionary = DEFS[id]
	return int(round(float(d.base_mat) * pow(level + 1, COST_POWER)))

static func is_maxed(id: String, level: int) -> bool:
	return level >= MAX_LEVEL

static func effect(id: String, level: int) -> float:
	var max_effect: float = float(DEFS[id].max_effect)
	return max_effect * (1.0 - exp(-float(level) / SATURATION_LEVELS))
