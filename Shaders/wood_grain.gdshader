shader_type spatial;

uniform vec3 base_light_color : source_color = vec3(0.90, 0.78, 0.65);
uniform vec3 base_dark_color : source_color = vec3(0.60, 0.45, 0.35);
uniform float grain_scale = 8.0;
uniform float wave_scale = 12.0;
uniform float random_scale = 5.0;
uniform float noise_scale = 0.05;
uniform float plank_color_variation = 0.2;

varying vec3 world_pos;

// Random noise function
vec2 random(vec2 pos) { 
	return fract(sin(vec2(
		dot(pos, vec2(12.9898,78.233)),
		dot(pos, vec2(-148.998,-65.233))
	)) * 43758.5453);
}

float value_noise(vec2 pos) {
	vec2 p = floor(pos);
	vec2 f = fract(pos);
	float v00 = random(p).x;
	float v10 = random(p + vec2(1.0, 0.0)).x;
	float v01 = random(p + vec2(0.0, 1.0)).x;
	float v11 = random(p + vec2(1.0, 1.0)).x;
	vec2 u = f*f*(3.0 - 2.0*f);
	return mix(mix(v00, v10, u.x), mix(v01, v11, u.x), u.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = world_pos.xy * 0.5;

	// Randomize each plank individually based on xz-position
	vec2 plank_id = floor(world_pos.xz * 2.0);
	float plank_rand = value_noise(plank_id) * plank_color_variation - plank_color_variation * 0.5;

	// Wood-wave appearance
	float wood_uv = uv.x + sin(uv.y * wave_scale + plank_rand);
	wood_uv += value_noise(uv * random_scale) * noise_scale;

	// Grain pattern generation
	float grain = mod(wood_uv * grain_scale, 1.0);

	vec3 wood_color = mix(base_light_color, base_dark_color, grain);
	wood_color += plank_rand;

	ALBEDO = wood_color;
}
