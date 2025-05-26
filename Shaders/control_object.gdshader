shader_type canvas_item;

uniform vec4 highlight_color = vec4(1.0, 0.0, 0.0, 1.0);
// how fast it ramps up from center→edge
uniform float falloff: hint_range(0.0,1.0) = 1.0;

void fragment() {
    // remap UV 0→1 into –1→1
    vec2 centered = UV * 2.0 - 1.0;
    // true circular distance from center
    float dist = length(centered);
    // ramp *up* from 0 at center to 1 at or beyond radius=1
    float strength = clamp(dist * falloff, 0.0, 1.0);
    // color alpha driven by strength
    COLOR = vec4(highlight_color.rgb, strength * highlight_color.a);
}
