shader_type canvas_item;

uniform float ring_thickness : hint_range(0.0, 0.5) = 0.045;
uniform float ring_radius : hint_range(0.0, 1.0) = 0.045;
uniform vec4 ring_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float smoothness : hint_range(0.0, 0.1) = 0.02;

void fragment() {
	// Convert to centered coordinates (-0.5 to 0.5)
	vec2 uv = UV - 0.5;
	
	// Calculate distance from center
	float dist = length(uv) * 2.0;
	
	// Create ring (inner and outer edge)
	float outer = smoothstep(ring_radius + smoothness, ring_radius, dist);
	float inner = smoothstep(ring_radius - ring_thickness, ring_radius - ring_thickness - smoothness, dist);
	
	float ring = outer - inner;
	
	COLOR = vec4(ring_color.rgb, ring * ring_color.a);
}