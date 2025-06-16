#define MAP_LEN 1000

//uniform vec4 iMouse = vec4(0.0);
uniform vec2 camera = vec2(0.0);
uniform float iTime = 0.0;
uniform Image iChannel0;

vec2 iResolution = love_ScreenSize.xy;

float getHeightValue(vec2 coords)
{
    float n = 0.33;
	float h = Texel(iChannel0, coords).x;
	return max(n, h);
}


float get_diffuse(vec3 n, vec3 l)
{
	return max(0.0, dot(n,l));
}

float shadow(vec3 wPos, vec3 lVector, float NdL)
{
	float bias = 0.01;
	float shadow = 1.0;
	vec3 p;
	
	if (NdL > 0.0)
   	{
   		for (float i = 0.0; i <= 1.0; i += 0.01) 
   		{
   			p = wPos + lVector * i;
				
 			if (p.z < getHeightValue(vec2(p.x, p.y)) - bias)
			{
				//shadow = 0.0 + p.z;
				shadow = 0.5;
				
				//shadow = 0.0 + i;
				break;
			}
		}
   	}
	return (shadow);
}


vec3 getNormal(vec2 coords, float intensity)
{
    float offset = 1.0;
    vec3 a = vec3(coords.x - offset, 0.0, getHeightValue(vec2(coords.x - offset, coords.y)) * intensity);
    vec3 b = vec3(coords.x + offset, 0.0, getHeightValue(vec2(coords.x + offset, coords.y)) * intensity);
    vec3 c = vec3(0.0, coords.y + offset, getHeightValue(vec2(coords.x, coords.y + offset)) * intensity);
    vec3 d = vec3(0.0, coords.y - offset, getHeightValue(vec2(coords.x, coords.y - offset)) * intensity);

    return normalize(cross(b-a, c-d));
}




vec4 effect( vec4 fragColor, Image tex, vec2 fragCoord, vec2 screenCoord )
{
	vec2 uv = fragCoord.xy;


	float phi = 1.0;	
	float theta = iTime;
	
	
	
	vec2 dir = vec2(cos(theta)*0.002, sin(theta)*0.002);
    vec3 lightVector = normalize(vec3( dir, cos(phi) ) );
	
    vec3 worldPos = vec3(vec2(uv), getHeightValue(uv));
    vec3 normal = getNormal(uv, 0.5);   
	
    float NdotL = max(dot(normal, lightVector), 0.0);
	
	vec3 color;
    color = vec3(get_diffuse(normal, lightVector)) * 0.1;
	
	float s = shadow(worldPos, lightVector, NdotL);
    color *= vec3( s );
	
	float ambient = 1.0 - s;
	
	// Gaussian blur

	/*
	int steps = 2;
	for(int i = 1; i <= int(steps); i++) {
		col = col + Texel(texture, vec2(texture_coords.x, texture_coords.y - pSize.y * float(i)));
		col = col + Texel(texture, vec2(texture_coords.x, texture_coords.y + pSize.y * float(i)));
	}
	col = col / (steps * 2.0 + 1.0);
	*/
	//return vec4(col.r, col.g, col.b, 1.0);
    return vec4(color, ambient);
}

