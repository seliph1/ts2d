uniform float offset[3] = float[](0.0, 1.3846153846, 3.2307692308);
uniform float weight[3] = float[](0.2270270270, 0.3162162162, 0.0702702703);

vec4 effect (vec4 COLOR, Image TEXTURE, vec2 UV, vec2 SCREEN_UV) {
	vec2 size = textureSize(TEXTURE, 0);

	vec4 TEXTURE_COLOR = Texel(TEXTURE, UV)  * weight[0];

	for (int i=1; i<3; i++) {
		TEXTURE_COLOR += Texel(TEXTURE, (UV + offset[i]/size) ) * weight[i];

		TEXTURE_COLOR += Texel(TEXTURE, (UV - offset[i]/size) ) * weight[i];
	}
	
	return TEXTURE_COLOR;
}