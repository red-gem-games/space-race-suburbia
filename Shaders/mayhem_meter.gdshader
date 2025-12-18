shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded, depth_prepass_alpha;

uniform float progress : hint_range(0.0, 0.5) = 0.5;  // 0.0 = empty, 1.0 = full
uniform vec4 fill_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);  // Red
uniform vec4 empty_color : source_color = vec4(0.5, 0.5, 0.5, 0.5);  // Gray
uniform float fill_opacity : hint_range(0.0, 1.0) = 0.9;  // Opacity of filled portion
uniform float empty_opacity : hint_range(0.0, 1.0) = 0.4;  // Opacity of empty portion

void fragment() {
	// UV.y goes from 0 (bottom) to 1 (top)
	bool is_filled = UV.y <= progress;
	
	vec4 color;
	float alpha;
	
	if (is_filled) {
		color = fill_color;
		alpha = fill_opacity;
	} else {
		color = empty_color;
		alpha = empty_opacity;
	}
	
	ALBEDO = color.rgb;
	ALPHA = alpha;
}