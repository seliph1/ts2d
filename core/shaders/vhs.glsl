uniform float color_offset_multiplier  =  0.004;
uniform float black_offset_multiplier = 0.1;
uniform float color_offset = 0.005;
uniform float blur_amount = 0.1;

uniform float time;

float noise(vec2 uv, float offset) {
	return (fract(sin(dot(uv * offset, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * 2.0;
}

vec3 rgb_to_yuv(vec3 rgb) {
	const mat3 RGB_TO_YUV = mat3(
		vec3(0.299, 0.587, 0.114),
		vec3(-0.14713, -0.28886, 0.436),
		vec3(.615, -0.51499, -0.10001)
		);
	return rgb * RGB_TO_YUV;
}

vec3 yuv_to_rgb(vec3 yuv) {
	const mat3 YUV_TO_RGB = mat3(
		vec3(1.0, 0.0, 1.13983),
		vec3(1.0, -0.39465, -0.58060),
		vec3(1.0, 2.03211, 0.0)
		);
	return clamp(yuv * YUV_TO_RGB, vec3(0.0), vec3(1.0));
}

vec4 effect(vec4 COLOR, Image TEXTURE, vec2 UV, vec2 SCREEN_UV) {
    vec4 final_color = vec4(0.0);

	float x_offset = color_offset + noise(vec2(floor(UV.y * 487.0), fract(UV.y * 487.0)), time) * color_offset_multiplier;
	float black_offset = noise(vec2(floor(UV.y * 487.0), fract(UV.y * 487.0)), time + 69.420) * (black_offset_multiplier * 0.01);

	final_color = textureLod(TEXTURE, UV + vec2(black_offset,0.0), 0.0);

	vec4 color2 = textureLod(TEXTURE, UV + vec2(x_offset,0.0), blur_amount);
	vec3 yuv1 = rgb_to_yuv(final_color.rgb);
	vec3 yuv2 = rgb_to_yuv(color2.rgb);

	return vec4(yuv_to_rgb(vec3(yuv1.x, yuv2.yz)), 1.0);
}