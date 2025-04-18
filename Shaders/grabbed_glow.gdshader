shader_type spatial;
render_mode unshaded, cull_front, depth_draw_always, blend_premul_alpha;

// Holo tint & opacity
uniform vec4 glow_color = vec4(0.0, 1.0, 1.0, 0.5);
// Change this (0.0–1.0) on load to re‑seed all your sweeps
uniform float random_seed : hint_range(0.0, 1.0) = 0.0;

// Fresnel edge
uniform float fresnel_power = 0.1;

// --- your ranges ---
const float MIN_SPEED   = 0.025;
const float MAX_SPEED   = 0.20;
const float MIN_THICK   = 0.01;
const float MAX_THICK   = 0.15;
const float MIN_WIGGLE  = 0.005;
const float MAX_WIGGLE  = 0.04;

// simple 1D hash
float rand(float x) {
    return fract(sin(x * 12.9898) * 43758.5453);
}

void fragment() {
    // --- derive four independent random params each ---
    float spd_v1 = mix(MIN_SPEED, MAX_SPEED, rand(random_seed + 1.0));
    float spd_v2 = mix(MIN_SPEED, MAX_SPEED, rand(random_seed + 2.0));
    float spd_h1 = mix(MIN_SPEED, MAX_SPEED, rand(random_seed + 3.0));
    float spd_h2 = mix(MIN_SPEED, MAX_SPEED, rand(random_seed + 4.0));

    float th_v1  = mix(MIN_THICK, MAX_THICK,   rand(random_seed + 5.0));
    float th_v2  = mix(MIN_THICK, MAX_THICK,   rand(random_seed + 6.0));
    float th_h1  = mix(MIN_THICK, MAX_THICK,   rand(random_seed + 7.0));
    float th_h2  = mix(MIN_THICK, MAX_THICK,   rand(random_seed + 8.0));

    float wg_v1  = mix(MIN_WIGGLE, MAX_WIGGLE, rand(random_seed + 9.0));
    float wg_v2  = mix(MIN_WIGGLE, MAX_WIGGLE, rand(random_seed + 10.0));
    float wg_h1  = mix(MIN_WIGGLE, MAX_WIGGLE, rand(random_seed + 11.0));
    float wg_h2  = mix(MIN_WIGGLE, MAX_WIGGLE, rand(random_seed + 12.0));

    // ——— compute a time_offset that oscillates between 0 and 0.5 ———
    float t_off = sin(TIME) * 0.25 + 0.25;
    vec2 cuv = UV - vec2(0.5);

    // — Vertical sweep #1 —
    float vc1 = mod(TIME * spd_v1 + t_off, 1.0);
    float vw1 = sin(cuv.x * 20.0 + TIME * 6.0 + t_off) * wg_v1;
    float va1 = UV.y + vw1;
    float vb1 = smoothstep(vc1 - th_v1, vc1, va1)
              * (1.0 - smoothstep(vc1, vc1 + th_v1, va1));

    // — Vertical sweep #2 —
    float vc2 = mod(1.0 - TIME * spd_v2 + t_off, 1.0);
    float vw2 = sin(cuv.x * 20.0 + TIME * 5.0 - t_off) * wg_v2;
    float va2 = UV.y + vw2;
    float vb2 = smoothstep(vc2 - th_v2, vc2, va2)
              * (1.0 - smoothstep(vc2, vc2 + th_v2, va2));

    // — Horizontal sweep #1 —
    float hc1 = mod(TIME * spd_h1 + t_off, 1.0);
    float hw1 = sin(cuv.y * 20.0 + TIME * 4.0 + t_off) * wg_h1;
    float ha1 = UV.x + hw1;
    float hb1 = smoothstep(hc1 - th_h1, hc1, ha1)
              * (1.0 - smoothstep(hc1, hc1 + th_h1, ha1));

    // — Horizontal sweep #2 —
    float hc2 = mod(1.0 - TIME * spd_h2 + t_off, 1.0);
    float hw2 = sin(cuv.y * 20.0 + TIME * 3.0 - t_off) * wg_h2;
    float ha2 = UV.x + hw2;
    float hb2 = smoothstep(hc2 - th_h2, hc2, ha2)
              * (1.0 - smoothstep(hc2, hc2 + th_h2, ha2));

    // Combine
    float total_band = clamp(vb1 + vb2 + hb1 + hb2, 0.0, 1.0);

    // Sweep highlight back to a brighter tint
    vec3 sweep_color   = clamp(glow_color.rgb + vec3(0.3), vec3(0.0), vec3(1.0));
    vec3 blended_color = mix(glow_color.rgb, sweep_color, total_band);

    // Fresnel edge glow
    float fr = pow(1.0 - abs(dot(NORMAL, VIEW)), fresnel_power);
    vec3 final_color = blended_color + glow_color.rgb * fr;

    ALBEDO = final_color;
    ALPHA  = glow_color.a;
}

