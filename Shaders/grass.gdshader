shader_type spatial;
render_mode unshaded;

// How many squares you see across your UV space.
// Increase this to get more (smaller) squares.
uniform float base_scale = 30.0;

// The size range for each square’s fill area inside its cell.
// Lower min_fill or max_fill for more “border,” or raise them for fuller squares.
uniform float min_fill = 0.6;
uniform float max_fill = 0.9;

// Border color around each square.
// If you don't want borders at all, make this close to your square colors.
uniform vec4 border_color = vec4(0.2, 0.3, 0.2, 1.0);

// Six more-muted greens. Tweak these to your liking.
uniform vec4 color0 = vec4(0.3, .475, .1, 1.0); // #456B42
uniform vec4 color1 = vec4(0.25, .45, .1, 1.0); // #4C7347
uniform vec4 color2 = vec4(0.25, 0.45, .12, 1.0); // #547A4C
uniform vec4 color3 = vec4(0.2, .4, .1, 1.0); // #598050
uniform vec4 color4 = vec4(0.2, .45, .1, 1.0); // #5F874F
uniform vec4 color5 = vec4(0.274, .45, .12, 1.0); // #668D5C


// Returns one of the six color uniforms.
vec4 getColor(int index) {
    if (index == 0) return color0;
    if (index == 1) return color1;
    if (index == 2) return color2;
    if (index == 3) return color3;
    if (index == 4) return color4;
    return color5;
}

void fragment() {
    // Scale UVs to define a grid of squares.
    vec2 grid_uv = UV * base_scale;
    vec2 cell = floor(grid_uv);
    vec2 f = fract(grid_uv);

    // Random value for fill factor.
    float rnd = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
    float fill = mix(min_fill, max_fill, rnd);

    // Random value to pick one of six colors.
    float color_rnd = fract(sin(dot(cell, vec2(93.9898, 67.345))) * 43758.5453);
    int idx = int(floor(color_rnd * 6.0));
    vec4 cell_color = getColor(idx);

    // If inside the fill region, use the cell color; otherwise, border color.
    if (f.x < fill && f.y < fill) {
        ALBEDO = cell_color.rgb;
    } else {
        ALBEDO = border_color.rgb;
    }
}
