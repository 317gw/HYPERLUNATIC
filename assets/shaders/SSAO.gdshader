shader_type spatial;

uniform sampler2D g_buffer_pos: hint_depth_texture, repeat_disable, filter_linear_mipmap;
uniform sampler2D g_buffer_norm: hint_normal_roughness_texture, repeat_disable, filter_linear_mipmap;
uniform sampler2D g_random: hint_roughness_normal, filter_linear_mipmap_anisotropic, repeat_enable;

uniform float random_size;
uniform float g_sample_rad: hint_range(-10.0, 10.0) = 0.0;
uniform float g_intensity: hint_range(0.0, 10.0, 0.05) = 2.0;
uniform float g_scale;
uniform float g_bias;
uniform int iterations: hint_range(0, 20) = 4;
uniform float lod: hint_range(0.0, 10.0, 0.05) = 2.0;


float doAmbientOcclusion(vec2 tcoord, vec2 uv, vec3 p, vec3 cnorm) {
	vec3 diff = textureLod(g_buffer_pos, tcoord + uv, lod).xyz - p;
	vec3 v = normalize(diff);
	float d = length(diff) * g_scale;
	return max(0.0, dot(cnorm, v) - g_bias) * (1.0 / (1.0 + d));
}


void fragment() {
	vec3 p = textureLod(g_buffer_pos, SCREEN_UV, lod).xyz;
	vec3 n = normalize(textureLod(g_buffer_norm, SCREEN_UV, lod).xyz * 2.0 - 1.0);
	vec2 rand = normalize(textureLod(g_random, VIEWPORT_SIZE * SCREEN_UV / random_size, lod).xy * 2.0 - 1.0);

	float ao = 0.0;
	float rad = g_sample_rad / p.z;

	vec2 vec[4] = vec2[](
		vec2(1, 0),
		vec2(-1, 0),
		vec2(0, 1),
		vec2(0, -1)
	);

	//int iterations = 4;
	for (int j = 0; j < iterations; ++j) {
		vec2 coord1 = reflect(vec[j], rand) * rad;
		vec2 coord2 = vec2(coord1.x * 0.707 - coord1.y * 0.707, coord1.x * 0.707 + coord1.y * 0.707);

		ao += doAmbientOcclusion(SCREEN_UV, coord1 * 0.25, p, n);
		ao += doAmbientOcclusion(SCREEN_UV, coord2 * 0.5, p, n);
		ao += doAmbientOcclusion(SCREEN_UV, coord1 * 0.75, p, n);
		ao += doAmbientOcclusion(SCREEN_UV, coord2, p, n);
	}

	ao /= float(iterations) * 4.0;
	ao = clamp(1.0 - ao * g_intensity, 0.0, 1.0);
	ALBEDO = vec3(ao);
	//ALBEDO = vec3(0.5);
}
