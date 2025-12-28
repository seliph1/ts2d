uniform vec3 silhouette_color = vec3(1.0);
uniform float height = 1.0;

vec3 pix = vec3( 1/love_ScreenSize.x, 1/love_ScreenSize.y, 0);
vec4 effect( vec4 COLOR, Image TEXTURE, vec2 UV, vec2 SCREEN_UV )
{
    vec4 TEXTURE_COLOR = Texel(TEXTURE, UV);
    if (TEXTURE_COLOR.a < 0.90) {
        TEXTURE_COLOR.rgb = vec3(0.0);
    } else {
        TEXTURE_COLOR.rgb = vec3(silhouette_color * height);
    };
 
    vec4 final_color = vec4( TEXTURE_COLOR );
    return final_color;
    /*
    vec2 p = UV * love_ScreenSize.xy;
    vec2 p_lerp = fract(p);
    p = floor(p);
    p *= pix.xy;
    const float i = 0.0;
    vec4 a0 = Texel(TEXTURE, p);
    vec4 a1 = Texel(TEXTURE, p + pix.zy * i);
    vec4 a2 = Texel(TEXTURE, p + pix.xz * i);
    vec4 a3 = Texel(TEXTURE, p + pix.xy * i);

    vec4 b0 = mix(a0, a2, p_lerp.x );
    vec4 b1 = mix(a1, a3, p_lerp.x );

    vec4 lerp =  mix(b0, b1, p_lerp.y);

    if (lerp.a < 0.99) { discard; };
    vec4 final_color = vec4( vec3(silhouette_color * height), lerp.r );
    //vec4 final_color = vec4( vec3(lerp), 1.0*height);
	return final_color;*/
}