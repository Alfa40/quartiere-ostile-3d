class_name HouseTiers
extends RefCounted

# Ordine progressivo dei tier di abitazione. Ogni tier ha uno o più piani,
# ognuno con una griglia banchi cols x rows (una cella = 2 unità di mondo,
# stesso schema della tenda originale), via via più grandi, collegati da
# scale interne quando un tier ha più di un piano.
const TIER_ORDER := [
	"tenda", "capanna", "container", "casetta", "casa", "casa_due_piani",
	"villetta", "villa", "fortezza", "bunker", "castello",
]

const TIERS := {
	"tenda": {
		"label": "Tenda", "floors": [{"cols": 2, "rows": 3}], "shape": "tent",
		"cost_money": 0, "cost_material": "", "cost_amount": 0,
		"wall_color": Color(0.62, 0.52, 0.36, 1), "accent_color": Color(0.45, 0.38, 0.26, 1),
		"towers": 0, "moat": false, "underground": false,
	},
	"capanna": {
		"label": "Capanna", "floors": [{"cols": 3, "rows": 3}], "shape": "tent",
		"cost_money": 300, "cost_material": "legno", "cost_amount": 40,
		"wall_color": Color(0.42, 0.3, 0.16, 1), "accent_color": Color(0.24, 0.4, 0.18, 1),
		"towers": 0, "moat": false, "underground": false,
	},
	"container": {
		"label": "Container", "floors": [{"cols": 2, "rows": 6}], "shape": "box",
		"cost_money": 700, "cost_material": "metallo", "cost_amount": 70,
		"wall_color": Color(0.55, 0.58, 0.6, 1), "accent_color": Color(0.75, 0.62, 0.15, 1),
		"towers": 0, "moat": false, "underground": false,
	},
	"casetta": {
		"label": "Casetta", "floors": [{"cols": 4, "rows": 4}], "shape": "box",
		"cost_money": 1400, "cost_material": "metallo", "cost_amount": 110,
		"wall_color": Color(0.85, 0.8, 0.7, 1), "accent_color": Color(0.55, 0.3, 0.22, 1),
		"roof_color": Color(0.55, 0.27, 0.2, 1),
		"towers": 0, "moat": false, "underground": false,
	},
	"casa": {
		"label": "Casa", "floors": [{"cols": 4, "rows": 5}], "shape": "box",
		"cost_money": 2500, "cost_material": "metallo", "cost_amount": 160,
		"wall_color": Color(0.7, 0.35, 0.28, 1), "accent_color": Color(0.9, 0.88, 0.82, 1),
		"roof_color": Color(0.48, 0.24, 0.18, 1),
		"towers": 0, "moat": false, "underground": false,
	},
	"casa_due_piani": {
		"label": "Casa a due piani", "floors": [{"cols": 3, "rows": 4}, {"cols": 3, "rows": 4}], "shape": "box",
		"cost_money": 4000, "cost_material": "metallo", "cost_amount": 220,
		"wall_color": Color(0.72, 0.4, 0.3, 1), "accent_color": Color(0.9, 0.88, 0.82, 1),
		"roof_color": Color(0.48, 0.24, 0.18, 1),
		"towers": 0, "moat": false, "underground": false,
	},
	"villetta": {
		"label": "Villetta", "floors": [{"cols": 3, "rows": 6}, {"cols": 3, "rows": 4}], "shape": "box",
		"cost_money": 6000, "cost_material": "metallo", "cost_amount": 300,
		"wall_color": Color(0.88, 0.84, 0.72, 1), "accent_color": Color(0.5, 0.42, 0.3, 1),
		"roof_color": Color(0.32, 0.28, 0.26, 1),
		"towers": 0, "moat": false, "underground": false,
	},
	"villa": {
		"label": "Villa", "floors": [{"cols": 5, "rows": 7}], "shape": "box",
		"cost_money": 9000, "cost_material": "metallo", "cost_amount": 400,
		"wall_color": Color(0.92, 0.9, 0.84, 1), "accent_color": Color(0.8, 0.7, 0.4, 1),
		"roof_color": Color(0.35, 0.3, 0.27, 1),
		"towers": 0, "moat": false, "underground": false,
	},
	"fortezza": {
		"label": "Fortezza", "floors": [{"cols": 4, "rows": 5}, {"cols": 4, "rows": 5}], "shape": "box",
		"cost_money": 13000, "cost_material": "metallo", "cost_amount": 520,
		"wall_color": Color(0.4, 0.4, 0.42, 1), "accent_color": Color(0.25, 0.25, 0.27, 1),
		"towers": 4, "moat": false, "underground": false,
	},
	"bunker": {
		"label": "Bunker", "floors": [
			{"cols": 3, "rows": 3}, {"cols": 4, "rows": 3}, {"cols": 4, "rows": 3}, {"cols": 4, "rows": 3},
		], "shape": "box",
		"cost_money": 18000, "cost_material": "metallo", "cost_amount": 650,
		"wall_color": Color(0.5, 0.5, 0.48, 1), "accent_color": Color(0.3, 0.32, 0.3, 1),
		"towers": 0, "moat": false, "underground": true,
	},
	"castello": {
		"label": "Castello", "floors": [{"cols": 5, "rows": 5}, {"cols": 5, "rows": 5}], "shape": "box",
		"cost_money": 25000, "cost_material": "metallo", "cost_amount": 800,
		"wall_color": Color(0.78, 0.76, 0.7, 1), "accent_color": Color(0.55, 0.5, 0.42, 1),
		"towers": 4, "moat": true, "underground": false,
	},
}

const FLOOR_HEIGHT := 2.7

static func tier_id(index: int) -> String:
	var i: int = clampi(index, 0, TIER_ORDER.size() - 1)
	return TIER_ORDER[i]

static func tier_data(index: int) -> Dictionary:
	return TIERS[tier_id(index)]

static func next_tier_index(index: int) -> int:
	return clampi(index + 1, 0, TIER_ORDER.size() - 1)

static func is_max_tier(index: int) -> bool:
	return index >= TIER_ORDER.size() - 1

static func own_floors(index: int) -> Array:
	return TIERS[tier_id(index)].floors

static func floor_count(index: int) -> int:
	return own_floors(index).size()

static func floor_data(index: int, floor_idx: int) -> Dictionary:
	var floors := own_floors(index)
	var f: int = clampi(floor_idx, 0, floors.size() - 1)
	return floors[f]

# Il bunker ha i piani sotto terra invece che sopra (solo l'ingresso 3x3 resta
# in superficie): tutti gli altri tier con più piani impilano verso l'alto.
static func floor_y(index: int, floor_idx: int) -> float:
	if bool(tier_data(index).underground) and floor_idx > 0:
		return -float(floor_idx) * FLOOR_HEIGHT
	return float(floor_idx) * FLOOR_HEIGHT

static func col_values(index: int, floor_idx: int) -> Array:
	var cols: int = int(floor_data(index, floor_idx).cols)
	var values := []
	for c in range(cols):
		values.append((c - (cols - 1) / 2.0) * 2.0)
	return values

static func row_values(index: int, floor_idx: int) -> Array:
	var rows: int = int(floor_data(index, floor_idx).rows)
	var values := []
	for r in range(rows):
		values.append((r - (rows - 1) / 2.0) * 2.0)
	return values

static func describe_space(index: int) -> String:
	var floors := own_floors(index)
	if floors.size() == 1:
		return "spazio %dx%d" % [int(floors[0].cols), int(floors[0].rows)]
	var parts := []
	for f in range(floors.size()):
		var name := "piano terra" if f == 0 else ("piano %d" % f)
		parts.append("%s %dx%d" % [name, int(floors[f].cols), int(floors[f].rows)])
	return "%d piani (%s)" % [floors.size(), ", ".join(parts)]
