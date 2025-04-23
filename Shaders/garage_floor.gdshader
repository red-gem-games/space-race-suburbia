shader_type spatial;
render_mode cull_back;

// Base color (light gray concrete)
uniform vec4 base_color = vec4(0.85, 0.85, 0.85, 1.0);

// Tileable noise texture for surface variation
uniform sampler2D noise_texture;
uniform float noise_scale : hint_range(1.0, 100.0) = 20.0;

// Tileable crack mask texture (white cracks on black)
uniform sampler2D crack_texture;
uniform float crack_scale : hint_range(1.0, 20.0) = 3.0;
uniform float crack_threshold : hint_range(0.0, 1.0) = 0.7;

// Strength of chipped edges via normal perturb
uniform float chip_strength : hint_range(0.0, 1.0) = 0.1;

void fragment() {
    vec2 uv = UV;

    // 1) subtle base noise for color variation
    float n = texture(noise_texture, uv * noise_scale).r;
    vec3 noisy_base = base_color.rgb * (1.0 - 0.05) + vec3(n) * 0.05;

    // 2) crack overlay darkens where cracks exist
    float c = texture(crack_texture, uv * crack_scale).r;
    if (c > crack_threshold) {
        noisy_base *= 0.5; // darken cracks
    }

    ALBEDO = noisy_base;

    // 3) vary roughness with noise
    ROUGHNESS = mix(0.5, 0.8, n);

    // 4) add slight normal perturb for chipped/chunky look
    vec3 bump = texture(noise_texture, uv * (noise_scale * 2.0)).rgb * 2.0 - 1.0;
    NORMAL = normalize(NORMAL + bump * chip_strength);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
