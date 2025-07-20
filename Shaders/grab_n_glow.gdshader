shader_type spatial;
render_mode blend_mul, cull_disabled, depth_draw_always;

uniform vec3 albedo = vec3(0.0, 0.0, 0.0);
uniform vec3 emission_col = vec3(0.9, 0.25, 0.025);
uniform float emission_str = 8.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = albedo;
	EMISSION = emission_col * emission_str;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}

