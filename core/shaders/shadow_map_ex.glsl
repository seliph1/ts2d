uniform Image heightmap;

// 640 units sun height
// This ensures our uniform shadows scale with pixel size.
const vec3 sunPos = vec3( vec2(0.0, 0.0), 640.0);
uniform float steps = 32.0;
uniform float shadowBrightness = 0.5;
uniform float shadowLength = 32.0;
uniform float direction = 45.0;
uniform float mode = 1.0;
uniform float stepFactor = 0.05;
uniform float distanceFactor = 0.05;
vec3 pix = vec3( 1/love_ScreenSize.x, 1/love_ScreenSize.y, 0);

uniform float offset[3] = float[](0.0, 1.3846153846, 3.2307692308);
uniform float weight[3] = float[](0.2270270270, 0.3162162162, 0.0702702703);

float getHeight(vec2 UV) {
    vec4 color = Texel(heightmap, UV);
    return color.r;
}

float logEase(float t) {
    return log(1.0 + 9.0 * t) / log(10.0);
}

float expEase(float t, float k)
{
    // k > 0 controla o quão agressivo é o crescimento
    // k = 3..6 costuma ser bom
    return (exp(k * t) - 1.0) / (exp(k) - 1.0);
}

vec3 getOcclusion(vec2 UV) {
    float minStepSize = min(pix.x, pix.y);
    float angle = radians(direction);
    float height0 = getHeight(UV);

    vec3 p = vec3(UV, height0);
    vec3 sunDir = sunPos - vec3(vec2(sin(angle), cos(angle)) * shadowLength, 0.0);
    vec3 stepDir = normalize(sunDir) / steps;
    vec3 groundPos = p;
    

    float inShadow = 0.0;
    float dist = 0.0 * distanceFactor;

    for (float i = 0.0; i < steps; i++) {
        float j = steps - i;
        float height = getHeight(p.xy);
        p += stepDir;
        //dist = smoothstep(1.0, groundPos.z, p.z);
        //dist = smoothstep(0.0, 1.0, i/steps);
        //dist = 1.0 - (p.z - height0);
        dist = smoothstep(0.8, 1.0, i/steps);
        
        if (height > p.z) {
            // Ray got inside a terrain while travelling to sun.
            // So this pixel must be inside a shadow
            inShadow = 1.0;
            // Calculate distance between floor and sky (max height limit).
            break;
        };

        if (p.z > 1.0) {
            // Ray got over the height limit
            // This pixel isn't over a shadow, so no point in calculating further.
            dist = 0.0;
            break;
        };
    }
    return vec3(inShadow, dist, height0);
}

vec3 easeOcclusion(vec2 UV) {
	vec2 size = textureSize(heightmap, 0);
	vec3 occlusion = getOcclusion(UV);

	for (int i=1; i<3; i++) {
        occlusion += getOcclusion(UV + offset[i]/size) * weight[i];
        occlusion += getOcclusion(UV - offset[i]/size) * weight[i];
	}
	return occlusion;
}

vec4 effect(vec4 COLOR, Image TEXTURE, vec2 UV, vec2 UV2)
{
    vec3 occlusion = getOcclusion(UV);
    //vec3 occlusion = easeOcclusion(UV);

    float shadow = occlusion.x;
    float dist = occlusion.y;
    float height = occlusion.z;

    if (mode < 0.3) {
        return vec4( vec3(height), 1.0 );
    };
    if (mode >= 0.3 && mode < 0.6) {
        return vec4( vec3(shadow), 1.0 );
    };
    if (mode >= 0.6 && mode < 0.9) {
        return vec4( vec3(dist), 1.0 );
    };
    //dist = expEase( dist, 5.0 );
    shadow = step(0.001, shadow);

    vec3 shadow_color = COLOR.rgb;
    float shadow_fadeout = (shadow - dist) * shadowBrightness;


    return vec4( shadow_color, shadow_fadeout );
}