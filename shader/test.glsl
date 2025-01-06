const int   SAMPLES = 24;
const float DECAY   = 0.1;
const vec3  SHADOW_COL = vec3(0.0);

float rand(vec2 seed) { return fract(sin(dot(seed.xy ,vec2(12.9898, 78.233)))*43758.5453); }

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    
    vec4 texc = texture(iChannel0, uv);
    
    vec2 lightp = iMouse.xy/iResolution.xy;
    vec2 pc = (lightp-uv)*(1.0+(rand(uv+fract(iTime))*2.0-1.0)*0.1);
    
    float range = (sin(iTime*0.5)*0.5+0.5)*7.0;
    float power = (1.0+range)/float(SAMPLES);
    
    float shadoww = 0.0;
    for(int i = 0; i < SAMPLES; ++i)
    {
		shadoww += texture(iChannel0, uv+float(i)*DECAY/float(SAMPLES)*pc).a*power; 
    }
    
    float mask = 1.0-texc.a;
    vec3 col = mix(texc.rgb, SHADOW_COL, shadoww*mask);

    float light = max(1.0-length(uv-lightp), 0.0);
    col *= light;
    
    fragColor = vec4(col,1.0);
}