uniform float brightnessMult = 4.0;
uniform float wiggleMult = 0.005;
uniform float chromaticAberrationOffset = 0.001;
uniform float time;

vec4 effect(vec4 COLOR, Image TEXTURE, vec2 UV, vec2 SCREEN_UV) {
//	set up
    vec3 color;
    vec2 SCREEN = love_ScreenSize.xy;    
    float TIME = time;
//	wiggle
	float x =  sin(0.3*TIME+UV.y*21.0)*sin(0.7*TIME+UV.y*29.0)*sin(0.3+0.33*TIME+UV.y*31.0)*wiggleMult;
//draw the actual game lol
	//the color adjustments is a simpler chromatic aberration
    color.r = Texel(TEXTURE,vec2(x+UV.x+chromaticAberrationOffset,UV.y+chromaticAberrationOffset)).x+0.045;
    color.g = Texel(TEXTURE,vec2(x+UV.x,UV.y-chromaticAberrationOffset)).y+0.05;
    color.b = Texel(TEXTURE,vec2(x+UV.x-chromaticAberrationOffset,UV.y)).z+0.055;

	//simple vignette
    float vignette = (0.0 + 1.0*16.0*UV.x*UV.y*(1.0-UV.x)*(1.0-UV.y));
	color *= vec3(pow(vignette,0.3));

	//adjust brightness
    color *= vec3(0.95,1.05,0.95);
	color *= brightnessMult;

	//add scanlines
	float scans = clamp( 0.35+0.35*sin(3.5*TIME+UV.y*SCREEN.y*1.5), 0.0, 1.0);
	float s = pow(scans,1.7);
	color = color*vec3( 0.4+0.7*s) ;

    return vec4(color,1.0);
}