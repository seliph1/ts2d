// fluence_hrc.glsl
// Sums and averages the radiance from all 4 rotated frustums.
// Applies 1-pixel shift offsets to avoid overlapping samples at cone boundaries,
// and converts the final averaged radiance back to sRGB space.

uniform vec2 fluence_extent;
uniform Image fluence_frustum0;
uniform Image fluence_frustum1;
uniform Image fluence_frustum2;
uniform Image fluence_frustum3;

#define SRGB(c) vec4(pow((c).rgb, vec3(1.0 / 2.2)), 1.0)

// Offsets coordinate by 1px into each frustum and rotates back to original orientation
vec4 textureRot2D(Image tex, vec2 coords, int frust) {
    vec2 pixel = vec2(1.0, 0.0) / fluence_extent;
    vec2 offset;
    
    // Explicit conditional compilation branches to avoid dynamic array indexing issues on strict GPU drivers
    if (frust == 0) {
        offset = vec2(coords + pixel.xy).xy;
    } else if (frust == 1) {
        offset = 1.0 - vec2(coords - pixel.yx).yx;
    } else if (frust == 2) {
        offset = 1.0 - vec2(coords - pixel.xy).xy;
    } else {
        offset = vec2(coords + pixel.yx).yx;
    }
    
    return Texel(tex, offset);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 radiance = vec4(0.0);
    
    // Accumulate radiance from each direction
    radiance += textureRot2D(fluence_frustum0, texture_coords, 0);
    radiance += textureRot2D(fluence_frustum1, texture_coords, 1);
    radiance += textureRot2D(fluence_frustum2, texture_coords, 2);
    radiance += textureRot2D(fluence_frustum3, texture_coords, 3);
    
    // Average contributions and apply gamma correction
    return SRGB((radiance / 4.0));
}
