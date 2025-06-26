shader_type spatial;

uniform float fresnel_power = 2.0;
uniform float emission_strength = 5.0;

// Converts HSV to RGB
vec3 hsv2rgb(float h, float s, float v) {
    float c = v * s;
    float x = c * (1.0 - abs(mod(h / 60.0, 2.0) - 1.0));
    float m = v - c;
    vec3 rgb;

    if (h < 60.0)      rgb = vec3(c, x, 0.0);
    else if (h < 120.0) rgb = vec3(x, c, 0.0);
    else if (h < 180.0) rgb = vec3(0.0, c, x);
    else if (h < 240.0) rgb = vec3(0.0, x, c);
    else if (h < 300.0) rgb = vec3(x, 0.0, c);
    else               rgb = vec3(c, 0.0, x);

    return rgb + vec3(m);
}

void fragment() {
    // Loop hue: wraps every 20 seconds
    float hue = mod(TIME * (360.0 / 3.0), 360.0); // 360 degrees in 20 seconds
    float saturation = 0.62;
    float value = 1.0;

    vec3 beam_color = hsv2rgb(hue, saturation, value);

    vec3 normal_dir = normalize(NORMAL);
    vec3 view_dir = normalize(-VIEW);
    float fresnel = pow(1.0 - dot(normal_dir, view_dir), fresnel_power);

    ALBEDO = beam_color;
    EMISSION = beam_color * (emission_strength + fresnel * 0.5);
}

