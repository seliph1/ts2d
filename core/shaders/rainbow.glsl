uniform float time = 0.0;
uniform float strength = 0.5;
uniform float speed = 0.5;
uniform float angle = 0.0;

vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
{
	vec4 texcolor = Texel(tex, texture_coords);
	vec2 uv = texture_coords;
	float hue = uv.x * cos(radians(angle)) - uv.y * sin(radians(angle));
	hue = fract(hue + fract(time * speed));
	float x = 1.0 - abs(mod(hue / (1.0/6.0), 2.0 ) -1.0);
	vec3 rainbow;
	if (hue < 1.0/6.0) {
		rainbow = vec3(1.0, x, 0.0);
	} else if (hue < 1.0/3.0) {
		rainbow = vec3(x, 1.0, 0);
	} else if (hue < 0.5) {
		rainbow = vec3(0, 1., x);
	} else if (hue < 2.0/3.0) {
		rainbow = vec3(0., x, 1.);
	} else if (hue < 5.0/6.0) {
		rainbow = vec3(x, 0.0, 1.);
	} else {
		rainbow = vec3(1.0, 0.0, x);
	}
	texcolor = mix(texcolor, vec4(rainbow, texcolor.a), strength);

	// interpolação linear

	return texcolor * color;
}