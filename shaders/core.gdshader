shader_type spatial;
// Unshaded toon planet core.
//  - Hard-banded body color (bright center -> dark rim, view based).
//  - Optional slow "swirl" noise that wobbles the band borders.
//  - Progressive cracks: Voronoi cell edges, revealed one by one as
//    crack_amount goes 0 -> 1 (each edge has its own random threshold).
//  - Dimming: brightness / desaturation / tint to sit in the game's palette.
render_mode unshaded, cull_back, shadows_disabled;

// ---- Body (toon bands, center -> rim) ----
uniform vec3 color_center : source_color = vec3(1.0, 0.78, 0.35);
uniform vec3 color_mid : source_color = vec3(0.95, 0.42, 0.12);
uniform vec3 color_rim : source_color = vec3(0.55, 0.12, 0.08);
// Band borders in "facing" space (1 = facing camera, 0 = silhouette).
uniform float band_mid : hint_range(0.0, 1.0) = 0.45;
uniform float band_center : hint_range(0.0, 1.0) = 0.8;
// 0 = hard toon edges, small values soften them slightly (anti-alias).
uniform float band_softness : hint_range(0.0, 0.1) = 0.01;

// ---- Swirl (wobbles band borders, animated) ----
uniform float swirl_strength : hint_range(0.0, 0.5) = 0.12;
uniform float swirl_scale = 2.5;
uniform float swirl_speed = 0.15;

// ---- Cracks ----
// 0 = no cracks, 1 = every cell edge cracked.
uniform float crack_amount : hint_range(0.0, 1.0) = 0.0;
uniform float crack_scale = 3.0;       // cells per unit (object space)
uniform float crack_width : hint_range(0.0, 0.3) = 0.06;
uniform vec3 crack_color : source_color = vec3(1.0, 0.95, 0.7);
// > 1 pushes cracks into HDR so they bloom with WorldEnvironment glow.
uniform float crack_intensity = 2.0;
uniform float crack_pulse_speed = 2.0;
uniform float crack_pulse_amount : hint_range(0.0, 1.0) = 0.25;
uniform float crack_seed = 0.0;
// Dark lip on both sides of a crack, reads well in toon style.
uniform float crack_edge_width : hint_range(0.0, 0.3) = 0.04;
uniform vec3 crack_edge_color : source_color = vec3(0.12, 0.03, 0.03);

// ---- Dimming / game alignment ----
uniform float brightness : hint_range(0.0, 2.0) = 0.6;
uniform float desaturate : hint_range(0.0, 1.0) = 0.2;
uniform vec3 tint : source_color = vec3(1.0);
// Whether dimming also applies to cracks (off = cracks stay bright).
uniform bool dim_cracks = false;

varying vec3 obj_pos;

vec3 hash33(vec3 p) {
	p = vec3(dot(p, vec3(127.1, 311.7, 74.7)),
			dot(p, vec3(269.5, 183.3, 246.1)),
			dot(p, vec3(113.5, 271.9, 124.6)));
	return fract(sin(p + crack_seed) * 43758.5453);
}

float hash13(vec3 p) {
	return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719)) + crack_seed) * 43758.5453);
}

float value_noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash13(i);
	float n100 = hash13(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash13(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash13(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash13(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash13(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash13(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash13(i + vec3(1.0, 1.0, 1.0));
	return mix(mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),
			mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y), f.z);
}

// Distance to the nearest Voronoi edge + ids of the two cells sharing it.
// Uses the proper bisector distance (not F2-F1) so width is uniform.
void voronoi_edge(vec3 p, out float edge_dist, out vec3 cell_a, out vec3 cell_b) {
	vec3 ip = floor(p);
	vec3 fp = fract(p);

	vec3 mr = vec3(0.0);
	vec3 mg = vec3(0.0);
	float md = 1e9;
	for (int z = -1; z <= 1; z++) {
	for (int y = -1; y <= 1; y++) {
	for (int x = -1; x <= 1; x++) {
		vec3 g = vec3(float(x), float(y), float(z));
		vec3 r = g + hash33(ip + g) - fp;
		float d = dot(r, r);
		if (d < md) { md = d; mr = r; mg = g; }
	}}}

	edge_dist = 1e9;
	vec3 other = mg;
	for (int z = -2; z <= 2; z++) {
	for (int y = -2; y <= 2; y++) {
	for (int x = -2; x <= 2; x++) {
		vec3 g = mg + vec3(float(x), float(y), float(z));
		vec3 r = g + hash33(ip + g) - fp;
		vec3 diff = r - mr;
		if (dot(diff, diff) > 1e-5) {
			float d = dot(0.5 * (mr + r), normalize(diff));
			if (d < edge_dist) { edge_dist = d; other = g; }
		}
	}}}
	cell_a = ip + mg;
	cell_b = ip + other;
}

vec3 dim_color(vec3 c) {
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, vec3(l), desaturate);
	return c * tint * brightness;
}

void vertex() {
	obj_pos = VERTEX;
}

void fragment() {
	// --- Toon body ---
	float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float swirl = value_noise(obj_pos * swirl_scale + vec3(0.0, TIME * swirl_speed, 0.0)) - 0.5;
	facing += swirl * swirl_strength;

	float s = max(band_softness, 1e-4);
	vec3 body = color_rim;
	body = mix(body, color_mid, smoothstep(band_mid - s, band_mid + s, facing));
	body = mix(body, color_center, smoothstep(band_center - s, band_center + s, facing));
	body = dim_color(body);

	vec3 col = body;

	// --- Cracks ---
	if (crack_amount > 0.0) {
		float edge;
		vec3 ca;
		vec3 cb;
		voronoi_edge(obj_pos * crack_scale, edge, ca, cb);

		// Same id for both sides of an edge -> stable per-edge threshold.
		float edge_id = hash13(min(ca, cb) * 1.7 + max(ca, cb) * 3.1);
		// Edges ramp in width as crack_amount passes their threshold.
		float grow = clamp((crack_amount - edge_id) * 8.0, 0.0, 1.0);

		float w = crack_width * grow;
		float lip = (crack_width + crack_edge_width) * grow;
		float aa = fwidth(edge);

		float lip_mask = 1.0 - smoothstep(lip - aa, lip + aa, edge);
		float crack_mask = 1.0 - smoothstep(w - aa, w + aa, edge);

		float pulse = 1.0 - crack_pulse_amount * (0.5 + 0.5 * sin(TIME * crack_pulse_speed + edge_id * 6.2831));
		vec3 glow = crack_color * crack_intensity * pulse;
		vec3 lip_col = crack_edge_color;
		if (dim_cracks) {
			glow = dim_color(glow);
			lip_col = dim_color(lip_col);
		}

		col = mix(col, lip_col, lip_mask * step(1e-4, grow));
		col = mix(col, glow, crack_mask * step(1e-4, grow));
	}

	ALBEDO = col;
}
