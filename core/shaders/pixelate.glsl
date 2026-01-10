uniform float time;
uniform vec4 mouse;

uniform float amount = 1.0;
vec2 screenSize = love_ScreenSize.xy;

vec4 effect(vec4 COLOR, Image TEXTURE, vec2 UV, vec2 SCREEN_UV) {
    vec2 grid_uv = UV;
    grid_uv.x -= mod(grid_uv.x, 1.0 / amount);
    grid_uv.y -= mod(grid_uv.y, 1.0 / amount);
    vec4 text = texture(TEXTURE, grid_uv);
    return text;
}