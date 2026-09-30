// @default waveAmount = 12.56
// @default waveSize = 0.05
// @default waveSpeed = 0.05
// @default x = 1.0
// @default y = 1.0
// @default time = 0.0

uniform float waveAmount;
uniform float waveSize;
uniform float waveSpeed;
uniform float x;
uniform float y;
uniform float time;

vec4 effect (vec4 COLOR, Image TEXTURE, vec2 UV, vec2 SCREEN_UV) {
    vec2 pos = UV;
    float wavex = sin(pos.y * waveAmount + time * waveSpeed) * waveSize;
    float wavey = sin(pos.x * waveAmount + time * waveSpeed) * waveSize;
    vec2 offset = vec2(wavex * x, wavey * y);
    vec4 TEXTURE_COLOR = Texel(TEXTURE, pos + offset);

	return TEXTURE_COLOR;
}