shader_type spatial;

uniform float wave_strength = 0.01;
uniform float wave_speed = 2.0;
uniform float wobble_density = 6.0;

void vertex() {
    float wave = sin(VERTEX.y * wobble_density + TIME * wave_speed) * wave_strength;
    VERTEX.x += wave;
    VERTEX.z += wave;
	VERTEX.y += wave;
}
