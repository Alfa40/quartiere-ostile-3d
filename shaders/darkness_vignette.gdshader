shader_type canvas_item;

// Buio quasi totale nel campo: resta visibile solo un cerchio attorno al
// centro dello schermo (dove sta sempre il player, la telecamera lo segue).
// A schermo intero (non nel mondo 3D) perché la telecamera è in terza
// persona, scostata di parecchi metri dal player: un effetto nel mondo
// centrato sul player lascerebbe la telecamera stessa fuori dalla bolla,
// rendendo visibile tutto il resto (vedi main.gd, _update_darkness).
//
// La distanza è normalizzata sulla dimensione più piccola dello schermo
// (non su UV grezze, che sarebbero deformate dalla proporzione dello
// schermo): così il cerchio resta sempre un vero cerchio, mai un'ellisse,
// qualunque sia l'aspect ratio.

uniform float visible_radius : hint_range(0.0, 1.0) = 0.30;
uniform float edge_softness : hint_range(0.0, 0.5) = 0.05;

void fragment() {
	vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 pixel_pos = UV * screen_size;
	vec2 center = screen_size * 0.5;
	float min_dim = min(screen_size.x, screen_size.y);
	float dist = length(pixel_pos - center) / (min_dim * 0.5);
	float alpha = smoothstep(visible_radius, visible_radius + edge_softness, dist);
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
