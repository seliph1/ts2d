// Love2d variables
uniform vec2 camera = vec2(0.0);
uniform vec4 mouse = vec4(0.0);
uniform Image heightmap;

//////////////////////////////////////
// Uniforms                         //
//////////////////////////////////////

uniform float steps = 32.0;
uniform float maxSteps = 32.0;
uniform float shadowStrength = 0.8;
uniform float shadowLength = 22.0;
uniform float direction = 45.0;
uniform float mode = 1.0;
uniform float distanceFactor = 0.8;
uniform float blur = 1.0;

uniform float v1 = 1.0;
uniform float v2 = 1.0;

//////////////////////////////////////
// Constants                        //
//////////////////////////////////////
const float TILE_SIZE = 32.0;


float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float getHeight(vec2 UV) {
    // Get the texel from heightmap texture
    vec4 color = Texel(heightmap, UV);
    // If it's out of bounds, then treat it as 0.0
    if ( any(lessThan(UV, vec2(0.0))) || any(greaterThan(UV, vec2(1.0))) ) {
        color.r = 0.0;
    }

    // Return current height (on red channel)
    // TODO:
    //    add other kind of info on the remaining channels.
    return color.r;
}

vec3 getOcclusion(vec2 UV, vec2 size) {
    // Transform degrees to radians
    float direction = radians(direction);

    // Calculate angle from radians (0~1)
    vec2 ray2D = normalize(vec2(sin(direction), cos(direction))) / size;

    // Calculate base height on this position
    float baseHeight = getHeight(UV);

    // Create position vector at step 0, including ground.
    vec3 position = vec3(UV, baseHeight);

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
        height = getHeight(position.xy);

        // If current height is bigger than vector height, then
        if (height > position.z) {
            // Ray got inside a terrain while travelling to sun.
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

    // Return the control variables
    return vec3(shadow, dist, baseHeight);
}

vec4 getShadow(vec4 COLOR, vec2 UV, vec2 SCREEN_UV) {
    // Get the map size
    vec2 mapSize = vec2( textureSize(heightmap, 0) );

    // Get the viewport size
    vec2 screenSize = love_ScreenSize.xy;

    // Conversion factor: screen pixels > map space
    vec2 pixelsToMap = (mapSize * TILE_SIZE);

    // Screen space position
    vec2 screenCenter = screenSize * 0.5;
    vec2 mapPos = (SCREEN_UV + camera - screenCenter) / pixelsToMap;

    // Calculated occlusion with position normalized
    vec3 occlusion = getOcclusion( mapPos, mapSize );


    // Get the control variables
    float shadow = occlusion.x;
    float dist = occlusion.y;
    float height = occlusion.z;

    // Debug
    if (mode < 0.25) {
        return vec4( vec3(height), 1.0 );
    };
    if (mode >= 0.25 && mode < 0.5) {
        return vec4( vec3(shadow), 1.0 );
    };
    if (mode >= 0.5 && mode < 0.75) {
        return vec4( vec3(dist), 1.0 );
    };

    // Get the current color from external buffer
    vec3 shadow_color = COLOR.rgb;

    // Calculate alpha base on shadow strength
    float shadow_fadeout = (shadow - dist) * shadowStrength;

    // Return the final result
    return vec4(vec3( shadow_color ), shadow_fadeout);
}


vec4 effect(vec4 COLOR, Image TEXTURE, vec2 UV, vec2 SCREEN_UV) {
    vec4 shadowColor = getShadow(COLOR, UV, SCREEN_UV);

    return shadowColor;
}