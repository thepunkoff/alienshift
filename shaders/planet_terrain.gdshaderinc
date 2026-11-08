// Shared procedural terrain for planet shaders (color pass + outline pass).
// Terrain settings are *instance* uniforms: they live on the MeshInstance3D
// (Inspector > Geometry > Instance Shader Parameters), so every pass on that
// node (color + outline next_pass) reads the same values and stays in sync.

// ---- Terrain (vertex displacement along the sphere radius) ----
instance uniform bool terrain_enabled = true;
instance uniform float terrain_height = 0.77;
instance uniform float terrain_scale = 1.8;
instance uniform float sea_level : hint_range(0.0, 1.0) = 0.45;
instance uniform float mountain_sharpness = 1.5;
// Any integer gives a completely different landscape.
instance uniform int terrain_seed = 0;
instance uniform int terrain_octaves : hint_range(1, 8) = 5;
// Gentle relief below sea level (fraction of terrain_height), so no area is flat.
instance uniform float seabed_relief : hint_range(0.0, 1.0) = 0.15;

// ---- Terrain normals ----
// Exaggerates how far mountain normals tilt away from the sphere surface.
instance uniform float normal_strength : hint_range(0.0, 8.0) = 5.2;
// Finite-difference step for the normal (smaller = picks up finer detail).
instance uniform float normal_epsilon : hint_range(0.0005, 0.1) = 0.0455;
// Noise octaves used for normals. Fewer = only big landforms count;
// geometry still uses terrain_octaves.
instance uniform int normal_octaves : hint_range(1, 8) = 3;

// PCG3D integer hash: uniform output everywhere, seeded.
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

float hash31(vec3 lattice) {
	uint s = uint(terrain_seed);
	uvec3 u = uvec3(ivec3(lattice)) + uvec3(s * 747796405u, s * 2891336453u, s * 277803737u);
	return float(pcg3d(u).x) / 4294967295.0;
}

float value_noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash31(i), hash31(i + vec3(1.0, 0.0, 0.0)), f.x),
			mix(hash31(i + vec3(0.0, 1.0, 0.0)), hash31(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
			mix(mix(hash31(i + vec3(0.0, 0.0, 1.0)), hash31(i + vec3(1.0, 0.0, 1.0)), f.x),
			mix(hash31(i + vec3(0.0, 1.0, 1.0)), hash31(i + vec3(1.0, 1.0, 1.0)), f.x), f.y), f.z);
}

float fbm(vec3 p, int octaves) {
	float sum = 0.0;
	float amp = 0.5;
	float norm = 0.0;
	for (int i = 0; i < 8; i++) {
		if (i >= octaves) {
			break;
		}
		sum += amp * value_noise(p);
		norm += amp;
		p *= 2.0;
		amp *= 0.5;
	}
	return sum / norm;
}

// Height above the base radius for a direction on the sphere.
float terrain_at(vec3 dir, int octaves) {
	float h = fbm(dir * terrain_scale, octaves);
	float land = max(h - sea_level, 0.0) / max(1.0 - sea_level, 1e-4);
	float seabed = min(h, sea_level) / max(sea_level, 1e-4);
	return (pow(land, mountain_sharpness) + seabed * seabed_relief) * terrain_height;
}

// Normal of the displaced surface at a sphere direction, from two nearby samples.
// strength: 1.0 = true normal, >1 exaggerates tilt.
vec3 terrain_normal_ex(vec3 dir, float radius, int octaves, float eps, float strength) {
	vec3 up = abs(dir.y) < 0.99 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
	vec3 t1 = normalize(cross(dir, up));
	vec3 t2 = cross(dir, t1);
	vec3 d1 = normalize(dir + t1 * eps);
	vec3 d2 = normalize(dir + t2 * eps);

	vec3 p0 = dir * (radius + terrain_at(dir, octaves));
	vec3 p1 = d1 * (radius + terrain_at(d1, octaves));
	vec3 p2 = d2 * (radius + terrain_at(d2, octaves));

	vec3 n = normalize(cross(p1 - p0, p2 - p0));
	if (dot(n, dir) < 0.0) {
		n = -n;
	}
	vec3 tilt = n - dir * dot(n, dir);
	return normalize(dir * dot(n, dir) + tilt * strength);
}

// Normal used for coloring (uses the normal_* settings).
vec3 terrain_normal(vec3 dir, float radius) {
	return terrain_normal_ex(dir, radius, min(normal_octaves, terrain_octaves),
			normal_epsilon, normal_strength);
}

// Displaced object-space position for an undeformed vertex.
vec3 terrain_displace(vec3 v) {
	vec3 dir = normalize(v);
	return dir * (length(v) + terrain_at(dir, terrain_octaves));
}
