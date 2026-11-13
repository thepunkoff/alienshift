shader_type sky;

// Cartoon space: flat gradient, posterized nebula bands, hard-edged stars
// (round dots + 4-point sparkles) with a gentle twinkle. All edges are
// hard steps to match the toon planet.

// ---- Background ----
uniform vec3 space_top : source_color = vec3(0.075, 0.055, 0.13);
uniform vec3 space_bottom : source_color = vec3(0.03, 0.03, 0.07);
// Number of flat bands in the background gradient (0 = smooth).
uniform int gradient_bands : hint_range(0, 8) = 3;

// ---- Nebula ----
uniform bool nebula_enabled = true;
uniform vec3 nebula_dark : source_color = vec3(0.14, 0.07, 0.2);
uniform vec3 nebula_mid : source_color = vec3(0.25, 0.11, 0.32);
uniform vec3 nebula_light : source_color = vec3(0.42, 0.25, 0.5);
uniform float nebula_scale = 1.6;
// Higher = less nebula on screen.
uniform float nebula_threshold : hint_range(0.0, 1.0) = 0.55;
// Gap between bands (in noise units).
uniform float nebula_band_step : hint_range(0.01, 0.2) = 0.07;
uniform int nebula_seed = 7;

// ---- Stars ----
uniform vec3 star_color : source_color = vec3(1.0, 0.97, 0.92);
uniform vec3 star_tint_a : source_color = vec3(0.85, 0.75, 1.0);
uniform vec3 star_tint_b : source_color = vec3(1.0, 0.9, 0.65);
// Small round stars.
uniform float dot_density = 70.0;
uniform float dot_size : hint_range(0.0, 0.02) = 0.0016;
// Fraction of cells that contain a dot star.
uniform float dot_amount : hint_range(0.0, 1.0) = 0.12;
// Big 4-point sparkle stars.
uniform float sparkle_density = 14.0;
uniform float sparkle_size : hint_range(0.0, 0.1) = 0.016;
uniform float sparkle_amount : hint_range(0.0, 1.0) = 0.06;
uniform float twinkle_speed = 1.5;
uniform float twinkle_amount : hint_range(0.0, 1.0) = 0.3;
uniform int star_seed = 1;

// ---- Rotation ----
// Spin of the nebula + stars. Negative speed reverses direction.
uniform float rotation_speed = 1.0; // degrees per second
// Axis the sky spins around (normalized in shader; Y = spin around the vertical).
uniform vec3 rotation_axis = vec3(0.0, 1.0, 0.0);

// Rodrigues rotation of v around unit axis k by angle a.
vec3 rotate_axis(vec3 v, vec3 k, float a) {
	float c = cos(a);
	float s = sin(a);
	return v * c + cross(k, v) * s + k * dot(k, v) * (1.0 - c);
}

// ---- Hashing / noise ----
uvec3 pcg3d(uvec3 v) {
	v = v * 1664525u + 1013904223u;
	v.x += v.y * v.z;
	v.y += v.z * v.x;
	v.z += v.x * v.y;
	v ^= v >> uvec3(16u);
	v.x += v.y * v.z;
	v.y += v.z * v.x;
	v.z += v.x * v.y;
	return v;
}

vec3 hash33(vec3 cell, int seed) {
	uint s = uint(seed);
	uvec3 u = uvec3(ivec3(cell)) + uvec3(s * 747796405u, s * 2891336453u, s * 277803737u);
	return vec3(pcg3d(u)) / 4294967295.0;
}

float value_noise(vec3 x, int seed) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash33(i, seed).x, hash33(i + vec3(1, 0, 0), seed).x, f.x),
			mix(hash33(i + vec3(0, 1, 0), seed).x, hash33(i + vec3(1, 1, 0), seed).x, f.x), f.y),
			mix(mix(hash33(i + vec3(0, 0, 1), seed).x, hash33(i + vec3(1, 0, 1), seed).x, f.x),
			mix(hash33(i + vec3(0, 1, 1), seed).x, hash33(i + vec3(1, 1, 1), seed).x, f.x), f.y), f.z);
}

float fbm(vec3 p, int seed) {
	float sum = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		sum += amp * value_noise(p, seed);
		p = p * 2.03 + vec3(1.7, 9.2, 4.1);
		amp *= 0.5;
	}
	return sum / 0.9375;
}

// ---- Stars ----
// One layer of stars on the unit sphere. Space is cut into cells of size
// 1/density; each cell near the sphere may hold one star.
// Returns vec4(color, alpha). `time` is passed in because the Compatibility
// renderer only exposes TIME inside sky().
vec4 star_layer(vec3 dir, float density, float size, float amount, bool sparkle, int seed, float time) {
	vec3 p = dir * density;
	vec3 base = floor(p);
	vec4 result = vec4(0.0);
	for (int z = -1; z <= 1; z++) {
		for (int y = -1; y <= 1; y++) {
			for (int x = -1; x <= 1; x++) {
				vec3 cell = base + vec3(float(x), float(y), float(z));
				vec3 h = hash33(cell, seed);
				if (h.x > amount) {
					continue;
				}
				vec3 star_pos = cell + 0.15 + 0.7 * hash33(cell + 31.0, seed);
				// Keep only stars close to the sphere shell (even distribution).
				if (abs(length(star_pos) - density) > 0.5) {
					continue;
				}
				vec3 s = normalize(star_pos);

				// Angular offset of this pixel from the star, in a tangent basis.
				vec3 up = abs(s.y) < 0.99 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
				vec3 t1 = normalize(cross(s, up));
				vec3 t2 = cross(s, t1);
				vec3 d = dir - s;
				vec2 uv = vec2(dot(d, t1), dot(d, t2));

				float twinkle = 1.0 + twinkle_amount * sin(time * twinkle_speed * (0.6 + h.y) + h.z * 6.2831);
				float r = size * (0.5 + h.y) * twinkle;

				float shape;
				if (sparkle) {
					// Random rotation, then a 4-point astroid star + small core.
					float a = h.z * 1.5708;
					uv = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * uv;
					vec2 q = sqrt(abs(uv) / r);
					shape = step(q.x + q.y, 1.0);
					shape = max(shape, step(length(uv), r * 0.22));
				} else {
					shape = step(length(uv), r);
				}

				if (shape > 0.0) {
					vec3 tint = h.y < 0.33 ? star_tint_a : (h.y < 0.66 ? star_tint_b : star_color);
					result = vec4(tint, 1.0);
				} else if (sparkle) {
					// Flat toon glow disc behind sparkles.
					float ring = step(length(uv), r * 0.55);
					if (ring > 0.0 && result.a < 0.5) {
						result = vec4(nebula_light, 0.5);
					}
				}
			}
		}
	}
	return result;
}

void sky() {
	vec3 dir = normalize(EYEDIR);

	// Background gradient, optionally banded.
	float g = clamp(dir.y * 0.5 + 0.5, 0.0, 1.0);
	if (gradient_bands > 0) {
		float b = float(gradient_bands);
		g = floor(g * b) / max(b - 1.0, 1.0);
	}
	vec3 col = mix(space_bottom, space_top, clamp(g, 0.0, 1.0));

	// Rotated direction for nebula + stars (gradient stays fixed to the horizon).
	vec3 axis = length(rotation_axis) > 0.0001 ? normalize(rotation_axis) : vec3(0.0, 1.0, 0.0);
	vec3 rdir = rotate_axis(dir, axis, -radians(rotation_speed) * TIME);

	// Nebula: fbm posterized into 3 flat bands with hard edges.
	if (nebula_enabled) {
		float n = fbm(rdir * nebula_scale, nebula_seed);
		if (n > nebula_threshold) {
			col = nebula_dark;
		}
		if (n > nebula_threshold + nebula_band_step) {
			col = nebula_mid;
		}
		if (n > nebula_threshold + nebula_band_step * 2.0) {
			col = nebula_light;
		}
	}

	// Stars (dots first, sparkles on top).
	vec4 dots = star_layer(rdir, dot_density, dot_size, dot_amount, false, star_seed, TIME);
	col = mix(col, dots.rgb, dots.a);
	vec4 sparks = star_layer(rdir, sparkle_density, sparkle_size, sparkle_amount, true, star_seed + 101, TIME);
	col = mix(col, sparks.rgb, sparks.a);

	COLOR = col;
}
