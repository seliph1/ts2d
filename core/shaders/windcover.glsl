extern vec4 iMouse = vec4(0.0);
extern float iTime = 0.0;
vec2 iResolution = love_ScreenSize.xy;
extern Image iChannel0;

float height( vec2 uv )
{
    const float baseHeight = 0.4;
    float h = Texel( iChannel0, uv ).r;
	return 1.0 / ( 1.0 - baseHeight ) * ( max( h, baseHeight ) - baseHeight );
}

float windOverLineSegment( vec2 p1, vec2 p2 )
{
    const float maxCoverDistance = 1.0;
    const float minEffectiveHeight = 0.1;
    float windValue = 1.0;
    vec2 dPix = ( p2 - p1 ) * iResolution.xy;
    if ( length( dPix ) < 1.0 ) return 0.0;
    float numSteps = abs( dPix.x ) > abs( dPix.y ) ? abs( dPix.x ) : abs( dPix.y );
    vec2 inc = ( p2 - p1 ) / numSteps;
    #define MAXSTEPS 4096
    vec2 p = p1;
    for( int i = 0; i < MAXSTEPS; ++i )
    {
        if ( float( i ) >= numSteps ) break;
        if ( p.x < 0.0 || p.x > 1.0 ) break;
        if ( p.y < 0.0 || p.y > 1.0 ) break;
        float h = height( p );
        windValue = h > minEffectiveHeight && distance( p, p1 ) < maxCoverDistance * h ? 0.0 : windValue;
        p += inc;
    }
    return windValue;
}

#define EPSILON 1e-7

bool pointIsOnPlane2D( in vec2 point, in vec2 AnyPointOnPlane, in vec2 planeNormal )
{
    return abs( dot( point - AnyPointOnPlane, planeNormal ) ) < EPSILON;
}

bool rayIsParallelToPlane2D( in vec2 rd, in vec2 n )
{
    return abs( dot( rd, n ) ) < EPSILON;
}

bool rayIntersectsPlane2D( in vec2 ro, in vec2 rd, in vec2 p, in vec2 n, out vec2 intersectionPoint )
{
    if ( pointIsOnPlane2D( ro, p, n ) )
    {
        intersectionPoint = ro;
        return true;
    }
    if ( rayIsParallelToPlane2D( rd, n ) ) return false;
    float t = -dot( ro - p, n ) / dot( rd, n );
    if ( t < 0.0 ) return false;
    intersectionPoint = ro + t * rd;
    return true;
}

float wind( in vec2 uv, in vec2 dir )
{
    vec2 uv2 = uv;
	bool intersects = rayIntersectsPlane2D( uv, -dir, vec2( 0.0, 0.0 ), vec2( 1.0, 0.0 ) , uv2 );
    if ( !intersects ) intersects = rayIntersectsPlane2D( uv, -dir, vec2( 0.0, 0.0 ), vec2( 0.0, 1.0 ), uv2 );
    if ( !intersects ) intersects = rayIntersectsPlane2D( uv, -dir, vec2( 1.0, 1.0 ), vec2( -1.0, 0.0 ) , uv2 );
    if ( !intersects ) intersects = rayIntersectsPlane2D( uv, -dir, vec2( 1.0, 1.0 ), vec2( 0.0, -1.0 ) , uv2 );
    return windOverLineSegment( uv, uv2 );
}

vec4 effect( vec4 fragColor, Image tex, vec2 fragCoord, vec2 screenCoord )
{
	vec2 uv = screenCoord.xy / iResolution.xy;
    vec2 mousePos =  iMouse.xy / iResolution.xy;
    vec2 dir = normalize( mousePos - vec2( 0.5, 0.5 ) );
    return vec4( height( uv ) ) + vec4( wind( uv, dir ), 0.0, 0.0, 1.0 );
}