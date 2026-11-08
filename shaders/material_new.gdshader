shader_type spatial;
// Lighting is fully custom (toon ramp in light()); no ambient/specular from Godot.
render_mode ambient_light_disabled, specular_disabled;

// Port of a Blender node material:
//
//   A: TexCoord.Normal -> Mapping(Point) -> ColorRamp(Constant) --\
//                                                                  Mix(Color, fac) -> Emission(1.0)
//   B: TexCoord.Generated -> Mapping -> Voronoi(F1, Minkowski) -> ColorRamp(Constant) --/
//
// Plus: procedural terrain displacement (planet_terrain.gdshaderinc).
// Outline: material_new_outline.gdshader, set as next_pass.

// ---- Mix (Color blend mode, clamped factor) ----
uniform float mix_factor : hint_range(0.0, 1.0) = 0.233;
uniform float emission_strength = 1.0;

// ---- A: Normal -> Mapping ----
uniform vec3 a_location = vec3(0.0);
uniform vec3 a_rotation_deg = vec3(343.0, 0.0, 0.0);
uniform vec3 a_scale = vec3(0.8, -1.7, 1.0);

// ---- A: Scene lighting ----
// On: the A ramp is driven by the scene's lights (N·L) instead of the fixed
// Normal->Mapping direction above. Off: original Blender behavior (unlit).
uniform bool use_scene_light = true;
// Ramp factor = light_ramp_scale * dot(N, L) + light_ramp_offset.
// 0.71 / 0.0 matches the Blender mapping (scale (0.8,-1.7,1)): same band widths.
uniform float light_ramp_scale = 0.71;
uniform float light_ramp_offset = 0.0;
// Tint the result by light color * energy.
uniform bool use_light_color = false;
// Shadowed areas fall into the dark stop of the ramp.
uniform bool receive_shadows = true;

// ---- A: Color Ramp (constant) ----
uniform vec3 a_c0 : source_color = vec3(0.325, 0.357, 0.388);
uniform vec3 a_c1 : source_color = vec3(0.251, 0.110, 0.322);
uniform vec3 a_c2 : source_color = vec3(0.549, 0.549, 0.549);
uniform vec3 a_c3 : source_color = vec3(0.753, 0.631, 0.812);
uniform float a_p1 : hint_range(0.0, 1.0) = 0.075;
uniform float a_p2 : hint_range(0.0, 1.0) = 0.09;
uniform float a_p3 : hint_range(0.0, 1.0) = 0.61;

// ---- B: Generated -> Mapping ----
// Godot has no automatic bounding box, so set this to the mesh AABB.
uniform vec3 bbox_min = vec3(-0.5);
uniform vec3 bbox_size = vec3(1.0);
uniform vec3 b_location = vec3(0.0);
uniform vec3 b_rotation_deg = vec3(0.0);
uniform vec3 b_scale = vec3(1.0);

// ---- B: Voronoi Texture (3D, F1, Minkowski, normalized) ----
uniform float voronoi_scale = -2.0;
uniform float voronoi_detail : hint_range(0.0, 15.0) = 0.5;
uniform float voronoi_roughness : hint_range(0.0, 1.0) = 0.307;
uniform float voronoi_lacunarity = 2.0;
uniform float voronoi_exponent = 0.5;
uniform float voronoi_randomness : hint_range(0.0, 1.0) = 1.0;

// ---- B: Color Ramp (constant) ----
uniform vec3 b_c0 : source_color = vec3(0.325, 0.357, 0.388);
uniform vec3 b_c1 : source_color = vec3(0.549, 0.549, 0.549);
uniform vec3 b_c2 : source_color = vec3(0.251, 0.110, 0.322);
uniform vec3 b_c3 : source_color = vec3(0.753, 0.631, 0.812);
uniform float b_p1 : hint_range(0.0, 1.0) = 0.08;
uniform float b_p2 : hint_range(0.0, 1.0) = 0.325;
uniform float b_p3 : hint_range(0.0, 1.0) = 0.6;

#include "res://shaders/planet_terrain.gdshaderinc"

// Blender's Generated coords come from the undeformed mesh; enable to use
// the displaced positions instead.
uniform bool generated_use_displaced = false;
// Recompute the terrain normal per pixel: crisp gradient edges on mountain
// sides regardless of mesh density. Off = per-vertex (cheaper, blurrier).
uniform bool per_pixel_normals = true;

varying vec3 obj_normal;
varying vec3 obj_pos;
varying vec3 obj_up;
varying float base_radius;
// fragment -> light: final color for each A-ramp stop (already blended with B).
varying vec3 v_lit0;
varying vec3 v_lit1;
varying vec3 v_lit2;
varying vec3 v_lit3;

void vertex() {
	// Object-space values, like Blender's Texture Coordinate node.
	obj_pos = VERTEX;
	obj_normal = NORMAL;
	obj_up = normalize(VERTEX);
	base_radius = length(VERTEX);

	if (terrain_enabled) {
		vec3 dir = normalize(VERTEX);
		vec3 p0 = terrain_displace(VERTEX);
		vec3 n = terrain_normal(dir, base_radius);

		VERTEX = p0;
		NORMAL = n;
		obj_normal = n;  // displaced normal drives branch A, like Blender's Normal coord
		if (generated_use_displaced) {
			obj_pos = p0;
		}
	}
}

// Blender Mapping (Point): rotate(scale * v) + location, Euler XYZ.
vec3 mapping_point(vec3 v, vec3 loc, vec3 rot_deg, vec3 scl) {
	vec3 r = radians(rot_deg);
	vec3 p = v * scl;
	float c = cos(r.x); float s = sin(r.x);
	p = vec3(p.x, c * p.y - s * p.z, s * p.y + c * p.z);
	c = cos(r.y); s = sin(r.y);
	p = vec3(c * p.x + s * p.z, p.y, -s * p.x + c * p.z);
	c = cos(r.z); s = sin(r.z);
	p = vec3(c * p.x - s * p.y, s * p.x + c * p.y, p.z);
	return p + loc;
}

// Constant-interpolation color ramp with 4 stops (first stop at 0).
vec3 ramp4(float f, vec3 c0, vec3 c1, vec3 c2, vec3 c3, float p1, float p2, float p3) {
	vec3 c = c0;
	c = mix(c, c1, step(p1, f));
	c = mix(c, c2, step(p2, f));
	c = mix(c, c3, step(p3, f));
	return c;
}

// Blender implicit socket conversions to float.
float vector_to_float(vec3 v) {
	return (v.x + v.y + v.z) / 3.0;
}

float color_to_float(vec3 c) {
	return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

vec3 hash33(vec3 p) {
	p = vec3(dot(p, vec3(127.1, 311.7, 74.7)),
			dot(p, vec3(269.5, 183.3, 246.1)),
			dot(p, vec3(113.5, 271.9, 124.6)));
	return fract(sin(p) * 43758.5453123);
}

// Single Voronoi F1 octave; returns the cell color.
vec3 voronoi_f1_color(vec3 p) {
	vec3 ip = floor(p);
	vec3 fp = p - ip;
	float best = 1e9;
	vec3 best_cell = ip;
	for (int k = -1; k <= 1; k++) {
		for (int j = -1; j <= 1; j++) {
			for (int i = -1; i <= 1; i++) {
				vec3 g = vec3(float(i), float(j), float(k));
				vec3 o = hash33(ip + g) * voronoi_randomness;
				vec3 d = abs(g + o - fp) + vec3(1e-6);
				float e = voronoi_exponent;
				float dist = pow(pow(d.x, e) + pow(d.y, e) + pow(d.z, e), 1.0 / e);
				if (dist < best) {
					best = dist;
					best_cell = ip + g;
				}
			}
		}
	}
	return hash33(best_cell + vec3(19.19, 7.7, 3.3));
}

// Blender 4.x fractal Voronoi (color output, normalized).
vec3 voronoi_fractal_color(vec3 coord) {
	float scale = voronoi_scale;
	float amplitude = 1.0;
	float max_amplitude = 0.0;
	vec3 color = vec3(0.0);
	int octaves = int(ceil(voronoi_detail));
	for (int i = 0; i <= 15; i++) {
		if (i > octaves) {
			break;
		}
		vec3 octave = voronoi_f1_color(coord * scale);
		if (i == 0) {
			color = octave;
			max_amplitude = 1.0;
			amplitude = voronoi_roughness;
		} else if (float(i) <= voronoi_detail) {
			color += octave * amplitude;
			max_amplitude += amplitude;
			amplitude *= voronoi_roughness;
		} else {
			float rem = voronoi_detail - floor(voronoi_detail);
			color = mix(color, color + octave * amplitude, rem);
			max_amplitude = mix(max_amplitude, max_amplitude + amplitude, rem);
		}
		scale *= voronoi_lacunarity;
	}
	return color / max_amplitude;
}

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Blender "Color" blend: hue + saturation of B, value of A.
vec3 blend_color(vec3 a, vec3 b, float fac) {
	vec3 hb = rgb2hsv(b);
	if (hb.y == 0.0) {
		return a;
	}
	vec3 ha = rgb2hsv(a);
	vec3 result = hsv2rgb(vec3(hb.x, hb.y, ha.z));
	return mix(a, result, clamp(fac, 0.0, 1.0));
}

void fragment() {
	vec3 n = normalize(obj_normal);
	if (terrain_enabled && per_pixel_normals) {
		n = terrain_normal(normalize(obj_up), base_radius);
	}

	// B
	vec3 generated = (obj_pos - bbox_min) / bbox_size;
	vec3 mb = mapping_point(generated, b_location, b_rotation_deg, b_scale);
	vec3 vc = voronoi_fractal_color(mb);
	vec3 col_b = ramp4(color_to_float(vc), b_c0, b_c1, b_c2, b_c3, b_p1, b_p2, b_p3);

	if (use_scene_light) {
		// Final color is produced in light(); ALBEDO = 1 so it passes through.
		v_lit0 = blend_color(a_c0, col_b, mix_factor) * emission_strength;
		v_lit1 = blend_color(a_c1, col_b, mix_factor) * emission_strength;
		v_lit2 = blend_color(a_c2, col_b, mix_factor) * emission_strength;
		v_lit3 = blend_color(a_c3, col_b, mix_factor) * emission_strength;
		NORMAL = normalize((VIEW_MATRIX * (MODEL_MATRIX * vec4(n, 0.0))).xyz);
		ALBEDO = vec3(1.0);
	} else {
		// Original unlit Blender behavior, output as emission.
		vec3 ma = mapping_point(n, a_location, a_rotation_deg, a_scale);
		vec3 col_a = ramp4(vector_to_float(ma), a_c0, a_c1, a_c2, a_c3, a_p1, a_p2, a_p3);
		ALBEDO = vec3(0.0);
		EMISSION = blend_color(col_a, col_b, mix_factor) * emission_strength;
	}
}

void light() {
	if (use_scene_light) {
		float ndl = dot(NORMAL, LIGHT);
		if (receive_shadows) {
			// Shadow pushes toward the fully-unlit end of the ramp.
			ndl = mix(-1.0, ndl, clamp(ATTENUATION, 0.0, 1.0));
		}
		float f = light_ramp_scale * ndl + light_ramp_offset;
		vec3 col = ramp4(f, v_lit0, v_lit1, v_lit2, v_lit3, a_p1, a_p2, a_p3);
		if (use_light_color) {
			col *= LIGHT_COLOR / PI;
		}
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
		// Compatibility sRGB-encodes the lit result once more than Forward+;
		// pre-decode so both renderers show the exact ramp colors.
		col = mix(col / 12.92, pow((col + 0.055) / 1.055, vec3(2.4)), step(0.04045, col));
#endif
		// Toon: brightest light wins instead of adding up.
		DIFFUSE_LIGHT = max(DIFFUSE_LIGHT, col);
	}
}
