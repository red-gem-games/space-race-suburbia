shader_type spatial;
render_mode unshaded, blend_add, depth_draw_always;

uniform vec4 glow_color = vec4(0.2, 0.6, 1.0, 1.0); // Electric blue glow
uniform float glow_strength = 2.0;
uniform float outline_width = 1.0;
uniform float fresnel_power = 3.0;

void fragment() {
    vec3 normal_dir = normalize(NORMAL);
    vec3 view_dir = normalize(-VIEW);

    // Fresnel-like rim effect based on view angle
    float fresnel = pow(1.0 - dot(normal_dir, view_dir), fresnel_power);

    // Push edges outward visually
    float outline = fresnel * outline_width;

    // Final glow intensity
    vec3 final_color = glow_color.rgb * outline * glow_strength;

    ALBEDO = final_color;
    EMISSION = final_color;
    ALPHA = outline;
}
