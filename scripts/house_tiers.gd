class_name HouseTiers
extends RefCounted

# Ordine progressivo dei tier di abitazione. Ogni tier ha uno spazio interno
# (griglia banchi cols x rows, una cella = 2 unità di mondo, stesso schema
# della tenda originale) via via più grande e un aspetto esterno diverso.
const TIER_ORDER := [
	"tenda", "capanna", "container", "casetta", "casa", "casa_due_piani",
	"villetta", "villa", "fortezza", "bunker", "castello",
]

const TIERS := {
	"tenda": {
		"label": "Tenda", "cols": 2, "rows": 3,
		"cost_money": 0, "cost_material": "", "cost_amount": 0, "zone_required": 1,
		"wall_color": Color(0.62, 0.52, 0.36, 1), "accent_color": Color(0.45, 0.38, 0.26, 1),
		"floors": 1, "towers": 0, "moat": false, "underground": false,
	},
	"capanna": {
		"label": "Capanna", "cols": 3, "rows": 3,
		"cost_money": 300, "cost_material": "legno", "cost_amount": 40, "zone_required": 4,
		"wall_color": Color(0.42, 0.3, 0.16, 1), "accent_color": Color(0.24, 0.4, 0.18, 1),
		"floors": 1, "towers": 0, "moat": false, "underground": false,
	},
	"container": {
		"label": "Container", "cols": 2, "rows": 6,
		"cost_money": 700, "cost_material": "metallo", "cost_amount": 70, "zone_required": 7,
		"wall_color": Color(0.55, 0.58, 0.6, 1), "accent_color": Color(0.75, 0.62, 0.15, 1),
		"floors": 1, "towers": 0, "moat": false, "underground": false,
	},
	"casetta": {
		"label": "Casetta", "cols": 4, "rows": 4,
		"cost_money": 1400, "cost_material": "metallo", "cost_amount": 110, "zone_required": 10,
		"wall_color": Color(0.85, 0.8, 0.7, 1), "accent_color": Color(0.55, 0.3, 0.22, 1),
		"floors": 1, "towers": 0, "moat": false, "underground": false,
	},
	"casa": {
		"label": "Casa", "cols": 4, "rows": 5,
		"cost_money": 2500, "cost_material": "metallo", "cost_amount": 160, "zone_required": 14,
		"wall_color": Color(0.7, 0.35, 0.28, 1), "accent_color": Color(0.9, 0.88, 0.82, 1),
		"floors": 1, "towers": 0, "moat": false, "underground": false,
	},
	"casa_due_piani": {
		"label": "Casa a due piani", "cols": 4, "rows": 6,
		"cost_money": 4000, "cost_material": "metallo", "cost_amount": 220, "zone_required": 18,
		"wall_color": Color(0.72, 0.4, 0.3, 1), "accent_color": Color(0.9, 0.88, 0.82, 1),
		"floors": 2, "towers": 0, "moat": false, "underground": false,
	},
	"villetta": {
		"label": "Villetta", "cols": 5, "rows": 6,
		"cost_money": 6000, "cost_material": "metallo", "cost_amount": 300, "zone_required": 23,
		"wall_color": Color(0.88, 0.84, 0.72, 1), "accent_color": Color(0.5, 0.42, 0.3, 1),
		"floors": 2, "towers": 0, "moat": false, "underground": false,
	},
	"villa": {
		"label": "Villa", "cols": 5, "rows": 7,
		"cost_money": 9000, "cost_material": "metallo", "cost_amount": 400, "zone_required": 28,
		"wall_color": Color(0.92, 0.9, 0.84, 1), "accent_color": Color(0.8, 0.7, 0.4, 1),
		"floors": 1, "towers": 0, "moat": false, "underground": false,
	},
	"fortezza": {
		"label": "Fortezza", "cols": 6, "rows": 7,
		"cost_money": 13000, "cost_material": "metallo", "cost_amount": 520, "zone_required": 34,
		"wall_color": Color(0.4, 0.4, 0.42, 1), "accent_color": Color(0.25, 0.25, 0.27, 1),
		"floors": 2, "towers": 4, "moat": false, "underground": false,
	},
	"bunker": {
		"label": "Bunker", "cols": 6, "rows": 8,
		"cost_money": 18000, "cost_material": "metallo", "cost_amount": 650, "zone_required": 40,
		"wall_color": Color(0.5, 0.5, 0.48, 1), "accent_color": Color(0.3, 0.32, 0.3, 1),
		"floors": 1, "towers": 0, "moat": false, "underground": true,
	},
	"castello": {
		"label": "Castello", "cols": 7, "rows": 8,
		"cost_money": 25000, "cost_material": "metallo", "cost_amount": 800, "zone_required": 47,
		"wall_color": Color(0.78, 0.76, 0.7, 1), "accent_color": Color(0.55, 0.5, 0.42, 1),
		"floors": 2, "towers": 4, "moat": true, "underground": false,
	},
}

static func tier_id(index: int) -> String:
	var i: int = clampi(index, 0, TIER_ORDER.size() - 1)
	return TIER_ORDER[i]

static func tier_data(index: int) -> Dictionary:
	return TIERS[tier_id(index)]

static func next_tier_index(index: int) -> int:
	return clampi(index + 1, 0, TIER_ORDER.size() - 1)

static func is_max_tier(index: int) -> bool:
	return index >= TIER_ORDER.size() - 1

static func col_values(index: int) -> Array:
	var cols: int = int(tier_data(index).cols)
	var values := []
	for c in range(cols):
		values.append((c - (cols - 1) / 2.0) * 2.0)
	return values

static func row_values(index: int) -> Array:
	var rows: int = int(tier_data(index).rows)
	var values := []
	for r in range(rows):
		values.append((r - (rows - 1) / 2.0) * 2.0)
	return values
