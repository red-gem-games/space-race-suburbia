shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 edge_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform float edge_thickness : hint_range(0.0, 0.1) = 0.07;

void fragment() {
	// Calculate distance from edges using UV coordinates
	float dist_x = min(UV.x, 1.0 - UV.x);
	float dist_y = min(UV.y, 1.0 - UV.y);
	float dist = min(dist_x, dist_y);

	// Only show edges
	if (dist > edge_thickness) {
		discard;
	}

	ALBEDO = edge_color.rgb;
	ALPHA = edge_color.a;
}