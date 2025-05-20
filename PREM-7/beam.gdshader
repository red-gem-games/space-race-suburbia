shader_type spatial;

uniform float curve_strength = 1.0;
uniform float beam_length = 5.0;

void vertex() {
    // Normalize z (0 to 1 along beam)
    float t = VERTEX.z / beam_length;

    // Basic parabolic bend: like a beam that arcs downward
    VERTEX.y -= pow(t, 2.0) * curve_strength;

    // Optional: pinch or scale based on distance
    // VERTEX.x *= mix(1.0, 0.5, t);
}


//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
