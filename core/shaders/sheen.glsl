uniform sampler2D noise_tex;
uniform float noise_scale = 2.0;
uniform float noise_speed = 0.5;

uniform vec4 tint_color = vec4(0.283, 0.423, 1.0, 1.0);
uniform float fresnel_strength = 2.0;
uniform float sheen_intensity = 1.5;
uniform float time = 0.0;

// Função hash simples para gerar pseudo-aleatoriedade
vec2 hash2(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)),
             dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453123);
}

// Fade (curva suave de Perlin)
float fade(float t){ return t * t * t * (t * (t * 6 - 15) + 10); }

// Perlin Noise 2D
float perlin(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    // Gradientes nos 4 cantos da célula
    vec2 g00 = normalize(hash2(i + vec2(0.0,0.0)) * 2.0 - 1.0);
    vec2 g10 = normalize(hash2(i + vec2(1.0,0.0)) * 2.0 - 1.0);
    vec2 g01 = normalize(hash2(i + vec2(0.0,1.0)) * 2.0 - 1.0);
    vec2 g11 = normalize(hash2(i + vec2(1.0,1.0)) * 2.0 - 1.0);

    // Vetores até o ponto
    vec2 d00 = (f - vec2(0.0,0.0));
    vec2 d10 = (f - vec2(1.0,0.0));
    vec2 d01 = (f - vec2(0.0,1.0));
    vec2 d11 = (f - vec2(1.0,1.0));

    // Produtos escalares
    float v00 = dot(g00, d00);
    float v10 = dot(g10, d10);
    float v01 = dot(g01, d01);
    float v11 = dot(g11, d11);

    // Interpolação suave
    vec2 u = vec2(fade(f.x), fade(f.y));
    
    return mix(
        mix(v00, v10, u.x),
        mix(v01, v11, u.x),
        u.y
    );
}

vec4 effect( vec4 color, Image SCREEN_TEXTURE, vec2 UV, vec2 SCREEN_UV ) {
    float TIME = time;
    vec2 uv = UV * noise_scale;
    uv += TIME * noise_speed;

    float noise = texture(noise_tex, uv).r;
    float fresnel = pow(1.0 - dot(NORMAL, VIEW), fresnel_strength);

    float magic_mask = fresnel * (0.5 + noise * 0.5);
    magic_mask *= 0.9 + sin(TIME * 2.0) * 0.1;

    ALBEDO = tint_color.rgb * magic_mask * sheen_intensity;
    ALPHA = magic_mask;

    return 
}