uniform float time;
uniform vec4 mouse;

vec4 effect(vec4 COLOR, Image TEXTURE, vec2 UV, vec2 SCREEN_UV) {
    vec4 TEXTURE_COLOR = Texel(TEXTURE, UV);
    TEXTURE_COLOR = TEXTURE_COLOR;

    return TEXTURE_COLOR * COLOR;
}