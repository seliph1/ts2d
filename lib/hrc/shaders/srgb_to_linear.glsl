// srgb_to_linear.glsl
// Converts sRGB colors to Linear space for physical blending calculations.

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 tex_color = Texel(texture, texture_coords);
    return pow(tex_color, vec4(2.2));
}
