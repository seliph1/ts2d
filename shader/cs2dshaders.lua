local shader = {}

shader.mask = love.graphics.newShader [[
extern Image tile;
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) { 
	vec4 texcolor = Texel(tex, texture_coords);
	vec4 tilecolor = Texel(tile, texture_coords);
	
	tilecolor.a = (texcolor.r + texcolor.g + texcolor.b)/3;
	return tilecolor * color;
}
]]


shader.magenta = love.graphics.newShader [[
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

shader.test1 = love.graphics.newShader [[
	#pragma language glsl3
	//uniform Image shadow_map;
	//uniform float time;

	#define PARALLAX_INTENSITY 0.15
	
	
	vec3 reinhard(vec3 x)
	{
		return x / (1.0 + x);
	}
	

	#ifdef PIXEL
	vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords ) {
		float heightmap = Texel(tex, texture_coords).r;
		vec3 viewdir_ts = vec3(0.0);
		viewdir_ts.xy = vec2(texture_coords) - vec2(0.5);
		viewdir_ts = normalize(viewdir_ts);
		
		vec2 parallax = viewdir_ts.xy * viewdir_ts.z * (heightmap - 0.5) * PARALLAX_INTENSITY;
		
		float heightmap_n = Texel(tex, texture_coords - parallax).r;
		vec2 heightmap_res = vec2(textureSize(tex, 0));

		float heightmap_x1 = Texel(tex, texture_coords - parallax + vec2(1.0/heightmap_res.x, 0.0)).r;
		float heightmap_y1 = Texel(tex, texture_coords - parallax + vec2(0.0, 1.0/heightmap_res.y)).r;
		
		float heightmap_ddx = heightmap_n - heightmap_x1;
		float heightmap_ddy = heightmap_n - heightmap_y1;
		
		vec3 normal = normalize(vec3(heightmap_ddx, heightmap_ddy, 0.001));
		vec3 light_dir = normalize( vec3(0.0, 0.0, 1.0) );
		
		vec3 light_direct = max(0.0, dot(normal, light_dir)) * vec3(1.0, 0.89, 0.81);

		float tex_shadow = Texel(tex, parallax + light_dir.xy * light_dir.z * heightmap *  0.5).r;
		float shadow = pow(max(heightmap - tex_shadow, 0.0), 0.25);


		vec3 fake_gi = heightmap_n * vec3(0.8,0.9,1.0) * 1.0;
		
		vec3 col = light_direct * 10.0 * shadow + fake_gi;
		col = reinhard(col);

		col *= pow(sin(texture_coords.x * 3.141592) * sin(texture_coords.y * 3.141592), 0.1);

		return vec4(col, 1.0);
	}
	#endif
	
	#ifdef VERTEX
	vec4 position( mat4 transform_projection, vec4 vertex_position )
	{
		//float d = 2.0;

		//vertex_position.xy = vec2(vertex_position.x*d,vertex_position.y*d);
		
		vertex_position.xy += vec2(16.0);

		return transform_projection * vertex_position;
	}
	#endif
]]


shader.test2 = love.graphics.newShader [[
	uniform Image shadow_map;
	uniform float time;
	
	float get_height(vec2 coords){
		// Cópia da imagem de altura.
		// Função chamada toda vez que quiser calcular uma sombra

		return Texel(shadow_map, coords).x;
	}
	
	vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
	{
		// Obtem a textura do mapa
		vec4 texcolor = Texel(tex, texture_coords);
		
		// Define o angulo que a sombra será desenhada
		//float phi = cos(time);
		float phi = -cos(time)*2;
		//float phi = 1;
		
		// Matriz de modificação do angulo
		mat2 angle_mod = mat2(cos(phi), -sin(phi), sin(phi), cos(phi));

		// Tamanho da sombra (quantas vezes o loop irá rodar)
		//float maxdepth = 0.032;
		float maxdepth = 0.008;
		float step = 0.001;
		float height = get_height(texture_coords);
		float depth = maxdepth;
		
		
		//texcolor.xyz *= vec3(height);
		
		for (float i=0.0; i <=maxdepth; i+= step) {
			float h = get_height(texture_coords + vec2(i)*angle_mod);
			if (h < 1.0 && height == 1.0)  {
				texcolor.xyz *= 0.3;
				break;
			};
		}
		return texcolor * color;
	}
]]

shader.test3 = love.graphics.newShader [[

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
local file

file = love.filesystem.read("shader/shadow.glsl")
shader.shadow = love.graphics.newShader ( file )


file = love.filesystem.read("shader/raycast.glsl")
shader.raycast = love.graphics.newShader( file )

file = love.filesystem.read("shader/experiment.glsl")
shader.experiment = love.graphics.newShader( file )

--file = love.filesystem.read("shader/bleed.glsl")
--shader.bleed = love.graphics.newShader( file )

file = love.filesystem.read("shader/windcover.glsl")
shader.wind = love.graphics.newShader( file )

file = love.filesystem.read("shader/raycastshadow.glsl")
shader.raycasts = love.graphics.newShader( file )

return shader

