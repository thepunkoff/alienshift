shader_type spatial;
// Inverted hull: render only back faces of a slightly inflated copy of the
// (terrain-displaced) mesh, so it peeks out around silhouettes and folds.
render_mode unshaded, cull_front, depth_draw_opaque, shadows_disabled;

#include "res://shaders/planet_terrain.gdshaderinc"

uniform vec3 outline_color : source_color = vec3(0.07, 0.04, 0.09);
// Thickness. With constant_screen_width on, it's roughly a fraction of
// view distance (0.004 ~ a few pixels); off, it's object-space units.
uniform float outline_width : hint_range(0.0, 0.05) = 0.004;
uniform bool constant_screen_width = true;

void vertex() {
	vec3 v = VERTEX;
	vec3 n = normalize(NORMAL);

	if (terrain_enabled) {
		vec3 dir = normalize(v);
		// Smoothed true normal (strength 1.0): avoids gaps in the hull.
		n = terrain_normal_ex(dir, length(v), min(normal_octaves, terrain_octaves),
				normal_epsilon, 1.0);
		v = terrain_displace(v);
	}

	float w = outline_width;
	if (constant_screen_width) {
		float dist = length((MODELVIEW_MATRIX * vec4(v, 1.0)).xyz);
		float obj_scale = length(MODEL_MATRIX[0].xyz);
		w *= dist / max(obj_scale, 1e-4);
	}

	VERTEX = v + n * w;
}

void fragment() {
	ALBEDO = outline_color;
}
