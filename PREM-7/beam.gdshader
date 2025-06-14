shader_type spatial;

uniform vec3 beam_color : source_color = vec3(1.0, 1.0, 0.5); // warm yellow
uniform float fresnel_power = 2.0;
uniform float emission_strength : hint_range(0.0, 10.0) = 1.0;

void fragment() {
    vec3 normal_dir = normalize(NORMAL);
    vec3 view_dir = normalize(-VIEW);

    float fresnel = pow(1.0 - dot(normal_dir, view_dir), fresnel_power);

    ALBEDO = beam_color;
    EMISSION = beam_color * (emission_strength + fresnel * 0.5);
}

