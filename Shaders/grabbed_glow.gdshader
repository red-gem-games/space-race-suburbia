shader_type spatial;
render_mode unshaded, blend_mix, cull_front;


// your existing “scroll + noise” parameters
uniform float speed         = 0.1;
uniform float ring_scale    = 1.5;
uniform float wave_scale    = 4.0;
uniform float random_scale  = 10.0;
uniform float noise_scale   = 0.1;
uniform float c1 = 0.18;
uniform float c2 = 0.5;
uniform float c3 = 2.98;
uniform float c4 = 3.25;


// new: where the fade starts/ends in local‐space Y
uniform float fade_min_y    =  -3.0;  // fully opaque at or below this Y
uniform float fade_max_y    =  3.0;  // fully transparent at or above this Y

// new: emission (glow) control
uniform float emission_strength = 1.0; // how “bright” the glow is

// ----------------------------------------------
// 1) hsv2rgb (unchanged)
// ----------------------------------------------
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

// ----------------------------------------------
// 2) value_noise / random (unchanged)
// ----------------------------------------------
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

// ----------------------------------------------
// 3) Pass local‐space Y from vertex→fragment
// ----------------------------------------------
varying float v_local_y;

void vertex() {
    v_local_y = VERTEX.y;
    // Godot’s built-ins handle the rest of the transforms
}

// ----------------------------------------------
// 4) Compute UV warping, color, fade, and emission
// ----------------------------------------------
void fragment() {
    // ——— A) Scroll & warp your UV exactly as before ———
    vec2 shift_uv = UV;
    shift_uv.x += value_noise(UV * random_scale + TIME * speed);
    shift_uv.y += TIME * speed;
    float x = shift_uv.x + sin(shift_uv.y * wave_scale);
    float f = mod(x * ring_scale + random(UV).x * noise_scale, 1.0);

    vec3 base_col = hsv2rgb(f, 1.0, 1.0);

    // ——— B) Compute alpha based on local Y vs fade_min_y/fade_max_y ———
    float alpha = clamp((fade_max_y - v_local_y) / (fade_max_y - fade_min_y), 0.0, 1.0);

    // ——— C) Output color + transparency ———
    ALBEDO = base_col;
    ALPHA  = alpha;

    // ——— D) Emission (glow) ———
    // Multiply your base color by an emission strength
    // Optionally, you can also let glow fade out along with alpha
    EMISSION = base_col * emission_strength * alpha;
}
