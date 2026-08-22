class_name PlayerUpgrades
extends RefCounted

const DEFS := {
	"scarpe": {
		"label": "Scarpe migliori", "desc": "Aumenta la velocità di movimento",
		"material": "metallo", "base_money": 40, "base_mat": 3, "growth": 1.4,
		"max_level": 10, "per_level": 0.045,
	},
	"salute": {
		"label": "Salute", "desc": "Aumenta la vita massima",
		"material": "legno", "base_money": 55, "base_mat": 4, "growth": 1.35,
		"max_level": 10, "per_level": 40.0,
	},
	"saccheggio": {
		"label": "Saccheggio", "desc": "Aumenta i soldi guadagnati dai nemici",
		"material": "cablaggi", "base_money": 45, "base_mat": 3, "growth": 1.4,
		"max_level": 10, "per_level": 0.06,
	},
	"sicurezza": {
		"label": "Sicurezza", "desc": "Riduce i soldi rubati dai nemici",
		"material": "metallo", "base_money": 50, "base_mat": 3, "growth": 1.4,
		"max_level": 10, "per_level": 0.09,
	},
	"zaino": {
		"label": "Zaino", "desc": "Aumenta i materiali ottenuti dagli oggetti",
		"material": "legno", "base_money": 45, "base_mat": 3, "growth": 1.4,
		"max_level": 10, "per_level": 0.08,
	},
}

const ORDER := ["scarpe", "salute", "saccheggio", "sicurezza", "zaino"]

static func cost_money(id: String, level: int) -> int:
	var d: Dictionary = DEFS[id]
	return int(round(d.base_money * pow(d.growth, level)))

static func cost_material(id: String, level: int) -> int:
	var d: Dictionary = DEFS[id]
	return int(round(d.base_mat * pow(d.growth, level)))

static func is_maxed(id: String, level: int) -> bool:
	return level >= int(DEFS[id].max_level)

static func effect(id: String, level: int) -> float:
	return level * float(DEFS[id].per_level)
