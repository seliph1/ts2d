uniform float time;
uniform vec4 mouse;

uniform float width = 0.05;
uniform float t = 0.2;
uniform float aberration = 0.02;
uniform float speed = 1.0;
uniform float shading = 1.0;
uniform vec2 centre = vec2(0.0);

const float maxRadius = 0.25;

float getOffsetStrength(float t, vec2 dir) {
    vec2 aspect = vec2(1.0, love_ScreenSize.x/love_ScreenSize.y);
    float d = length(dir/aspect) - t * maxRadius;
    d *= 1.0 - smoothstep(0.0, width, abs(d));

    // Intro
    d *= smoothstep(0.0, 0.05, t);
    // Outro
    d *= 1.0 - smoothstep(0.0, 1.0, t);
    return d;
}

vec4 effect (vec4 COLOR, Image TEXTURE, vec2 UV, vec2 SCREEN_UV) {
    //vec2 dir = centre - UV;
    vec2 dir = mouse.xy / love_ScreenSize.xy - UV;

    float elapsed = fract( (t + time) * speed);
    //float d = getOffsetStrength(elapsed, dir);
    float rD = getOffsetStrength(elapsed, dir + aberration);
    float gD = getOffsetStrength(elapsed, dir);
    float bD = getOffsetStrength(elapsed, dir - aberration);

    dir = normalize(dir);

    //vec4 TEXTURE_COLOR = Texel(TEXTURE, UV + dir * d);
    float r = Texel(TEXTURE, UV + dir * rD).r;
    float g = Texel(TEXTURE, UV + dir * gD).g;
    float b = Texel(TEXTURE, UV + dir * bD).b;
    float a = Texel(TEXTURE, UV + dir * gD).a;

    vec4 final_color = vec4(r,g,b,a);
    final_color += gD * shading;

    return final_color * COLOR;
}