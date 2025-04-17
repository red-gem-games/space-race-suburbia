shader_type spatial;
render_mode unshaded, cull_front, depth_draw_always, blend_premul_alpha;

uniform vec4 glow_color : source_color = vec4(0.0, 1.0, 0.0, 0.25); // default green
uniform float time_offset = 0.0;

void fragment() {
	float noise = fract(sin(dot(UV * TIME * 3.0 + time_offset, vec2(12.9898, 78.233))) * 43758.5453);
	float alpha_variation = mix(0.2, 0.4, noise);
	ALBEDO = glow_color.rgb;
	ALPHA = glow_color.a * alpha_variation;
}
