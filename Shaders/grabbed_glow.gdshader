shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled;

// your existing “scroll + noise” parameters
uniform float speed         = 0.3;
uniform float ring_scale    = 0.5;
uniform float wave_scale    = 60.0;
uniform float random_scale  = 7.5;
uniform float noise_scale   = 0.1;

// new: where the fade starts/ends in local‐space Y
// (for a typical Godot CylinderMesh of height=2.0, Y ranges from -1.0 to +1.0)
uniform float fade_min_y    =  0.0;  // fully opaque at or below this Y
uniform float fade_max_y    =  1.0;  // fully transparent at or above this Y

// ----------------------------------------------
// 1) A little override of hsv2rgb for wide stripes
//    (unchanged, but included here for completeness)
// ----------------------------------------------
vec3 hsv2rgb(float h, float s, float v) {
    return (
        (
            clamp(
                abs(fract(h + vec3(0.0, 1.25, 1.0)/2.0) * 3.0 - 3.0) - 1.5,
                0.0,
                1.5
            ) - 1.0
        ) * s + 1.25
    ) * v;
}

// ----------------------------------------------
// 2) The same value_noise / random functions
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
// 3) We want each fragment to know its local‐space Y.
//    Use a varying to pass it from the vertex stage.
// ----------------------------------------------
varying float v_local_y;

void vertex() {
    // VERTEX is the mesh's local‐space position of each vertex.
    // Store its Y for use in the fragment() stage.
    v_local_y = VERTEX.y;
    // Let Godot perform its usual transform_to_screen() and such
    // by leaving the built‐in code intact.
}

// ----------------------------------------------
// 4) In the fragment(), we calculate a 0→1 alpha
//    based on how “close to the top” this Y is.
// ----------------------------------------------
void fragment() {
    // ——— A) Scroll & warp your UV exactly as before ———
    vec2 shift_uv = UV;
    shift_uv.x += value_noise(UV * random_scale + TIME * speed);
    shift_uv.y += TIME * speed;
    float x = shift_uv.x + sin(shift_uv.y * wave_scale);
    float f = mod(x * ring_scale + random(UV).x * noise_scale, 1.0);

    vec3 col = hsv2rgb(f, 1.0, 1.0);

    // ——— B) Compute alpha based on local Y vs fade_min_y/fade_max_y ———
    //    Anything at or below fade_min_y → alpha = 1.0 (fully opaque)
    //    Anything at or above fade_max_y → alpha = 0.0 (fully transparent)
    //    Linear interpolation in between.
    float alpha = clamp((fade_max_y - v_local_y) / (fade_max_y - fade_min_y), 0.0, 1.0);

    // ——— C) Output color + transparency ———
    ALBEDO = col;       // base color
    EMISSION = col;     // keep it glowing
    ALPHA   = alpha;    // apply our fade
}
