shader_type spatial;
render_mode depth_draw_opaque, cull_back;

// Toon water for Godot 4.x. Works in Compatibility, Mobile and Forward+.
// Apply to a subdivided PlaneMesh (e.g. 100x100 subdivisions) via ShaderMaterial.
// No textures required.

group_uniforms colors;
uniform vec4 shallow_color : source_color = vec4(0.30, 0.85, 0.85, 1.0);
uniform vec4 deep_color : source_color = vec4(0.04, 0.22, 0.55, 1.0);
uniform float depth_max : hint_range(0.5, 20.0) = 4.0;
uniform int color_steps : hint_range(2, 8) = 3;
uniform float alpha_shallow : hint_range(0.0, 1.0) = 0.55;
uniform float alpha_deep : hint_range(0.0, 1.0) = 0.92;

group_uniforms waves;
uniform vec2 wave_direction = vec2(1.0, 0.4);
uniform float wave_height : hint_range(0.0, 1.0) = 0.12;
uniform float wave_frequency : hint_range(0.1, 5.0) = 0.8;
uniform float wave_speed : hint_range(0.0, 5.0) = 1.0;

group_uniforms foam;
uniform bool enable_shore_foam = true;
uniform bool enable_crest_foam = true;
uniform vec4 foam_color : source_color = vec4(1.0);
uniform float shore_foam_distance : hint_range(0.0, 3.0) = 0.3;
uniform float shore_foam_noise : hint_range(0.0, 1.0) = 0.2;
uniform float crest_foam_threshold : hint_range(0.0, 2.0) = 1.05;
uniform float foam_scale : hint_range(0.1, 10.0) = 2.0;
uniform float foam_speed : hint_range(0.0, 2.0) = 0.25;

group_uniforms surface_lines;
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float line_strength : hint_range(0.0, 1.0) = 0.25;
uniform float line_width : hint_range(0.0, 0.5) = 0.06;
uniform float line_scale : hint_range(0.1, 10.0) = 1.2;
uniform float line_speed : hint_range(0.0, 2.0) = 0.3;

group_uniforms lighting;
uniform float fresnel_power : hint_range(0.5, 8.0) = 4.0;
uniform float fresnel_threshold : hint_range(0.0, 1.0) = 0.6;
uniform float fresnel_amount : hint_range(0.0, 1.0) = 0.35;
uniform vec4 fresnel_color : source_color = vec4(0.75, 0.95, 1.0, 1.0);
uniform float specular_shininess : hint_range(4.0, 512.0) = 200.0;
uniform float specular_threshold : hint_range(0.0, 1.0) = 0.7;
uniform float specular_strength : hint_range(0.0, 2.0) = 0.6;
uniform int light_bands : hint_range(1, 6) = 2;
uniform float shadow_floor : hint_range(0.0, 1.0) = 0.6;

group_uniforms advanced;
// ON for Compatibility renderer (OpenGL depth -1..1). Turn OFF for Forward+/Mobile.
uniform bool compatibility_depth = true;

uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

varying float v_height;
varying vec3 v_world;

vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453);
}

// returns (distance to nearest cell, distance to cell edge)
vec2 voronoi(vec2 uv, float anim) {
	vec2 i = floor(uv);
	vec2 f = fract(uv);
	float d1 = 8.0;
	float d2 = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = hash2(i + g);
			o = 0.5 + 0.5 * sin(anim + 6.2831 * o);
			vec2 r = g + o - f;
			float d = dot(r, r);
			if (d < d1) {
				d2 = d1;
				d1 = d;
			} else if (d < d2) {
				d2 = d;
			}
		}
	}
	return vec2(sqrt(d1), sqrt(d2) - sqrt(d1));
}

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = TIME * wave_speed;

	vec2 d1 = normalize(wave_direction);
	vec2 d2 = vec2(-d1.y, d1.x);
	vec2 d3 = normalize(d1 + d2 * 0.5);

	float f1 = dot(w.xz, d1) * wave_frequency + t;
	float f2 = dot(w.xz, d2) * wave_frequency * 1.7 + t * 1.3;
	float f3 = dot(w.xz, d3) * wave_frequency * 2.3 + t * 0.8;

	float a1 = wave_height;
	float a2 = wave_height * 0.5;
	float a3 = wave_height * 0.25;

	float h = sin(f1) * a1 + sin(f2) * a2 + sin(f3) * a3;
	vec2 grad = d1 * cos(f1) * a1 * wave_frequency
			+ d2 * cos(f2) * a2 * wave_frequency * 1.7
			+ d3 * cos(f3) * a3 * wave_frequency * 2.3;

	VERTEX.y += h;
	NORMAL = normalize(vec3(-grad.x, 1.0, -grad.y));

	// normalized wave height, about -1..1 (independent of wave_height)
	v_height = h / max(wave_height * 1.75, 0.0001);
	v_world = w;
}

void fragment() {
	// ---- water thickness behind this pixel ----
	float depth = texture(depth_texture, SCREEN_UV).r;
	float z = compatibility_depth ? depth * 2.0 - 1.0 : depth;
	vec4 view_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, z, 1.0);
	view_pos.xyz /= view_pos.w;
	float water_depth = max(-view_pos.z + VERTEX.z, 0.0);
	// nothing behind the water (sky / far plane) -> treat as very deep
	if (depth >= 0.9999) {
		water_depth = depth_max;
	}

	// ---- posterized depth gradient ----
	float dt = clamp(water_depth / depth_max, 0.0, 1.0);
	float steps = float(color_steps - 1);
	dt = round(dt * steps) / steps;
	vec3 col = mix(shallow_color.rgb, deep_color.rgb, dt);
	float alpha = mix(alpha_shallow, alpha_deep, dt);

	// ---- surface lines ----
	vec2 vl = voronoi(v_world.xz * line_scale, TIME * line_speed);
	float lines = 1.0 - smoothstep(line_width, line_width + 0.02, vl.y);
	col = mix(col, line_color.rgb, lines * line_strength * (1.0 - dt * 0.6));

	// ---- fresnel rim ----
	float fres = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), fresnel_power);
	fres = step(fresnel_threshold, fres);
	col = mix(col, fresnel_color.rgb, fres * fresnel_amount);

	// ---- foam ----
	vec2 vf = voronoi(v_world.xz * foam_scale + vec2(TIME * foam_speed, 0.0), TIME * foam_speed * 2.0);
	float noise = vf.x - 0.5;

	float shore = 0.0;
	if (enable_shore_foam) {
		shore = step(water_depth, shore_foam_distance + noise * shore_foam_noise);
		shore *= step(0.0001, shore_foam_distance);
	}
	float crest = 0.0;
	if (enable_crest_foam) {
		crest = step(crest_foam_threshold, v_height + noise * 0.3);
	}
	float foam = clamp(shore + crest, 0.0, 1.0);

	ALBEDO = mix(col, foam_color.rgb, foam);
	EMISSION = foam_color.rgb * foam * 0.2;
	ALPHA = mix(alpha, 1.0, foam);
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.0;
}

void light() {
	float ndl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	float bands = float(light_bands);
	float toon = floor(ndl * bands) / bands;
	toon = mix(shadow_floor, 1.0, toon);
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * toon * 0.5;

	vec3 h = normalize(LIGHT + VIEW);
	float spec = pow(clamp(dot(NORMAL, h), 0.0, 1.0), specular_shininess);
	spec = smoothstep(specular_threshold, specular_threshold + 0.02, spec);
	SPECULAR_LIGHT += LIGHT_COLOR * ATTENUATION * spec * specular_strength;
}