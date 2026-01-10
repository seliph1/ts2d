uniform float boundBrightness = 1.0;

vec4 effect(vec4 COLOR, Image TEXTURE, vec2 UV, vec2 SCREEN_UV) {
	vec4 TEXTURE_COLOR = Texel(TEXTURE, UV);
    vec2 SCREEN_SIZE = love_ScreenSize.xy;

	vec2 scan_uv = floor(UV * SCREEN_SIZE); 
	

	TEXTURE_COLOR.rgb += boundBrightness;

	//TEXTURE_COLOR.rgb = vec3(0.5);

	return TEXTURE_COLOR;
}