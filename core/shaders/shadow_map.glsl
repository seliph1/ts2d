#pragma language glsl3
// Love2d variables
uniform vec2 camera = vec2(0.0);
uniform vec4 mouse = vec4(0.0);
uniform Image heightmap;
uniform Image overlay;

//////////////////////////////////////
// Uniforms                         //
//////////////////////////////////////

uniform float steps = 32.0;
uniform float maxSteps = 32.0;
uniform float shadowStrength = 0.6;
uniform float shadowLength = 32.0;
uniform float direction = 225.0;
uniform float mode = 1.0;
uniform float distanceFactor = 0.9;
uniform float blur = 1.0;

uniform int numOccluders;
uniform vec4 occluders[32]; // [i] = vec4(worldX, worldY, radius, height)

uniform float vx, vy, v1, v2;

//////////////////////////////////////
// Constants                        //
//////////////////////////////////////
const float TILE_SIZE = 32.0;


float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Samples height only from the map / heightmap texture
float getTerrainHeight(vec2 mapPos) {
    vec4 color = Texel(heightmap, mapPos);
    if ( any(lessThan(mapPos, vec2(0.0))) || any(greaterThan(mapPos, vec2(1.0))) ) {
        color.r = 0.0;
    }
    return min(color.r, 1.0);
}

// Samples height from terrain and dynamic occluders (players)
float getHeight(vec2 mapPos, vec2 pixelsToMap) {
    float h = getTerrainHeight(mapPos);

    if (numOccluders > 0) {
        vec2 worldPos = mapPos * pixelsToMap;
        for (int i = 0; i < numOccluders; i++) {
            vec4 occ = occluders[i];
            float dx = abs(worldPos.x - occ.x);
            if (dx > occ.z) continue;
            float dy = abs(worldPos.y - occ.y);
            if (dy > occ.z) continue;

            float d2 = dx * dx + dy * dy;
            float r2 = occ.z * occ.z;
            if (d2 < r2) {
                float circleHeight = occ.w * sqrt(1.0 - d2 / r2);
                h = max(h, circleHeight);
            }
        }
    }

    return h;
}

vec3 getOcclusion(vec2 UV, vec2 SCREEN_UV) {
    // Get the map size
    vec2 mapSize = vec2( textureSize(heightmap, 0) );

    // Get the viewport size
    vec2 screenSize = love_ScreenSize.xy;

    // Conversion factor: screen pixels > map space
    vec2 pixelsToMap = (mapSize * TILE_SIZE);

    // Screen space position in world pixels
    vec2 screenCenter = screenSize * 0.5;
    vec2 worldPos = (SCREEN_UV + camera - screenCenter);
    vec2 mapPos = worldPos / pixelsToMap;

    // Base ground height from terrain
    float baseHeight = getTerrainHeight(mapPos);

    // If current pixel is directly underneath a dynamic occluder (contact shadow),
    // fill the shadow completely (cheia) without holes
    if (numOccluders > 0) {
        for (int i = 0; i < numOccluders; i++) {
            vec4 occ = occluders[i];
            if (distance(worldPos, occ.xy) < occ.z) {
                return vec3(1.0, 0.0, baseHeight);
            }
        }
    }

    // Transform degrees to radians
    float direction = radians(direction);

    // Calculate angle from radians (0~1)
    vec2 ray2D = normalize(vec2(sin(direction), cos(direction))) / mapSize;

    // Create position vector at step 0, starting at terrain level
    vec3 position = vec3(mapPos, baseHeight);

    // Calculate the step size of sample
    vec3 stepDir = normalize( vec3(ray2D * shadowLength, 32.0) ) / maxSteps;

    // Create control variables:
    // We are in shadow if shadow == 1.0;
    float shadow = 0.0;
    // Dist = Distance travelled by vector p
    float dist = 1.0;
    // Height in the current step
    float height = 0.0;
    float highest = 0.0;

    // Iterate through steps
    for (float i = 0.0; i < steps; i++) {
        // Increment vector p by step size
        position += stepDir;

        // Get the height on the current step
        height = getHeight(position.xy, pixelsToMap);

        // If current height is bigger than vector height, then
        if (height > position.z) {
            // Ray got inside an obstacle while travelling to sun.
            // So this pixel must be inside a shadow
            shadow = 1.0;

            if (highest < height) {
                highest = height;
                // Also calculate the distance of shadow base to ceiling
                // To emulate soft shadows at the border
                float factor = (1.0) / height * blur;
                float falloff = length(vec3(position.xyz) - vec3( position.xy, 0.0) ) * factor;

                dist = min(dist, falloff);
            }
        };

        // If height is higher than the sky (1.0)
        // Ray got over the height limit
        if (position.z > 1.0) break;
    }

    // Make threshold to where the shadow softness should begin
    dist = smoothstep(distanceFactor, 1.0, dist);

    // If there is no shadow at this pixel, dist should not subtract or show white in debug
    if (shadow < 0.5) {
        dist = 0.0;
    }

    // Return the control variables
    return vec3(shadow, dist, baseHeight);
}

vec4 getShadow(vec4 COLOR, vec2 UV, vec2 SCREEN_UV) {
    // Calculated occlusion with position normalized
    vec3 occlusion = getOcclusion( UV, SCREEN_UV );
    
    // Get the control variables
    float shadow = occlusion.x;
    float dist = occlusion.y;
    float height = occlusion.z;

    // Debug
    if (mode < 0.2) {
        return vec4( 1.0 );
    }
    if (mode >= 0.2 && mode < 0.4) {
        return vec4( vec3(height), 1.0 );
    };
    if (mode >= 0.4 && mode < 0.6) {
        return vec4( vec3(shadow), 1.0 );
    };
    if (mode >= 0.6 && mode < 0.8) {
        return vec4( vec3(dist), 1.0 );
    };

    // Get the current color from external buffer
    vec3 shadow_color = COLOR.rgb;

    // Calculate alpha base on shadow strength, clamping negative values
    float shadow_fadeout = max(0.0, shadow - dist) * shadowStrength;

    // Return the final result
    return vec4(vec3( shadow_color ), shadow_fadeout);
}


vec4 effect(vec4 COLOR, Image TEXTURE, vec2 UV, vec2 SCREEN_UV) {
    vec4 shadowColor = getShadow(COLOR, UV, SCREEN_UV);

    return shadowColor;
}