shader_type spatial;

render_mode blend_mix, depth_test_disabled;

uniform vec4 glow_color : source_color = vec4(0.0, 0.5, 1.0, 1.0);
uniform vec4 pulse_color : source_color = vec4(0.25, 1.0, 0.25, 1.0);
uniform float speed : hint_range(0.1, 10.0) = 5.0;
uniform float scale : hint_range(0.1, 10.0) = 8.5;
uniform float distortion : hint_range(0.01, 5.0) = 0.5;
uniform float shield_power : hint_range(0.0, 1.0) = 0.1;
uniform float rim_power : hint_range(0.0, 5.0) = 5.0;
uniform float pulse_frequency : hint_range(0.1, 10.0) = 1.0;

float noise(vec3 p) {
    return fract(sin(dot(p, vec3(12.9898, 78.233, 45.5432))) * 12.5453);
}

float fbm(vec3 p) {
    float value = 1.0;
    float amplitude = 0.5;
    float frequency = 5.0;
    for (int i = 0; i < 5; i++) {
        value += amplitude * noise(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return value;
}

void vertex() {
    float displacement = fbm(VERTEX * scale + vec3(0.0, 0.0, TIME * speed)) * distortion;
    VERTEX += NORMAL * displacement * 0.1;
}

void fragment() {
    vec3 view_dir = normalize(VIEW);
    vec3 normal = normalize(NORMAL);

    // Fresnel effect for shield rim
    float fresnel = pow(1.75 - dot(normal, view_dir), rim_power);

    // Noise-based distortion
    vec3 noise_pos = VERTEX * scale + vec3(0.0, 0.0, TIME * speed);
    float noise_val = fbm(noise_pos);

    // Pulsating effect
    float pulse = (sin(TIME * pulse_frequency) + 1.0) * 0.5;

    // Combine effects
    float shield_intensity = mix(shield_power, 1.0, fresnel);
    shield_intensity *= mix(0.8, 1.2, noise_val);
    shield_intensity *= mix(0.4, 1.0, pulse);

    // Color mixing
    vec4 final_color = mix(glow_color, glow_color, pulse * 0.5);
    final_color.rgb *= shield_intensity;

    // material properties
    ALBEDO = final_color.rgb;
    EMISSION = final_color.rgb * shield_intensity * 2.0;
    ALPHA = clamp(shield_intensity * 1.0, 0.0, 1.0);
    ROUGHNESS = 0.5;
    METALLIC = 0.2;

    vec3 normal_distortion = vec3(noise_val, noise_val, 1.0) * 0.1;
    NORMAL_MAP = normalize(mix(NORMAL, normal_distortion, 0.5));
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
