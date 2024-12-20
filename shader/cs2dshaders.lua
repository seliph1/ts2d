local shader = {}

shader.magenta = love.graphics.newShader [[
//extern Image palette;
uniform float epsilon = 0.1;

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
]]

shader.entity = love.graphics.newShader [[
uniform int mask = 0;
uniform int blend = 0;
uniform float epsilon = 0.1;

vec4 color_mask(vec4 sub_color, vec4 tex_color, float threshold){
	if (
		(sub_color.r + threshold >= tex_color.r && sub_color.r - threshold <= tex_color.r) &&
		(sub_color.g + threshold >= tex_color.g && sub_color.g - threshold <= tex_color.g) &&
		(sub_color.b + threshold >= tex_color.b && sub_color.b - threshold <= tex_color.b)
	)
	{
		return vec4(0.0,0.0,0.0,0.0);
	} else {
		return tex_color;
	}    
}


vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
{
	vec4 texcolor = Texel(tex, texture_coords);
	if (blend == 6) { // Grayscale
		texcolor.a = (texcolor.r + texcolor.g + texcolor.b)/3;
		
	} else if (blend == 3) { // Light
		texcolor.rgb *= color.a*2.0;
	}
	
	if ( mask == 4 ) {
		texcolor = color_mask( vec4(0.0), texcolor, epsilon);
	};

	return texcolor * color;
}
]]


shader.shadow = love.graphics.newShader [[

// Inputs
uniform vec2 light_direction = vec2(0.0, 1.0);				// Direction of the light (normalized)
uniform vec4 shadow_color = vec4(0.0, 0.0, 0.0, 0.5);		// Color and opacity of the shadow
uniform float shadow_length = 32.0;							// Length of the shadow

vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
{
	vec4 texcolor = Texel(tex, texture_coords);
	
	vec2 shadow_offset = light_direction * shadow_length;
    vec2 shadow_coord = texture_coords + shadow_offset;
	
	// Sample the shadow from the object's texture
    float shadow_alpha = Texel(tex, shadow_coord).a; // Use alpha for shadow shape
	
	// Combine shadow and object color
    vec4 shadow = shadow_color * shadow_alpha;            // Modulate shadow by alpha
	
    vec4 frag_color = mix(shadow, texcolor, texcolor.a); // Blend shadow and object
	
	return frag_color;
}
]]

return shader

