#pragma language glsl3
/*

simple 2D shadows (with optional bleed-thru of the light thru walls)

no SDF or distance fields, just a value field for the world

*/

uniform vec4 iMouse = vec4(0.0);
uniform float iTime = 0.0;
vec2 iResolution = love_ScreenSize.xy;


vec2 mod289(vec2 x) {
	return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 mod289(vec3 x) {
	return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 mod289(vec4 x) {
	return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
	return mod289(((x*34.0) + 1.0 )*x);
}

vec4 taylorInvSqrt(vec4 r) {
	return 1.79284291400159 - 0.85373472095314 * r;
}

float snoise(float v) {return 0.0;}
vec2 snoise(vec2 v) {return vec2(0.0);}
vec3 snoise(vec3 v) {return vec3(0.0);}
vec4 snoise(vec4 v) {return vec4(0.0);}




vec4 world(vec2 uv) {
    // snoise defined in Common tab
    float existHere = snoise(uv * 5.0) > 0.0 ? 1.0 : 0.0;
    
    vec3 col = vec3(1.0, 1.0, 1.0) * existHere;

    return vec4(col,1.0);
}


vec4 effect( vec4 fragColor, Image tex, vec2 fragCoord, vec2 screenCoord )
{
    // normalized pixel coordinates (from 0 to 1)
    vec2 uv = screenCoord/iResolution.xy;

    // choose light source position
    vec2 sourcePos = vec2(sin(iTime), cos(iTime)) / 2.0 + 0.5;
    if (iMouse.z > 0.1) {
        sourcePos = iMouse.xy / iResolution.xy;
    }
    
    vec2 dir = normalize(uv - sourcePos);
    float dist = length(uv - sourcePos);
    
    float stepAmount = 0.001;
    float lightStrength = 0.5;
    float maxIter = 500.0; // adjust with light strength
    
    float curLightVal = 1.0 - dist / lightStrength;
    vec2 curPos = sourcePos;
    float curDist = 0.0;
    
    for (float i = 0.0; i < maxIter; i++) {
        curPos = sourcePos + dir * curDist;
        vec4 worldVal = world(curPos);
        if (curDist > dist) {
            break;
        }
        if (worldVal.x < 0.5) {
            // stop
            //curLightVal = 0.0;
           	//break;
            // or bleed thru
            //curLightVal -= 0.01;
            curLightVal -= iMouse.z > 0.0
                ? sin(iTime) * 0.02 + 0.02
            	: 0.02;
            if (curLightVal < 0.0) {
                break;
            }
        }
        //curPos += dir * stepAmount; // alternative way to calc curPos
        
        curDist += stepAmount;
    }
    
    float lightVal = max(curLightVal, 0.0);
    //float lightVal = curLightVal; // vignette around light source
    
    return vec4(
        (vec3(1.0*lightVal, 1.0, 1.0*lightVal) * lightVal) +
        (vec3(0.1, 0.2, 0.3) * world(uv).xyz)
    , 1.0);
}
