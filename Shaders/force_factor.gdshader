shader_type spatial;
render_mode depth_draw_always, cull_front, blend_add;

uniform float fill_amount : hint_range(0.0, 1.0) = 0.25;
uniform vec4 fill_color : source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform vec4 empty_color : source_color = vec4(0, 0, 0, 1.0);
uniform float start_angle : hint_range(0.0, 6.283) = 1.5708; // 4.71239 = top (270 degrees, -90)
uniform bool clockwise = true;
uniform float glow_intensity : hint_range(0.0, 100.0) = 5.0;
uniform float smooth_transition : hint_range(0.0, 0.1) = 0;

void fragment() {
	// For a torus/ring CSG mesh, UV.x wraps around the ring (0 to 1 = full circle)
	// UV.y goes around the tube thickness
	
	float angle = UV.x * 6.283185307; // Convert UV.x (0-1) to angle (0-2π)
	
	// Adjust for start angle
	angle -= start_angle;
	
	// Normalize to 0-2π range
	while (angle < 0.0) {
		angle += 6.283185307;
	}
	while (angle > 6.283185307) {
		angle -= 6.283185307;
	}
	
	// Reverse direction if counter-clockwise
	if (!clockwise) {
		angle = 6.283185307 - angle;
	}
	
	// Calculate progress (0 to 1)
	float progress = angle / 6.283185307;
	
	// Determine if filled
	bool is_filled = progress <= fill_amount;
	
	// Smooth transition at the fill boundary
	float boundary_distance = abs(progress - fill_amount);
	float transition = smoothstep(smooth_transition, 0.0, boundary_distance);
	
	// Choose color
	vec4 color;
	if (is_filled) {
		color = fill_color;
	} else {
		color = empty_color;
	}
	
	// Apply smooth transition
	if (boundary_distance < smooth_transition) {
		color = mix(empty_color, fill_color, transition);
	}
	
	ALBEDO = color.rgb;
	ALPHA = color.a;
	
	// Optional glow/emission
	if (glow_intensity > 0.0 && is_filled) {
		EMISSION = fill_color.rgb * glow_intensity;
	}
}