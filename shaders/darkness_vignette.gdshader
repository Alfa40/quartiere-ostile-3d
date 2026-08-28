shader_type canvas_item;

// Buio quasi totale nel campo: resta visibile solo un cerchio attorno al
// centro dello schermo (dove sta sempre il player, la telecamera lo segue).
// A schermo intero (non nel mondo 3D) perché la telecamera è in terza
// persona, scostata di parecchi metri dal player: un effetto nel mondo
// centrato sul player lascerebbe la telecamera stessa fuori dalla bolla,
// rendendo visibile tutto il resto (vedi main.gd, _update_darkness).
//
// viewport_size viene passato da hud.gd (get_viewport().get_visible_rect())
// invece di usare SCREEN_PIXEL_SIZE: stessa fonte di verità già usata da
// tutto il resto dell'interfaccia per orientamento/scala, per evitare
// discrepanze con la modalità di stretch del progetto. La distanza è
// normalizzata sulla dimensione più piccola, così il cerchio resta un vero
// cerchio (non un'ellisse) a qualunque proporzione di schermo.

uniform vec2 viewport_size = vec2(1280.0, 720.0);
uniform float visible_radius : hint_range(0.0, 1.0) = 0.60;
uniform float edge_softness : hint_range(0.0, 0.5) = 0.05;

void fragment() {
	vec2 pixel_pos = UV * viewport_size;
	vec2 center = viewport_size * 0.5;
	float min_dim = min(viewport_size.x, viewport_size.y);
	float dist = length(pixel_pos - center) / (min_dim * 0.5);
	float alpha = smoothstep(visible_radius, visible_radius + edge_softness, dist);
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
