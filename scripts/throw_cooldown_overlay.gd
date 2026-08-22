extends Control

# Spicchio scuro che copre la parte di ricarica ancora mancante del tasto a
# cui è agganciato, come un grafico a torta che si riempie in senso orario.
var frac_remaining := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if frac_remaining <= 0.001:
		return
	var center: Vector2 = size * 0.5
	var radius: float = min(size.x, size.y) * 0.5
	var start_angle := -PI / 2.0
	var sweep: float = TAU * clamp(frac_remaining, 0.0, 1.0)
	var segments := 32
	var points := PackedVector2Array()
	points.append(center)
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var a: float = start_angle + sweep * t
		points.append(center + Vector2(cos(a), sin(a)) * radius)
	draw_polygon(points, PackedColorArray([Color(0.05, 0.05, 0.08, 0.6)]))
