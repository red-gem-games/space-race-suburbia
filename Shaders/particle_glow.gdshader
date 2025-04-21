// Shader (keep it simple now)
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_add;

uniform vec4 glow_color : source_color = vec4(0.0, 1.0, 0.0, 0.5);
uniform float pulse_speed = 2.0;
uniform float glow_intensity = 1.5;

void fragment() {
    float pulse = sin(TIME * pulse_speed + UV.x * 10.0 + UV.y * 10.0) * 0.5 + 0.5;
    ALBEDO = glow_color.rgb * glow_intensity;
    ALPHA = glow_color.a * pulse;
    EMISSION = glow_color.rgb * pulse * glow_intensity;
}
