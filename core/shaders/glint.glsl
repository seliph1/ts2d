// Uniforms to control the overlay texture and transparency level
uniform sampler2D overlay_texture;
uniform float zoom_factor = 7.0;
uniform float move_speed = 0.2;
uniform float transparency = 60.0; // Transparency level between 1 and 100
uniform float time = 0.0;

vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords ) {
    // Base texture color
    //vec4 base_color = texture(TEXTURE, UV);
    vec4 base_color = Texel(tex, texture_coords);
    vec2 uv = texture_coords;

    // Calculate offset for random movement based on time
    float offset_x = sin(time * move_speed * 1.3 + sin(time * move_speed * 0.7)) * 0.05;
    float offset_y = cos(time * move_speed * 0.9 + cos(time * move_speed * 0.5)) * 0.05;

    // Apply zoom and offset to UV coordinates for the overlay
    vec2 zoomed_uv = (uv - 0.5) / zoom_factor + 0.5 + vec2(offset_x, offset_y);

    // Sample the overlay texture
    vec4 overlay_color = texture(overlay_texture, zoomed_uv);

    // Convert transparency percentage to a 0.0 - 1.0 range
    float transparency_factor = clamp(transparency / 100.0, 0.0, 1.0);

    // Determine if the overlay should be applied per pixel
    float overlay_blend_factor = (base_color.a > 0.0) ? (transparency_factor * overlay_color.a) : 0.0;

    // Blend the overlay with the base texture using the computed blend factor
    vec4 texcolor = mix(base_color, overlay_color, overlay_blend_factor);

    return texcolor * color;
}
