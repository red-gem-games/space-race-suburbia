shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_back, unshaded;

// Main color and intensity
uniform vec4 forcefield_color : source_color = vec4(0.0, 1.0, 0.3, 1.0);
uniform float emission_strength : hint_range(0.0, 10.0) = 3.0;

// Fresnel effect (edge glow)
uniform float fresnel_power : hint_range(0.1, 10.0) = 3.0;
uniform float fresnel_intensity : hint_range(0.0, 5.0) = 1.5;

// Intersection glow (where forcefield touches objects)
uniform float intersection_thickness : hint_range(0.0, 2.0) = 0.3;
uniform float intersection_intensity : hint_range(0.0, 10.0) = 5.0;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

// Animation
uniform float pulse_speed : hint_range(0.0, 5.0) = 0.5;
uniform float pulse_intensity : hint_range(0.0, 1.0) = 0.25;

// Scanlines/patterns
uniform float scanline_speed : hint_range(0.0, 2.0) = 0.5;
uniform float scanline_scale : hint_range(1.0, 50.0) = 20.0;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	// Get view direction for fresnel
	vec3 view_dir = normalize(VIEW);
	vec3 normal = normalize(NORMAL);
	
	// Fresnel effect (edges glow more than center)
	float fresnel = pow(1.0 - abs(dot(view_dir, normal)), fresnel_power);
	fresnel *= fresnel_intensity;
	
	// Pulsing effect over time
	float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
	pulse = mix(1.0, pulse, pulse_intensity);
	
	// Scrolling scanlines
	float scanlines = sin((UV.y + TIME * scanline_speed) * scanline_scale);
	scanlines = scanlines * 0.5 + 0.5;
	scanlines = mix(1.0, scanlines, scanline_intensity);
	
	// Get depth for intersection glow
	float depth = texture(depth_texture, SCREEN_UV).r;
	vec4 world_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	world_pos.xyz /= world_pos.w;
	
	float depth_diff = abs(world_pos.z - VERTEX.z);
	float intersection = 1.0 - smoothstep(0.0, intersection_thickness, depth_diff);
	intersection *= intersection_intensity;
	
	// Combine all effects
	float final_intensity = fresnel * pulse * scanlines;
	final_intensity += intersection;
	final_intensity *= emission_strength;
	
	// Apply color
	vec3 final_color = forcefield_color.rgb * final_intensity;
	
	// Alpha based on overall intensity (more glow = more visible)
	float alpha = clamp(final_intensity * 0.5, 0.0, 1.0);
	
	ALBEDO = final_color;
	EMISSION = final_color;
	ALPHA = alpha;
}
