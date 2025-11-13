shader_type spatial;
render_mode blend_add, cull_disabled;

uniform vec4 line_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);  // Cyan
uniform vec4 bg_color : source_color = vec4(0.0, 0.1, 0.1, 0.8);
uniform vec4 inactive_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);  // Color for non-display faces
uniform float line_thickness : hint_range(0.001, 0.05) = 0.01;
uniform float glow_intensity : hint_range(0.0, 5.0) = 2.0;
uniform bool show_grid = true;
uniform float grid_spacing : hint_range(0.05, 0.2) = 0.1;
uniform float grid_thickness : hint_range(0.001, 0.01) = 0.002;
uniform bool show_dots = true;
uniform float dot_size : hint_range(0.005, 0.03) = 0.015;
uniform int active_face : hint_enum("Front:0", "Back:1", "Right:2", "Left:3", "Top:4", "Bottom:5") = 0;

// Bell curve function (Gaussian distribution)
float bell_curve(float x, float center, float width, float height) {
	float normalized = (x - center) / width;
	return height * exp(-normalized * normalized * 4.0);
}

// Distance from point to line segment
float distance_to_curve(vec2 uv, float curve_value) {
	return abs(uv.y - curve_value);
}

// Check if we're on a grid line
bool on_grid(vec2 uv) {
	float x_grid = mod(uv.x, grid_spacing);
	float y_grid = mod(uv.y, grid_spacing);
	
	return (x_grid < grid_thickness || x_grid > grid_spacing - grid_thickness) ||
	       (y_grid < grid_thickness || y_grid > grid_spacing - grid_thickness);
}

// Detect which face we're on based on normal
int get_face_index(vec3 normal) {
	vec3 abs_normal = abs(normal);
	
	// Front face (Z+)
	if (abs_normal.z > 0.9 && normal.z > 0.0) return 0;
	// Back face (Z-)
	if (abs_normal.z > 0.9 && normal.z < 0.0) return 1;
	// Right face (X+)
	if (abs_normal.x > 0.9 && normal.x > 0.0) return 2;
	// Left face (X-)
	if (abs_normal.x > 0.9 && normal.x < 0.0) return 3;
	// Top face (Y+)
	if (abs_normal.y > 0.9 && normal.y > 0.0) return 4;
	// Bottom face (Y-)
	if (abs_normal.y > 0.9 && normal.y < 0.0) return 5;
	
	return -1;
}

void fragment() {
	// Check if we're on the active face
	int current_face = get_face_index(NORMAL);
	
	if (current_face != active_face) {
		// Not on the display face - show inactive color
		ALBEDO = inactive_color.rgb;
		ALPHA = inactive_color.a;
	} else {
		// We're on the display face - show the graph
		vec2 uv = UV;
		
		// Calculate the bell curve value at this x position
		float curve_height = bell_curve(uv.x, 0.5, 0.15, 0.8);
		
		// Center the curve vertically
		float curve_y = 0.5 - curve_height * 0.5;
		
		// Distance to the curve
		float dist_to_curve = distance_to_curve(uv, curve_y);
		
		// Check if we're on the curve line
		bool is_curve = dist_to_curve < line_thickness;
		
		// Grid
		bool is_grid = show_grid && on_grid(uv);
		
		// Sample points (dots) along the curve
		bool is_dot = false;
		if (show_dots) {
			// Place dots at regular intervals
			float dot_spacing = 0.05;
			float x_mod = mod(uv.x, dot_spacing);
			
			if (x_mod < dot_spacing * 0.1) {  // Near a sample point
				float sample_x = uv.x - x_mod;
				float sample_curve_height = bell_curve(sample_x, 0.5, 0.15, 0.8);
				float sample_y = 0.5 - sample_curve_height * 0.5;
				
				float dist_to_dot = distance(uv, vec2(sample_x, sample_y));
				is_dot = dist_to_dot < dot_size;
			}
		}
		
		// Combine elements
		if (is_curve || is_dot) {
			ALBEDO = line_color.rgb;
			EMISSION = line_color.rgb * glow_intensity;
			ALPHA = line_color.a;
		} else if (is_grid) {
			ALBEDO = line_color.rgb * 0.3;
			EMISSION = line_color.rgb * 0.5;
			ALPHA = 0.3;
		} else {
			ALBEDO = bg_color.rgb;
			ALPHA = bg_color.a;
		}
	}
}