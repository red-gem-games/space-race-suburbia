shader_type spatial;
render_mode specular_schlick_ggx, depth_draw_opaque, cull_back;

uniform vec4 albedo = vec4(1.0, 1.0, 1.0, 1.0);
uniform float metallic : hint_range(0.0, 1.0) = 1.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.6;
uniform float ambient_occlusion : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    ALBEDO = albedo.rgb;
    METALLIC = metallic;
    ROUGHNESS = roughness;
    AO = ambient_occlusion;
}
