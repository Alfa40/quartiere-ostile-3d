class_name Scenarios
extends RefCounted

# Ogni scenario "veste" le zone fino al checkpoint successivo: il campo da
# gioco (terreno/muri/cielo) cambia di netto esattamente alla zona-checkpoint,
# mentre l'aspetto di alberi e nemici transita gradualmente nelle ultime
# TRANSITION_WINDOW zone prima del checkpoint (vedi transition_progress). La
# casa non è mai toccata da questo sistema: resta quella scelta dal player
# con l'Armadio.
#
# I confini degli scenari coincidono con quelli dei checkpoint (stesse soglie
# di CheckpointData.is_checkpoint_zone, duplicate qui in TIER1/2/3_*: se si
# cambia una delle due va aggiornata anche l'altra) — così ogni volta che il
# player raggiunge un checkpoint, anche lo scenario cambia.
#
# Per aggiungere un nuovo scenario in futuro: aggiungere una voce a DATA col
# prossimo indice, stesso schema delle altre. Nessun'altra modifica al
# codice è necessaria.

const TIER1_INTERVAL := 20
const TIER1_END := 100
const TIER2_INTERVAL := 30
const TIER2_END := 250
const TIER3_INTERVAL := 50

const TRANSITION_WINDOW := 15
const TRANSITION_MAX_PROGRESS := 0.87

const DATA := {
	0: {
		"label": "Parco",
		"floor_color": Color(0.47, 0.56, 0.42, 1),
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
		"floor_color": Color(0.43, 0.49, 0.39, 1),
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
		"floor_color": Color(0.46, 0.45, 0.37, 1),
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
	3: {
		"label": "Deserto",
		"floor_color": Color(0.76, 0.65, 0.42, 1),
		"wall_color": Color(0.55, 0.35, 0.20, 1),
		"sky_top_color": Color(0.45, 0.55, 0.75, 1),
		"sky_horizon_color": Color(0.85, 0.65, 0.40, 1),
		"ground_bottom_color": Color(0.10, 0.07, 0.04, 1),
		"ground_horizon_color": Color(0.55, 0.42, 0.26, 1),
		"ambient_light_color": Color(0.9, 0.75, 0.55, 1),
		"ambient_light_energy": 0.65,
		"tree_trunk_color": Color(0.40, 0.28, 0.15, 1),
		"tree_foliage_color": Color(0.55, 0.50, 0.25, 1),
		"tree_shape": "sparse",
		"enemy_colors": {
			"balordo": Color(0.65, 0.55, 0.35),
			"nervoso": Color(0.85, 0.40, 0.15),
			"imprevedibile": Color(0.55, 0.30, 0.60),
			"bruto": Color(0.45, 0.22, 0.12),
			"tiratore": Color(0.40, 0.45, 0.40),
		},
	},
	4: {
		"label": "Giungla",
		"floor_color": Color(0.40, 0.55, 0.35, 1),
		"wall_color": Color(0.20, 0.30, 0.15, 1),
		"sky_top_color": Color(0.12, 0.22, 0.15, 1),
		"sky_horizon_color": Color(0.35, 0.42, 0.30, 1),
		"ground_bottom_color": Color(0.04, 0.06, 0.04, 1),
		"ground_horizon_color": Color(0.22, 0.26, 0.18, 1),
		"ambient_light_color": Color(0.55, 0.65, 0.50, 1),
		"ambient_light_energy": 0.5,
		"tree_trunk_color": Color(0.22, 0.15, 0.08, 1),
		"tree_foliage_color": Color(0.10, 0.50, 0.20, 1),
		"tree_shape": "sphere",
		"enemy_colors": {
			"balordo": Color(0.40, 0.45, 0.25),
			"nervoso": Color(0.65, 0.35, 0.15),
			"imprevedibile": Color(0.45, 0.25, 0.55),
			"bruto": Color(0.20, 0.12, 0.08),
			"tiratore": Color(0.18, 0.32, 0.28),
		},
	},
	5: {
		"label": "Città",
		"floor_color": Color(0.50, 0.50, 0.52, 1),
		"wall_color": Color(0.40, 0.40, 0.42, 1),
		"sky_top_color": Color(0.30, 0.32, 0.38, 1),
		"sky_horizon_color": Color(0.55, 0.50, 0.45, 1),
		"ground_bottom_color": Color(0.05, 0.05, 0.06, 1),
		"ground_horizon_color": Color(0.35, 0.34, 0.32, 1),
		"ambient_light_color": Color(0.6, 0.6, 0.62, 1),
		"ambient_light_energy": 0.55,
		"tree_trunk_color": Color(0.25, 0.22, 0.20, 1),
		"tree_foliage_color": Color(0.30, 0.42, 0.25, 1),
		"tree_shape": "sparse",
		"enemy_colors": {
			"balordo": Color(0.50, 0.50, 0.52),
			"nervoso": Color(0.75, 0.35, 0.20),
			"imprevedibile": Color(0.50, 0.30, 0.65),
			"bruto": Color(0.30, 0.12, 0.12),
			"tiratore": Color(0.25, 0.35, 0.40),
		},
	},
	6: {
		"label": "Paesaggio di Caramelle",
		"floor_color": Color(0.85, 0.55, 0.70, 1),
		"wall_color": Color(0.55, 0.30, 0.60, 1),
		"sky_top_color": Color(0.50, 0.30, 0.55, 1),
		"sky_horizon_color": Color(0.95, 0.70, 0.85, 1),
		"ground_bottom_color": Color(0.15, 0.05, 0.15, 1),
		"ground_horizon_color": Color(0.5, 0.3, 0.45, 1),
		"ambient_light_color": Color(0.9, 0.75, 0.9, 1),
		"ambient_light_energy": 0.65,
		"tree_trunk_color": Color(0.5, 0.3, 0.5, 1),
		"tree_foliage_color": Color(0.95, 0.4, 0.6, 1),
		"tree_shape": "sphere",
		"enemy_colors": {
			"balordo": Color(0.70, 0.55, 0.75),
			"nervoso": Color(0.95, 0.50, 0.35),
			"imprevedibile": Color(0.65, 0.40, 0.85),
			"bruto": Color(0.55, 0.20, 0.35),
			"tiratore": Color(0.40, 0.55, 0.75),
		},
	},
}

static func scenario_count() -> int:
	return DATA.size()

# Indice di scenario corrispondente allo scenario "attivo" in questa zona:
# stesse soglie di CheckpointData.is_checkpoint_zone.
static func scenario_index_for_zone(zone: int) -> int:
	var idx: int
	if zone <= TIER1_END:
		idx = zone / TIER1_INTERVAL
	elif zone <= TIER2_END:
		idx = (TIER1_END / TIER1_INTERVAL) + (zone - TIER1_END) / TIER2_INTERVAL
	else:
		idx = (TIER1_END / TIER1_INTERVAL) + (TIER2_END - TIER1_END) / TIER2_INTERVAL + (zone - TIER2_END) / TIER3_INTERVAL
	return clampi(idx, 0, DATA.size() - 1)

# Prossimo numero di zona che è un checkpoint, dopo "zone" (usato solo per
# calcolare la finestra di transizione qui sotto — la logica dei checkpoint
# veri resta in CheckpointData).
static func _next_checkpoint_zone(zone: int) -> int:
	if zone < TIER1_END:
		return ((zone / TIER1_INTERVAL) + 1) * TIER1_INTERVAL
	elif zone < TIER2_END:
		return TIER1_END + (((zone - TIER1_END) / TIER2_INTERVAL) + 1) * TIER2_INTERVAL
	else:
		return TIER2_END + (((zone - TIER2_END) / TIER3_INTERVAL) + 1) * TIER3_INTERVAL

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
	var next_checkpoint: int = _next_checkpoint_zone(zone)
	var start_zone: int = next_checkpoint - TRANSITION_WINDOW
	var end_zone: int = next_checkpoint - 1
	if zone < start_zone or zone > end_zone:
		return 0.0
	var t: float = float(zone - start_zone) / float(TRANSITION_WINDOW - 1)
	return TRANSITION_MAX_PROGRESS * t * t
