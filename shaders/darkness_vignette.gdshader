shader_type canvas_item;

// Buio della tempesta: un cerchio pieno di luce centrato sulla CASA (non sul
// player, che invece resta sempre al centro schermo grazie alla telecamera)
// che si restringe nei 30s della tempesta fino a chiudersi (vedi
// main.gd:_update_house_vignette, aggiorna house_center_px/
// house_visible_radius ogni frame proiettando la casa e un punto sul vero
// bordo del cerchio con la telecamera attiva). Il player ha comunque sempre
// un piccolo raggio minimo visibile attorno a sé (player_visible_radius,
// centro schermo fisso), anche a cerchio della casa già chiuso del tutto:
// una zona è visibile se rientra in ALMENO uno dei due cerchi.
//
// viewport_size arriva da hud.gd (get_viewport().get_visible_rect()) invece
// di SCREEN_PIXEL_SIZE: stessa fonte di verità di tutta l'interfaccia,
// evita discrepanze con la modalità di stretch del progetto. Le distanze
// sono normalizzate sulla dimensione più piccola dello schermo, così i
// cerchi restano veri cerchi (non ellissi) a qualunque proporzione.

uniform vec2 viewport_size = vec2(1280.0, 720.0);
uniform vec2 house_center_px = vec2(640.0, 360.0);
uniform float house_visible_radius : hint_range(0.0, 4.0) = 2.0;
uniform float player_visible_radius : hint_range(0.0, 1.0) = 0.56;
uniform float edge_softness : hint_range(0.0, 0.5) = 0.05;

void fragment() {
	vec2 pixel_pos = UV * viewport_size;
	float min_dim = min(viewport_size.x, viewport_size.y);
	float half_dim = min_dim * 0.5;

	vec2 screen_center = viewport_size * 0.5;
	float dist_player = length(pixel_pos - screen_center) / half_dim;
	float dist_house = length(pixel_pos - house_center_px) / half_dim;

	float alpha_house = smoothstep(house_visible_radius, house_visible_radius + edge_softness, dist_house);
	float alpha_player = smoothstep(player_visible_radius, player_visible_radius + edge_softness, dist_player);

	float alpha = min(alpha_house, alpha_player);
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
