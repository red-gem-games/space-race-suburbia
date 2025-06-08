shader_type spatial;
render_mode unshaded, depth_prepass_alpha, blend_mix, cull_disabled;

// Teleport progress (0 → 1)
uniform float progress       : hint_range(0.0, 1.0) = 0.0;
// How noisy the tear effect is
uniform float noise_density  = 60.0;
// How thick the glowing beam stripe remains
uniform float beam_size      : hint_range(0.01, 0.5) = 0.5;
// Base “solid” color of your mesh (since there’s no texture to sample)
uniform vec3  base_color     = vec3(1.0, 1.0, 1.0);
// Overall base alpha (in case you want a semi-transparent mesh)
uniform float base_alpha     : hint_range(0.0, 1.0) = 1.0;
// Color of the teleportation beam/glow
uniform vec3  beam_color      = vec3(0.0, 1.02, 1.2);
// Intensity of the beam glow (feeds into EMISSION)
uniform float emission_strength = 1.0;

// ————————————
// 1) Generate 2D value noise
// ————————————
vec2 random2d(vec2 uv) {
    uv = vec2(
        dot(uv, vec2(127.1, 311.7)),
        dot(uv, vec2(269.5, 183.3))
    );
    return -1.0 + 2.0 * fract(sin(uv) * 43758.5453123);
}

float value_noise_2d(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float v00 = dot(random2d(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0));
    float v10 = dot(random2d(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0));
    float v01 = dot(random2d(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0));
    float v11 = dot(random2d(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0));
    float i1 = mix(v00, v10, u.x);
    float i2 = mix(v01, v11, u.x);
    return mix(i1, i2, u.y) * 0.5 + 0.5;
}

// ————————————
// 2) Main Fragment: carve away and glow
// ————————————
void fragment() {
    // Use flat base_color instead of sampling a missing texture
    vec3 col = base_color;

    // Compute noise at UV, scaled, times UV.y so it erases from “bottom” (u.y=0) upward.
    float n = value_noise_2d(UV * noise_density) * UV.y;

    // Two step() calls isolate a thin stripe (“beam”) of width beam_size.
    float d1 = step(progress, n);
    float d2 = step(progress - beam_size, n);
    // (d2 - d1) is 1 inside the narrow stripe, 0 elsewhere.
    vec3 beam_col = (d2 - d1) * beam_color;

    // Add the beam on top of your base_color
    vec3 final_col = col + beam_col;

    // Fade the mesh away everywhere except where d2 == 1 (the beam region).
    float final_alpha = base_alpha * d2;

    ALBEDO   = final_col;
    ALPHA    = final_alpha;
    EMISSION = beam_col * emission_strength;
}
