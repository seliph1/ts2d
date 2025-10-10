extern float epsilon = 0.1;

void color_mask(vec4 sub_color, vec4 tex_color, float threshold){
	if (
		(sub_color.r + threshold >= tex_color.r && sub_color.r - threshold <= tex_color.r) &&
		(sub_color.g + threshold >= tex_color.g && sub_color.g - threshold <= tex_color.g) &&
		(sub_color.b + threshold >= tex_color.b && sub_color.b - threshold <= tex_color.b)
	)
	{ discard; }    
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	vec4 texcolor = Texel(tex, texture_coords);
	
	color_mask( vec4(1.0, 0.0, 1.0, 0.0), texcolor, epsilon);

	return texcolor * color;
}