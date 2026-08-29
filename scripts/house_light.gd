class_name HouseLight
extends RefCounted

# Luce della casa: crea un cerchio di sicurezza attorno alla casa che il
# buio della "tempesta" non può mai sovrastare (vedi main.gd, storm_*).
# Livello 0 = non acquistata, il buio arriva fino alla porta. Ogni livello
# aumenta il raggio del cerchio: costa parecchio, materiale cablaggi (è un
# impianto elettrico), coerente con l'idea di essere un investimento serio.
const LEVELS := {
	1: {"radius": 8.0, "cost_money": 5000, "cost_material": "cablaggi", "cost_amount": 150},
	2: {"radius": 12.0, "cost_money": 12000, "cost_material": "cablaggi", "cost_amount": 300},
	3: {"radius": 16.0, "cost_money": 25000, "cost_material": "cablaggi", "cost_amount": 500},
	4: {"radius": 20.0, "cost_money": 45000, "cost_material": "cablaggi", "cost_amount": 750},
	5: {"radius": 24.0, "cost_money": 70000, "cost_material": "cablaggi", "cost_amount": 1000},
}

const MAX_LEVEL := 5

static func radius_for_level(level: int) -> float:
	if level <= 0:
		return 0.0
	return float(LEVELS[clampi(level, 1, MAX_LEVEL)].radius)

static func is_max_level(level: int) -> bool:
	return level >= MAX_LEVEL

static func next_level_data(level: int) -> Dictionary:
	return LEVELS[clampi(level + 1, 1, MAX_LEVEL)]
