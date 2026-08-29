class_name Mushrooms
extends RefCounted

# 7 varietà, dalla più comune alla più rara: tutte possono comparire fin
# dalla zona 1 (vedi main.gd:_spawn_mushrooms), ma con probabilità di spawn
# molto diverse (spawn_weight, un peso relativo — non una percentuale
# assoluta) così quelle rare si trovano via via che si gioca a lungo,
# senza bisogno di alcuna soglia di zona. Servono da ingrediente per
# cucinare i piatti in recipes.gd (una per piatto, dalla più comune per il
# più economico alla più rara per il più prelibato).
const ORDER := ["comune", "maculato", "dorato", "silvestre", "leggendario", "dorato_splendente", "aurora"]

const DATA := {
	"comune": {"label": "Fungo comune", "color": Color(0.75, 0.6, 0.45), "spawn_weight": 100},
	"maculato": {"label": "Fungo maculato", "color": Color(0.85, 0.2, 0.2), "spawn_weight": 45},
	"dorato": {"label": "Fungo dorato", "color": Color(0.9, 0.75, 0.15), "spawn_weight": 20},
	"silvestre": {"label": "Fungo silvestre raro", "color": Color(0.35, 0.55, 0.3), "spawn_weight": 9},
	"leggendario": {"label": "Fungo leggendario", "color": Color(0.55, 0.25, 0.85), "spawn_weight": 4},
	"dorato_splendente": {"label": "Fungo dorato splendente", "color": Color(1.0, 0.85, 0.3), "spawn_weight": 2},
	"aurora": {"label": "Fungo dell'aurora", "color": Color(0.3, 0.85, 0.9), "spawn_weight": 1},
}

# Sceglie un fungo a caso pesato su spawn_weight: sommo i pesi, tiro un
# numero nell'intervallo totale, e prendo il primo la cui fascia cumulativa
# lo supera — così quelli con peso più alto (comuni) hanno più fette della
# torta, senza bisogno di normalizzare a percentuali.
static func random_id() -> String:
	var total := 0
	for id in ORDER:
		total += int(DATA[id].spawn_weight)
	var roll := randi() % total
	var cumulative := 0
	for id in ORDER:
		cumulative += int(DATA[id].spawn_weight)
		if roll < cumulative:
			return id
	return ORDER[0]
