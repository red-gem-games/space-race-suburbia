shader_type spatial;
render_mode unshaded, cull_front, depth_draw_always, blend_premul_alpha;

uniform vec4 glow_color : source_color = vec4(0.0, 1.0, 0.0, 0.5);
uniform float time_offset = 0.5;

uniform float fresnel_power = 0.5;

// Power surge / distortion pulse
uniform float surge_strength = 0.75;
uniform float surge_frequency = 1.0;
uniform float surge_thickness = 0.25;

float surge_wave(vec2 uv, float offset) {
	// Pulse wave oscillates between 0 and 1
	float pulse = sin(TIME * surge_frequency + offset) * 0.5;

	// Create a soft radial surge that grows outward from center
	float radius = length(uv - vec2(0.5));
	float ring = smoothstep(pulse - surge_thickness, pulse, radius) *
	             (1.0 - smoothstep(pulse, pulse + surge_thickness, radius));

	return ring;
}

void fragment() {
	// Base color + Fresnel edge glow
	vec3 base = glow_color.rgb;
	float fresnel = pow(abs(dot(NORMAL, VIEW)), fresnel_power);
	vec3 fresnel_glow = base * fresnel;

	// Surge distortion
	float surge = surge_wave(UV, time_offset);
	vec3 surge_flash = vec3(surge_strength) * surge;

	vec3 final_color = base + fresnel_glow + surge_flash;
	float final_alpha = glow_color.a + surge * 0.2;

	ALBEDO = final_color;
	ALPHA = clamp(final_alpha, 0.0, 1.0);
}
