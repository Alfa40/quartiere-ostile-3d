shader_type canvas_item;

// Buio quasi totale nel campo: resta visibile solo un piccolo cerchio
// attorno al centro dello schermo (dove sta sempre il player, la telecamera
// lo segue). A schermo intero (non nel mondo 3D) perché la telecamera è in
// terza persona, scostata di parecchi metri dal player: un effetto nel
// mondo centrato sul player lascerebbe la telecamera stessa fuori dalla
// bolla, rendendo visibile tutto il resto (vedi main.gd, _update_darkness).

uniform float visible_radius : hint_range(0.0, 1.0) = 0.15;
uniform float edge_softness : hint_range(0.0, 0.5) = 0.05;

void fragment() {
	vec2 centered = (UV - vec2(0.5)) * 2.0;
	float dist = length(centered);
	float alpha = smoothstep(visible_radius, visible_radius + edge_softness, dist);
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
