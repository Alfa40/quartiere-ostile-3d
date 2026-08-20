class_name EnemyArchetypes
extends RefCounted

const DATA := {
	"balordo": {
		"radius_mult": 1.12, "speed_mult": 0.72, "hp_mult": 1.25, "damage_mult": 1.0,
		"cooldown_mult": 1.0, "behavior": "steady", "min_zone": 1,
		"color": Color(0.54, 0.45, 0.33),
	},
	"nervoso": {
		"radius_mult": 0.9, "speed_mult": 1.4, "hp_mult": 0.8, "damage_mult": 1.05,
		"cooldown_mult": 0.7, "behavior": "aggressive", "min_zone": 1,
		"color": Color(0.88, 0.44, 0.24),
	},
	"imprevedibile": {
		"radius_mult": 1.0, "speed_mult": 1.1, "hp_mult": 0.9, "damage_mult": 1.0,
		"cooldown_mult": 0.85, "behavior": "erratic", "min_zone": 3,
		"color": Color(0.61, 0.35, 0.82),
	},
	"bruto": {
		"radius_mult": 1.5, "speed_mult": 0.42, "hp_mult": 1.6, "damage_mult": 2.3,
		"cooldown_mult": 1.3, "behavior": "steady", "min_zone": 4,
		"color": Color(0.36, 0.15, 0.15),
	},
	"tiratore": {
		"radius_mult": 0.85, "speed_mult": 0.85, "hp_mult": 0.55, "damage_mult": 0.8,
		"cooldown_mult": 1.0, "behavior": "ranged", "min_zone": 5,
		"color": Color(0.29, 0.42, 0.48),
	},
}

static func weight(id: String, zone: int) -> float:
	match id:
		"balordo":
			return max(0.15, 1.4 - zone * 0.12)
		"nervoso":
			return 0.4 + zone * 0.1
		"imprevedibile":
			return 0.0 if zone < 3 else 0.25 + (zone - 3) * 0.15
		"bruto":
			return 0.0 if zone < 4 else 0.18 + (zone - 4) * 0.05
		"tiratore":
			return 0.0 if zone < 5 else 0.15 + (zone - 5) * 0.07
	return 0.0

static func pick(zone: int) -> String:
	var candidates: Array = []
	for id in DATA:
		if zone >= DATA[id].min_zone:
			candidates.append(id)
	if candidates.is_empty():
		return "balordo"
	var total := 0.0
	for id in candidates:
		total += weight(id, zone)
	var roll := randf() * total
	for id in candidates:
		roll -= weight(id, zone)
		if roll <= 0.0:
			return id
	return candidates[candidates.size() - 1]
