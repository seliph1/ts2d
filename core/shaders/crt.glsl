// @default elapsed = 10.0
// @default offset = 0.001

uniform float elapsed;
uniform float offset;

vec2 radialDistortion(vec2 coord, float dist) {
  vec2 cc = coord - 0.5;
  dist = dot(cc, cc) * dist + cos(elapsed * 0.3) * 0.01;
  return (coord + cc * (1.0 + dist) * dist);
}

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 pc) {
    vec2 tcr = radialDistortion(tc, 0.24)  + vec2(offset, 0.0);
    vec2 tcg = radialDistortion(tc, 0.20);
    vec2 tcb = radialDistortion(tc, 0.18) - vec2(offset, 0.0);
    vec4 res = vec4(Texel(tex, tcr).r, Texel(tex, tcg).g, Texel(tex, tcb).b, 1.0)
        - cos(tcg.y * 128.0 * 3.142 * 2.0) * 0.03
        - sin(tcg.x * 128.0 * 3.142 * 2.0) * 0.03;
    return res * Texel(tex, tcg).a;
}