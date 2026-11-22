
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

varying vec3 local_normal;

float ramp_a_factor(vec3 n) {
    vec3 p = n * vec3(1.00000000, 1.00000000, 1.00000000);
    float c = cos(0.82379532);
    float s = sin(0.82379532);
    p = vec3(
        c * p.x - s * p.y,
        s * p.x + c * p.y,
        p.z
    );
    p += vec3(0.00000000, 0.00000000, 1.19999993);
    return (p.x + p.y + p.z) / 3.0;
}

float ramp_b_factor(vec3 n) {
    vec3 p = n * vec3(1.00000000, 1.00000000, 1.00000000);
    float c = cos(0.82379532);
    float s = sin(0.82379532);
    p = vec3(
        c * p.x - s * p.y,
        s * p.x + c * p.y,
        p.z
    );
    p += vec3(0.00000000, 0.00000000, 1.19999993);
    return (p.x + p.y + p.z) / 3.0;
}

vec3 color_a(float t) {
    if (t <= 0.00000000) return vec3(0.10675408, 0.00000000, 0.03166395);
    if (t <= 0.02272727) {
        float f = clamp((t - 0.00000000) / max(0.02272727, 0.000001), 0.0, 1.0);
        f = f * f * (3.0 - 2.0 * f);
        return mix(vec3(0.10675408, 0.00000000, 0.03166395), vec3(0.03341571, 0.00000000, 0.01304496), f);
    }
    if (t <= 0.15000002) {
        float f = clamp((t - 0.02272727) / max(0.12727275, 0.000001), 0.0, 1.0);
        f = f * f * (3.0 - 2.0 * f);
        return mix(vec3(0.03341571, 0.00000000, 0.01304496), vec3(0.22840974, 0.01457957, 0.10675666), f);
    }
    if (t <= 0.35454643) {
        float f = clamp((t - 0.15000002) / max(0.20454641, 0.000001), 0.0, 1.0);
        f = f * f * (3.0 - 2.0 * f);
        return mix(vec3(0.22840974, 0.01457957, 0.10675666), vec3(1.00000000, 0.04722758, 0.27349424), f);
    }
    if (t <= 0.52727324) {
        float f = clamp((t - 0.35454643) / max(0.17272681, 0.000001), 0.0, 1.0);
        f = f * f * (3.0 - 2.0 * f);
        return mix(vec3(1.00000000, 0.04722758, 0.27349424), vec3(0.97228169, 0.42078680, 0.72075039), f);
    }
    if (t <= 0.66590947) {
        float f = clamp((t - 0.52727324) / max(0.13863623, 0.000001), 0.0, 1.0);
        f = f * f * (3.0 - 2.0 * f);
        return mix(vec3(0.97228169, 0.42078680, 0.72075039), vec3(0.63467622, 0.00000000, 0.15896603), f);
    }
    if (t <= 0.74545479) {
        float f = clamp((t - 0.66590947) / max(0.07954532, 0.000001), 0.0, 1.0);
        f = f * f * (3.0 - 2.0 * f);
        return mix(vec3(0.63467622, 0.00000000, 0.15896603), vec3(0.22840974, 0.01457957, 0.10675666), f);
    }
    return vec3(0.22840974, 0.01457957, 0.10675666);
}

vec3 color_b(float t) {
    if (t <= 0.00000000) return vec3(0.10675408, 0.00000000, 0.03166395);
    if (t < 0.02272727) return vec3(0.10675408, 0.00000000, 0.03166395);
    if (t < 0.15000002) return vec3(0.03341571, 0.00000000, 0.01304496);
    if (t < 0.35454643) return vec3(0.22840974, 0.01457957, 0.10675666);
    if (t < 0.52727324) return vec3(1.00000000, 0.04722758, 0.27349424);
    if (t < 0.66590947) return vec3(0.97228169, 0.42078680, 0.72075039);
    if (t < 0.74545479) return vec3(0.63467622, 0.00000000, 0.15896603);
    return vec3(0.22840974, 0.01457957, 0.10675666);
}

vec3 overlay_colors(vec3 a, vec3 b) {
    vec3 low = 2.0 * a * b;
    vec3 high = vec3(1.0) -
        2.0 * (vec3(1.0) - a) * (vec3(1.0) - b);

    return mix(
        low,
        high,
        step(vec3(0.5), a)
    );
}

void vertex() {
    local_normal = NORMAL;
}

void fragment() {
    vec3 n = normalize(local_normal);

    float fa = ramp_a_factor(n);
    float fb = ramp_b_factor(n);

    vec3 a = color_a(fa);
    vec3 b = color_b(fb);

    vec3 combined = mix(
        a,
        overlay_colors(a, b),
        0.26666668
    );

    ALBEDO = combined;
    ROUGHNESS = 1.00000000;
    METALLIC = 0.00000000;
}
