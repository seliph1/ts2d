// @default lineBrightness = 0.1
// @default lines = 2.0

uniform float lineBrightness;
uniform float lines;

vec4 effect(vec4 COLOR, Image TEXTURE, vec2 UV, vec2 SCREEN_UV) {
	vec4 TEXTURE_COLOR = Texel(TEXTURE, UV);
    vec2 SCREEN_SIZE = love_ScreenSize.xy;

    UV = floor(UV * SCREEN_SIZE/lines); 
    float scanline = mod( UV.y, 2.0) * lineBrightness;
    TEXTURE_COLOR.rgb -= vec3(scanline);

    return TEXTURE_COLOR;
}
