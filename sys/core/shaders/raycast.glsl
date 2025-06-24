//#pragma language glsl3
#define EPSILON 0.001
#define MAP_LEN 16

uniform vec4 iMouse = vec4(0.0);
uniform float iTime = 0.0;
vec2 iResolution = love_ScreenSize.xy;


int[MAP_LEN*MAP_LEN] map = int[](
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,1,1,0,1,1,0,1,1,1,1,0,1,1,1,1,
    1,1,0,0,0,0,0,0,0,0,0,0,0,0,1,1,
    1,1,0,0,0,0,0,0,0,0,1,0,0,0,1,1,
    1,1,0,0,1,0,0,0,0,0,0,1,0,0,0,1,
    1,0,0,0,0,1,0,0,0,0,0,0,0,0,1,1,
    0,0,0,0,0,0,1,0,0,0,0,0,0,0,1,1,
    0,0,1,0,0,0,0,0,0,1,1,0,0,0,1,1,
    0,0,1,1,0,0,0,0,0,1,0,0,0,0,1,1,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
    0,0,0,0,0,0,0,1,1,1,0,0,0,0,1,1,
    0,0,0,0,0,0,1,1,1,0,0,0,0,0,1,1,
    0,1,0,0,0,0,0,1,1,0,0,0,0,0,1,1,
    0,1,1,0,1,1,1,1,1,0,1,1,1,0,0,1,
    0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
);

float round(float n) {
	return floor(n + .5);
}


// Get wall type (only 0 or 1 for now)
int getMap(int x, int y)
{
    if(x < 0 || x >= MAP_LEN || y < 0 || y >= MAP_LEN)
    {
        return 1;
    }
        
    int index = x + y * 16;
    return map[index];
}

// From normalized uvs to "world space"
void translateCoordsToWorld(inout vec2 coords)
{
    coords.y = 1.0 - coords.y;
    coords.x -= 0.25;
    coords.x *= iResolution.x / iResolution.y;
    coords *= float(MAP_LEN);
}

vec4 effect( vec4 fragColor, Image tex, vec2 fragCoord, vec2 screenCoord )
{
    // UVs
    vec2 uv = screenCoord/iResolution.xy;
    translateCoordsToWorld(uv);
    
    // Light position
    vec2 lightPos = vec2(8.5, 8.5);
    vec3 mousePos = iMouse.xyz / vec3(iResolution.xy, 1.0);
    
    if(mousePos.x > 0.0 && mousePos.y > 0.0)
    {
        translateCoordsToWorld(mousePos.xy);
        lightPos = mousePos.xy;
    }
    
    vec2 rayDir = uv - lightPos;
    float directionAngle = atan(rayDir.y, rayDir.x);
    
    float d = 100.0;
    vec3 col = vec3(0.0f);
    
    if(getMap(int(uv.x), int(uv.y)) == 0)
    {
        // Vertical
        if(rayDir.y != 0.0)
        {
            // Step lengths
            float stepX = sign(rayDir.y) / tan(directionAngle);
            float stepY = sign(rayDir.y);

            // Initial intersection
            vec2 p = vec2(0.0, round(lightPos.y + sign(rayDir.y) * 0.5));
            p.x = lightPos.x + -(lightPos.y - p.y) / tan(directionAngle);

            // March
            for(int i = 0; i < 16; i++)
            {
                // Test the tiles sharing an edge
                int testX = int(p.x);
                int testY1 = int(p.y + 0.5);
                int testY2 = int(p.y - 0.5);
                if(map[testX + testY1 * 16] + map[testX + testY2 * 16] <= 0)
                {
                    p += vec2(stepX, stepY);
                }
                else
                    break;
            }

            d = min(length(lightPos - p), d);
        }

        // Horizontal
        if(rayDir.x != 0.0)
        {
            // Step lengths
            float stepX = sign(rayDir.x);
            float stepY = sign(rayDir.x) * tan(directionAngle);

            // Initial intersection
            vec2 p = vec2(round(lightPos.x + sign(rayDir.x) * 0.5), 0.0);
            //vec2 p = vec2(lightPos.x + sign(rayDir.x) * 0.5, 0.0);
            p.y = lightPos.y + (p.x - lightPos.x) * tan(directionAngle);

            // March
            for(int i = 0; i < 16; i++)
            {
                // Test the tiles sharing an edge
                int testX1 = int(p.x + 0.5);
                int testX2 = int(p.x - 0.5);
                int testY = int(p.y);
                if(map[testX1 + testY * 16] + map[testX2 + testY * 16] <= 0)
                {
                    p += vec2(stepX, stepY);
                }
                else
                    break;
            }

            d = min(length(lightPos - p), d);
        }
        
        float lightToUvLen = length(uv - lightPos);
        
        // Is the pixel in view of the light?
        if(d >= lightToUvLen - EPSILON)
            col = 1.0f - vec3(lightToUvLen / 16.0f);
        else
            col = vec3(0.0f);
    }
    else // Wall
        col = vec3(1.0);
    
    // Output to screen
    return vec4(col, 1.0);
}