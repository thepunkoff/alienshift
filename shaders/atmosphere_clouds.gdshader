shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, specular_disabled;

group_uniforms atmosphere;
uniform vec4 atmosphere_color : source_color = vec4(0.55, 0.85, 1.0, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
uniform float haze : hint_range(0.0, 1.0) = 0.1;
uniform float rim_alpha : hint_range(0.0, 1.0) = 0.6;
uniform float rim_width : hint_range(0.0, 1.0) = 0.25;

group_uniforms clouds;
uniform vec4 cloud_color : source_color = vec4(1.0);
uniform vec4 shade_color : source_color = vec4(0.7, 0.8, 0.95, 1.0);
uniform float cloud_tint : hint_range(0.0, 1.0) = 0.2;
uniform float coverage : hint_range(0.0, 1.0) = 0.47;
uniform float shade_width : hint_range(0.0, 0.2) = 0.035;
uniform float edge_sharpness : hint_range(0.5, 4.0) = 1.0;
uniform float cloud_scale : hint_range(0.5, 12.0) = 3.5;
uniform int octaves : hint_range(1, 6) = 3;
uniform float warp : hint_range(0.0, 2.0) = 0.35;
uniform float stretch : hint_range(1.0, 4.0) = 1.6;

group_uniforms motion;
uniform vec3 spin_axis = vec3(0.0, 1.0, 0.0);
uniform float spin_speed : hint_range(-1.0, 1.0) = 0.04;
uniform float morph_speed : hint_range(0.0, 1.0) = 0.05;

group_uniforms lighting;
uniform int light_bands : hint_range(1, 4) = 2;
uniform float shadow_floor : hint_range(0.0, 1.0) = 0.55;
uniform float self_light : hint_range(0.0, 1.0) = 0.25;

varying vec3 v_dir;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(mix(hash(i + vec3(0, 0, 0)), hash(i + vec3(1, 0, 0)), f.x),
			mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x),
			mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y),
		f.z);
}

float fbm(vec3 p) {
	float sum = 0.0;
	float amp = 0.5;
	float norm = 0.0;
	for (int i = 0; i < 6; i++) {
		if (i >= octaves) {
			break;
		}
		sum += amp * noise(p);
		norm += amp;
		p = p * 2.03 + vec3(1.7, 9.2, 4.1);
		amp *= 0.5;
	}
	return sum / norm;
}

vec3 rotate(vec3 v, vec3 axis, float angle) {
	axis = normalize(axis);
	float c = cos(angle);
	float s = sin(angle);
	return v * c + cross(axis, v) * s + axis * dot(axis, v) * (1.0 - c);
}

float hard_step(float edge, float x) {
	float aa = max(fwidth(x), 1e-4) * edge_sharpness;
	return smoothstep(edge - aa, edge + aa, x);
}

void vertex() {
	v_dir = normalize(VERTEX);
}

void fragment() {
	vec3 dir = rotate(normalize(v_dir), spin_axis, TIME * spin_speed);

	vec3 axis = normalize(spin_axis);
	vec3 p = dir - axis * dot(dir, axis) * (1.0 - 1.0 / stretch);
	p *= cloud_scale;

	float t = TIME * morph_speed;
	vec3 w = vec3(fbm(p + vec3(0.0, t, 0.0)), fbm(p + vec3(5.2, 1.3, t)), fbm(p + vec3(t, 7.1, 2.8)));
	float n = fbm(p + (w - 0.5) * 2.0 * warp + vec3(t * 0.5));

	float threshold = 1.0 - coverage;
	float cloud = hard_step(threshold, n);
	float core = hard_step(threshold + shade_width, n);

	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = 1.0 - hard_step(rim_width, facing);
	float air = max(haze, rim * rim_alpha) * atmosphere_color.a;

	vec3 base_cloud = mix(cloud_color.rgb, cloud_color.rgb * atmosphere_color.rgb, cloud_tint);
	vec3 shade = mix(shade_color.rgb, shade_color.rgb * atmosphere_color.rgb, cloud_tint);
	vec3 cloud_rgb = mix(shade, base_cloud, core);
	float cloud_alpha = cloud * cloud_color.a;

	vec3 col = mix(atmosphere_color.rgb, cloud_rgb, cloud_alpha);
	ALBEDO = col;
	EMISSION = col * self_light;
	ROUGHNESS = 1.0;
	ALPHA = clamp(max(air, cloud_alpha), 0.0, 1.0) * opacity;
}

void light() {
	float ndl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION;
	float bands = float(light_bands);
	float toon = mix(shadow_floor, 1.0, ceil(ndl * bands) / bands);
	DIFFUSE_LIGHT = max(DIFFUSE_LIGHT, LIGHT_COLOR / PI * toon);
}
