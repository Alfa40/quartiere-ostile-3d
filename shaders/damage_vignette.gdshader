shader_type canvas_item;

// Vignetta rossa concentrata sui bordi dello schermo, sfumata verso il
// centro (che resta sempre completamente libero per la visuale). Segue il
// bordo rettangolare dello schermo (distanza di Chebyshev) invece di un
// cerchio, così copre in modo uniforme tutti e quattro i lati a qualunque
// proporzione schermo.

uniform vec4 vignette_color : source_color = vec4(1.0, 0.05, 0.05, 0.85);
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float edge_start : hint_range(0.0, 1.0) = 0.25;

void fragment() {
	vec2 centered = (UV - vec2(0.5)) * 2.0;
	float dist = max(abs(centered.x), abs(centered.y));
	float edge = smoothstep(edge_start, 1.0, dist);
	COLOR = vec4(vignette_color.rgb, vignette_color.a * edge * intensity);
}
