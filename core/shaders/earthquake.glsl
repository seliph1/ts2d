uniform float time = 1.0;
uniform float x = 0.0;
uniform float y = 0.0;
uniform float shake = 0.0;
uniform float speed = 1.0;
uniform float seed = 0.0;

float random( float seed )
{
	return fract( 543.2543 * sin( dot( vec2( seed, seed ), vec2( 3525.46, -54.3415 ) ) ) );
}

#ifdef VERTEX
vec4 position ( mat4 TRANSFORM, vec4 POSITION) {
    POSITION += vec4(x, y, 0, 0);
    //float f = random(time) * 32.0;

    float offset_x = sin(time * speed * 1.3 + sin(time * speed * 0.7)) * 0.05;
    float offset_y = cos(time * speed * 0.9 + cos(time * speed * 0.5)) * 0.05;

    POSITION += vec4( offset_x * shake, offset_y * shake, 0, 0);

    return TRANSFORM * POSITION;
}
#endif

#ifdef PIXEL
vec4 effect(vec4 COLOR, Image TEXTURE, vec2 UV, vec2 SCREEN_UV) {
    vec4 TEXTURE_COLOR = Texel(TEXTURE, UV);
    float TIME = time;
    TEXTURE_COLOR = TEXTURE_COLOR;

    return TEXTURE_COLOR * COLOR;
}
#endif