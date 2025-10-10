	#pragma language glsl3
	//extern Image shadow_map;
	//extern float time;

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