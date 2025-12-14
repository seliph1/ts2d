/*
	Glitch Effect Shader by Yui Kinomoto @arlez80
    Adapted to LOVE2D by Seliph
	MIT License
*/

uniform float shake_power = 0.1;
uniform float shake_rate = 0.2;
uniform float shake_speed = 5.0;
uniform float shake_block_size = 0.08;
uniform float shake_color_rate = 0.01;
uniform float time = 0.0;

float random( float seed )
{
	return fract( 543.2543 * sin( dot( vec2( seed, seed ), vec2( 3525.46, -54.3415 ) ) ) );
}

vec4 effect( vec4 color, Image SCREEN_TEXTURE, vec2 TEXTURE_UV, vec2 SCREEN_UV )
{
    float TIME = time;
        
	float enable_shift = float(
		random( trunc( TIME * shake_speed ) )
	<	shake_rate
	);

	vec2 fixed_uv = TEXTURE_UV;
	fixed_uv.x += (
		random(
			( trunc( SCREEN_UV.y * shake_block_size ) / shake_block_size )
		+	TIME
		) - 0.5
	) * shake_power * enable_shift;

    vec4 pixel_color = Texel(SCREEN_TEXTURE, fixed_uv);
	pixel_color.r = mix(
		pixel_color.r
	,	Texel( SCREEN_TEXTURE, fixed_uv + vec2( shake_color_rate, 0.0 ), 0.0 ).r
	,	enable_shift
	);
	pixel_color.b = mix(
		pixel_color.b
	,	Texel( SCREEN_TEXTURE, fixed_uv + vec2( -shake_color_rate, 0.0 ), 0.0 ).b
	,	enable_shift
	);

    return pixel_color * color;
}