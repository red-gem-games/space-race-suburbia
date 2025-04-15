shader_type spatial;

// The glow (emission) color—this will be updated from code.
uniform vec3 glow_color = vec3(0.0, 1.0, 0.0);
// Emission strength controls how bright the glow is.
uniform float emission_strength = 1.0;

void fragment() {
    // You can combine the object’s albedo with emission if you like.
    ALBEDO = vec3(0.1);  // A dark base color so the glow stands out.
    EMISSION = glow_color * emission_strength;
}


//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
