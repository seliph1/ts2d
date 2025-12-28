uniform float waveAmount = 12.56;
uniform float waveSize = 0.05;
uniform float waveSpeed = 0.05;
uniform float x = 1.0;
uniform float y = 1.0;
uniform float time = 0.0;

vec4 effect (vec4 COLOR, Image TEXTURE, vec2 UV, vec2 SCREEN_UV) {
    vec2 pos = UV;
    float wavex = sin(pos.y * waveAmount + time * waveSpeed) * waveSize;
    float wavey = sin(pos.x * waveAmount + time * waveSpeed) * waveSize;
    vec2 offset = vec2(wavex * x, wavey * y);
    vec4 TEXTURE_COLOR = Texel(TEXTURE, pos + offset);

	return TEXTURE_COLOR;
}