class_name Scenarios
extends RefCounted

# Ogni scenario "veste" 50 zone (stesso intervallo dei checkpoint): il
# campo da gioco (terreno/muri/cielo) cambia di netto esattamente alla
# zona-checkpoint (50, 100, 150...), mentre l'aspetto di alberi e nemici
# transita gradualmente nelle ultime TRANSITION_WINDOW zone prima del
# checkpoint (vedi transition_progress). La casa non è mai toccata da
# questo sistema: resta quella scelta dal player con l'Armadio.
#
# Per aggiungere un nuovo scenario in futuro: aggiungere una voce a DATA
# col prossimo indice, stesso schema delle altre. Nessun'altra modifica
# al codice è necessaria.

const SCENARIO_ZONE_SPAN := 50
const TRANSITION_WINDOW := 15
const TRANSITION_MAX_PROGRESS := 0.87

const DATA := {
	0: {
		"label": "Parco",
		"floor_color": Color(0.42, 0.58, 0.32, 1),
		"wall_color": Color(0.35, 0.18, 0.16, 1),
		"sky_top_color": Color(0.15, 0.18, 0.35, 1),
		"sky_horizon_color": Color(0.45, 0.4, 0.4, 1),
		"ground_bottom_color": Color(0.05, 0.05, 0.06, 1),
		"ground_horizon_color": Color(0.3, 0.28, 0.28, 1),
		"ambient_light_color": Color(0.6, 0.6, 0.7, 1),
		"ambient_light_energy": 0.6,
		"tree_trunk_color": Color(0.3, 0.2, 0.12, 1),
		"tree_foliage_color": Color(0.15, 0.45, 0.18, 1),
		"tree_shape": "sphere",
		"enemy_colors": {
			"balordo": Color(0.54, 0.45, 0.33),
			"nervoso": Color(0.88, 0.44, 0.24),
			"imprevedibile": Color(0.61, 0.35, 0.82),
			"bruto": Color(0.36, 0.15, 0.15),
			"tiratore": Color(0.29, 0.42, 0.48),
		},
	},
	1: {
		"label": "Bosco",
		"floor_color": Color(0.24, 0.32, 0.18, 1),
		"wall_color": Color(0.22, 0.16, 0.11, 1),
		"sky_top_color": Color(0.10, 0.14, 0.12, 1),
		"sky_horizon_color": Color(0.28, 0.30, 0.22, 1),
		"ground_bottom_color": Color(0.04, 0.05, 0.04, 1),
		"ground_horizon_color": Color(0.20, 0.20, 0.15, 1),
		"ambient_light_color": Color(0.5, 0.55, 0.45, 1),
		"ambient_light_energy": 0.45,
		"tree_trunk_color": Color(0.18, 0.12, 0.08, 1),
		"tree_foliage_color": Color(0.08, 0.28, 0.14, 1),
		"tree_shape": "cone",
		"enemy_colors": {
			"balordo": Color(0.34, 0.38, 0.22),
			"nervoso": Color(0.62, 0.34, 0.18),
			"imprevedibile": Color(0.42, 0.22, 0.52),
			"bruto": Color(0.24, 0.10, 0.10),
			"tiratore": Color(0.16, 0.30, 0.32),
		},
	},
	2: {
		"label": "Palude",
		"floor_color": Color(0.28, 0.26, 0.16, 1),
		"wall_color": Color(0.30, 0.32, 0.26, 1),
		"sky_top_color": Color(0.22, 0.24, 0.16, 1),
		"sky_horizon_color": Color(0.38, 0.36, 0.26, 1),
		"ground_bottom_color": Color(0.05, 0.05, 0.04, 1),
		"ground_horizon_color": Color(0.30, 0.28, 0.20, 1),
		"ambient_light_color": Color(0.55, 0.58, 0.48, 1),
		"ambient_light_energy": 0.5,
		"tree_trunk_color": Color(0.24, 0.20, 0.16, 1),
		"tree_foliage_color": Color(0.42, 0.40, 0.22, 1),
		"tree_shape": "sparse",
		"enemy_colors": {
			"balordo": Color(0.42, 0.44, 0.30),
			"nervoso": Color(0.58, 0.42, 0.20),
			"imprevedibile": Color(0.48, 0.30, 0.46),
			"bruto": Color(0.30, 0.22, 0.14),
			"tiratore": Color(0.24, 0.34, 0.30),
		},
	},
}

static func scenario_count() -> int:
	return DATA.size()

static func scenario_index_for_zone(zone: int) -> int:
	var idx: int = zone / SCENARIO_ZONE_SPAN
	return clampi(idx, 0, DATA.size() - 1)

static func scenario_data(index: int) -> Dictionary:
	var i: int = clampi(index, 0, DATA.size() - 1)
	return DATA[i]

static func next_scenario_index_for_zone(zone: int) -> int:
	return clampi(scenario_index_for_zone(zone) + 1, 0, DATA.size() - 1)

# Probabilità (0..1) che un albero/nemico che nasce in questa zona usi già
# l'aspetto dello scenario successivo invece di quello corrente: 0 prima
# della finestra di transizione, poi una parabola che cresce lenta
# all'inizio e più rapida verso la fine (0.87 * t^2), fino a
# TRANSITION_MAX_PROGRESS all'ultima zona prima del checkpoint. Il
# checkpoint stesso (gestito da scenario_index_for_zone) porta tutto al
# 100% col nuovo scenario che diventa quello corrente.
static func transition_progress(zone: int) -> float:
	var next_checkpoint: int = (scenario_index_for_zone(zone) + 1) * SCENARIO_ZONE_SPAN
	var start_zone: int = next_checkpoint - TRANSITION_WINDOW
	var end_zone: int = next_checkpoint - 1
	if zone < start_zone or zone > end_zone:
		return 0.0
	var t: float = float(zone - start_zone) / float(TRANSITION_WINDOW - 1)
	return TRANSITION_MAX_PROGRESS * t * t
