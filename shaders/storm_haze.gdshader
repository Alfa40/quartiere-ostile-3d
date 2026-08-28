shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_opaque;

// Foschia nera della tempesta: non dev'essere un "muro" (superficie piatta,
// bordi netti, colore uniforme), ma una nebbia densa che si nota per il suo
// aspetto irregolare e mobile. UV.x gira intorno alla circonferenza, UV.y
// va dal basso all'alto del cilindro (mappatura standard di CylinderMesh):
// un rumore procedurale che scorre lentamente su entrambe rompe la
// superficie in banchi di foschia, e una dissolvenza morbida in alto/basso
// evita il taglio netto che farebbe leggere la mesh come un muro.

uniform vec4 haze_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float base_alpha : hint_range(0.0, 1.0) = 0.97;
uniform float scroll_speed : hint_range(0.0, 1.0) = 0.08;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
	vec2 base_uv = vec2(UV.x * 8.0, UV.y * 3.0);
	vec2 drift = vec2(TIME * scroll_speed, TIME * scroll_speed * 0.35);
	float n = noise(base_uv + drift) * 0.6 + noise(base_uv * 2.3 - drift * 1.7) * 0.4;
	float height_fade = smoothstep(0.0, 0.25, UV.y) * smoothstep(1.0, 0.75, UV.y);
	ALBEDO = haze_color.rgb;
	ALPHA = base_alpha * height_fade * (0.5 + 0.5 * n);
}
