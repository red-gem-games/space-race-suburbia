shader_type spatial;
render_mode unshaded;

uniform float wave_speed = 1.0;
uniform float wave_strength = 0.02;
uniform float wave_scale = 20.0;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec2 uv = SCREEN_UV;
    float time = TIME * wave_speed;

    // Sine-based offset distortion
    uv.y += sin(uv.x * wave_scale + time) * wave_strength;
    uv.x += cos(uv.y * wave_scale + time) * wave_strength;

    vec3 screen_color = textureLod(SCREEN_TEXTURE, uv, 0.0).rgb;
    ALBEDO = screen_color;
}

