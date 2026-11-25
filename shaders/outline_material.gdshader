shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled;

uniform vec4 outline_color : source_color = vec4(1.0);
uniform float width : hint_range(0.0, 0.5) = 0.03;

void vertex() {
    VERTEX += normalize(VERTEX) * width;
}

void fragment() {
    if (COLOR.r < 0.5) {
        discard;
    }

    ALBEDO = outline_color.rgb;
}
