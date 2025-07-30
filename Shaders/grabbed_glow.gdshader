shader_type spatial;
render_mode blend_mul, cull_disabled, depth_draw_always, depth_test_disabled;

// ——— Control Variables ———
uniform float speed              = 0.25;
uniform float ring_scale         = 4.1;
uniform float wave_scale         = 0.1;
uniform float random_scale       = 2.25;
uniform float noise_scale        = 0.05;
uniform float c1                 = 0.72;
uniform float c2                 = 4.69;
uniform float c3                 = 7.35;
uniform float c4                 = 0.0;

uniform float emission_strength  = -1.15;  // Glow brightness
uniform float base_alpha         = -0.5;  // Overall transparency

// ——— Projection Mode ———
// 0 = XY (Front), 1 = YZ (Side), 2 = XZ (Top)
uniform int uv_projection_mode : hint_enum("XY (Front)", "YZ (Side)", "XZ (Top)") = 0;


// ——— Functions ———
vec3 hsv2rgb(float h, float s, float v) {
    return (
        (
            clamp(
                abs(fract(h + vec3(c1, c2, c3)/1.0) * 3.0 - c4) - 1.5,
                0.0,
                1.5
            ) - 1.0
        ) * s + 1.0
    ) * v;
}

vec2 random(vec2 pos) {
    return fract(
        sin(
            vec2(
                dot(pos, vec2(12.9898, 78.233)),
                dot(pos, vec2(-148.998, -65.233))
            )
        ) * 43758.5453
    );
}

float value_noise(vec2 pos) {
    vec2 p = floor(pos);
    vec2 f = fract(pos);

    float v00 = random(p + vec2(0.0, 0.0)).x;
    float v10 = random(p + vec2(1.0, 0.0)).x;
    float v01 = random(p + vec2(0.0, 1.0)).x;
    float v11 = random(p + vec2(1.0, 1.0)).x;

    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(v00, v10, u.x),
        mix(v01, v11, u.x),
        u.y
    );
}


// ——— Varyings ———
varying vec3 v_world_pos;

void vertex() {
    v_world_pos = (vec4(VERTEX, 1.0)).xyz;
}


// ——— Fragment Shader ———
void fragment() {
    // Projection switch: choose which 2D plane to map effect onto
    vec2 proj_uv;

    if (uv_projection_mode == 0) {
        proj_uv = vec2(v_world_pos.x, v_world_pos.y); // XY (Front)
    } else if (uv_projection_mode == 1) {
        proj_uv = vec2(v_world_pos.y, v_world_pos.z); // YZ (Side)
    } else {
        proj_uv = vec2(v_world_pos.x, v_world_pos.z); // XZ (Top)
    }

    // Scrolling & warping using projected UVs
    vec3 shift_uv = vec3(proj_uv, 0.0);
    shift_uv.x += value_noise(proj_uv * random_scale + TIME * speed);
    shift_uv.y += TIME * speed;
    float x = shift_uv.x + sin(shift_uv.y * wave_scale);
    float f = mod(x * ring_scale + random(proj_uv).x * noise_scale, 1.0);

    vec3 base_col = hsv2rgb(f, 1.0, 1.0);

    // Output
    ALBEDO = base_col;
    ALPHA  = base_alpha;

    EMISSION = base_col * emission_strength * base_alpha;
}
