extern int mask = 0;
extern int blend = 0;
extern float epsilon = 0.1;

vec4 color_mask(vec4 sub_color, vec4 tex_color, float threshold){
	if (
		(sub_color.r + threshold >= tex_color.r && sub_color.r - threshold <= tex_color.r) &&
		(sub_color.g + threshold >= tex_color.g && sub_color.g - threshold <= tex_color.g) &&
		(sub_color.b + threshold >= tex_color.b && sub_color.b - threshold <= tex_color.b)
	)
	{
		return vec4(0.0, 0.0, 0.0, 0.0);
	} else {
		return tex_color;
	}    
}


vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
{
	vec4 texcolor = Texel(tex, texture_coords);
	if (blend == 6) { // Grayscale
		texcolor.a = (texcolor.r + texcolor.g + texcolor.b) / 3.0;
		
	} else if (blend == 3) { // Light
		texcolor.rgb *= color.a * 2.0;
	}
	
	if ( mask == 4 ) {
		texcolor = color_mask( vec4(0.0), texcolor, epsilon);
	};

	return texcolor * color;
}