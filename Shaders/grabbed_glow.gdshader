//shader_type spatial;
//render_mode unshaded, cull_front, depth_draw_always, blend_premul_alpha;
//
//uniform vec4 glow_color : source_color = vec4(0.0, 1.0, 0.0, 0.5);
//uniform float time_offset = 0.5;
//
//uniform float fresnel_power = 0.5;
//
//// Power surge / distortion pulse
//uniform float surge_strength = 0.2;
//uniform float surge_frequency = 0.5;
//uniform float surge_thickness = 0.06;
//
//float surge_wave(vec2 uv, float offset) {
	//// Pulse wave oscillates between 0 and 1
	//float pulse = sin(TIME * surge_frequency + offset) * 0.5;
//
	//// Create a soft radial surge that grows outward from center
	//float radius = length(uv - vec2(0.5));
	//float ring = smoothstep(pulse - surge_thickness, pulse, radius) *
	             //(1.0 - smoothstep(pulse, pulse + surge_thickness, radius));
//
	//return ring;
//}
//
//void fragment() {
	//// Base color + Fresnel edge glow
	//vec3 base = glow_color.rgb;
	//float fresnel = pow(abs(dot(NORMAL, VIEW)), fresnel_power);
	//vec3 fresnel_glow = base * fresnel;
//
	//// Surge distortion
	//float surge = surge_wave(UV, time_offset);
	//vec3 surge_flash = vec3(surge_strength) * surge;
//
	//vec3 final_color = base + fresnel_glow + surge_flash;
	//float final_alpha = glow_color.a + surge * 0.2;
//
	//ALBEDO = final_color;
	//ALPHA = clamp(final_alpha, 0.0, 1.0);
//}
//







/*
	ゆらゆらシェーダー by あるる（きのもと 結衣）
	Yurayura Shader by Yui Kinomoto @arlez80

	MIT License
*/
shader_type spatial;
// render_mode;

uniform float speed = 0.6;
uniform float ring_scale = 4.4;
uniform float wave_scale = 8.454;
uniform float random_scale = 4.6;
uniform float noise_scale = 0.03;


vec3 hsv2rgb( float h, float s, float v )
{
	return (
		(
			clamp(
				abs( fract( h + vec3( 0.0, 2.0, 1.0 ) / 3.0 ) * 6.0 - 3.0 ) - 1.0
			,	0.0
			,	1.0
			) - 1.0
		) * s + 1.0
	) * v;
}

vec2 random( vec2 pos )
{
	return fract(
		sin(
			vec2(
				dot(pos, vec2(12.9898,78.233))
			,	dot(pos, vec2(-148.998,-65.233))
			)
		) * 43758.5453
	);
}

float value_noise( vec2 pos )
{
	vec2 p = floor( pos );
	vec2 f = fract( pos );

	float v00 = random( p + vec2( 0.0, 0.0 ) ).x;
	float v10 = random( p + vec2( 1.0, 0.0 ) ).x;
	float v01 = random( p + vec2( 0.0, 1.0 ) ).x;
	float v11 = random( p + vec2( 1.0, 1.0 ) ).x;

	vec2 u = f * f * ( 3.0 - 2.0 * f );

	return mix( mix( v00, v10, u.x ), mix( v01, v11, u.x ), u.y );
}

void fragment( )
{
	vec2 shift_uv = UV;
	shift_uv.x += value_noise( UV * random_scale + sin( TIME * speed ) );
	shift_uv.y += sin( cos( TIME ) * speed );
	float x = shift_uv.x + sin( shift_uv.y * wave_scale );
	float f = mod( x * ring_scale + random( UV ).x * noise_scale, 1.0 );

	ALBEDO = hsv2rgb( f, 1.0, 1.0 );
}
