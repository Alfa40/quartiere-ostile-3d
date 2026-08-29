shader_type canvas_item;

// Buio della tempesta: un cerchio pieno di luce centrato sulla CASA (raggio
// in unità di mondo reali, non uno pseudo-cerchio a schermo approssimato)
// che si restringe nei 30s della tempesta fino a chiudersi (vedi
// main.gd:_update_house_vignette). Per ogni pixel ricostruiamo a quale
// punto del terreno corrisponde intersecando il raggio telecamera-pixel col
// piano orizzontale all'altezza della casa, poi confrontiamo la vera
// distanza orizzontale dalla casa con visible_radius — lo stesso identico
// criterio usato dalla meccanica di gioco (_horizontal_distance_to_house),
// non un'approssimazione 2D: garantisce che il confine visibile coincida
// sempre con quello reale, qualunque sia la posizione o distanza del player
// dalla casa.
//
// I quattro raggi (uno per angolo dello schermo, calcolati in GDScript con
// Camera3D.project_ray_normal) bastano perché per una proiezione
// prospettica la direzione del raggio varia linearmente con la posizione a
// schermo: qui li interpoliamo bilinearmente per ottenere la direzione
// esatta di ogni pixel, senza passare matrici di camera/proiezione.
//
// Il player ha comunque sempre un piccolo raggio minimo visibile attorno a
// sé (player_visible_radius, centro schermo fisso — la telecamera lo segue
// sempre lì), anche a cerchio della casa già chiuso del tutto: un pixel è
// visibile se rientra in ALMENO uno dei due criteri.

uniform vec2 viewport_size = vec2(1280.0, 720.0);
uniform vec3 cam_origin = vec3(0.0, 0.0, 0.0);
uniform vec3 ray_tl = vec3(0.0, 0.0, -1.0);
uniform vec3 ray_tr = vec3(0.0, 0.0, -1.0);
uniform vec3 ray_bl = vec3(0.0, 0.0, -1.0);
uniform vec3 ray_br = vec3(0.0, 0.0, -1.0);
uniform vec2 house_xz = vec2(0.0, 0.0);
uniform float ground_y = 0.0;
uniform float visible_radius = 65.0;
uniform float edge_softness_world : hint_range(0.0, 10.0) = 1.5;
uniform float player_visible_radius : hint_range(0.0, 1.0) = 0.56;
uniform float edge_softness : hint_range(0.0, 0.5) = 0.05;

void fragment() {
	vec3 ray_top = mix(ray_tl, ray_tr, UV.x);
	vec3 ray_bottom = mix(ray_bl, ray_br, UV.x);
	vec3 ray_dir = normalize(mix(ray_top, ray_bottom, UV.y));

	float dist_house;
	float denom = ray_dir.y;
	float t = (ground_y - cam_origin.y) / denom;
	if (abs(denom) < 0.0001 || t < 0.0) {
		dist_house = 999999.0;
	} else {
		vec3 world_pos = cam_origin + ray_dir * t;
		dist_house = length(world_pos.xz - house_xz);
	}
	float alpha_house = smoothstep(visible_radius, visible_radius + edge_softness_world, dist_house);

	vec2 pixel_pos = UV * viewport_size;
	vec2 screen_center = viewport_size * 0.5;
	float min_dim = min(viewport_size.x, viewport_size.y);
	float dist_player = length(pixel_pos - screen_center) / (min_dim * 0.5);
	float alpha_player = smoothstep(player_visible_radius, player_visible_radius + edge_softness, dist_player);

	float alpha = min(alpha_house, alpha_player);
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
