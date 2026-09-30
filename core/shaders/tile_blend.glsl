uniform Image tile;

vec4 effect(vec4 color, Image mask, vec2 texture_coords, vec2 screen_coords) {
    vec4 mask_color = Texel(mask, texture_coords);
    vec4 tile_color = Texel(tile, texture_coords);

    float alpha = (mask_color.r + mask_color.g + mask_color.b) / 3.0;
    tile_color.a *= alpha;

    return tile_color * color;
}
