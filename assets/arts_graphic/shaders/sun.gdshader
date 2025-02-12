// By 317GW 2024 7
shader_type spatial;
render_mode specular_disabled, diffuse_toon;

uniform float Glow_Power : hint_range(0,10) = 3;
uniform float Lightness_Difference : hint_range(0,10) = 3;
uniform float fresnel : hint_range(0.001,2) = 1.05;
uniform float waveSpeed : hint_range(0,1) = 0.1;
uniform float sunWaveSpeed : hint_range(0,1) = 0.2;
uniform float scale : hint_range(0,2) = 0.01;
uniform float blendSharpness : hint_range(0,2) = 0.0;

varying vec3 vertex_pos;

uniform vec4 Sun_Color : source_color;
uniform sampler2D Sun_Texture : source_color,filter_nearest_mipmap,repeat_enable;
uniform sampler2D voronoi_noise : source_color,filter_nearest_mipmap,repeat_enable;
uniform sampler2D emission_noise : source_color,filter_nearest_mipmap,repeat_enable;

// TRIPLANAR FUNCTION 三平面函数
vec4 triplanar_texture(vec3 position, vec3 normal, vec2 offset, sampler2D noise) {
	vec4 colX = texture(noise, position.xy * scale + offset);
	vec4 colY = texture(noise, position.xz * scale + offset);
	vec4 colZ = texture(noise, position.zy * scale + offset);

	vec3 blendWeight = abs(normal);
	blendWeight = vec3(pow(blendWeight.x, blendSharpness), pow(blendWeight.y, blendSharpness), pow(blendWeight.z, blendSharpness));
	blendWeight /= (blendWeight.x + blendWeight.y + blendWeight.z);

	return colX * blendWeight.x + colY * blendWeight.y + colZ * blendWeight.z;
}

void vertex() {
	vertex_pos = VERTEX;
}

void fragment() {
	// Fresnel 计算菲涅尔效应
	float fresnel_out = pow(fresnel - clamp(dot(NORMAL, VIEW), 0.0, fresnel), fresnel);
	// 计算时间相关的波浪偏移
	float time = TIME * waveSpeed;
	vec2 waveOffsetA = vec2(time, time * 0.8);
	vec2 waveOffsetB = vec2(time * -0.8, time * -0.3);
	vec2 result_offset = waveOffsetA + waveOffsetB;
	// 使用三平面映射获取云纹理
	vec3 cloud_tex = triplanar_texture(vertex_pos, NORMAL, result_offset, voronoi_noise).rgb;
	vec3 cloud_tex_with_light = cloud_tex * vec3(Lightness_Difference);
	// 计算太阳纹理的偏移并获取太阳纹理
	vec2 waveOffsetC = vec2(TIME * sunWaveSpeed * 0.01, 0);
	vec4 sun_texture = texture(Sun_Texture, UV + waveOffsetC) ;
	ALBEDO = sun_texture.rgb * cloud_tex * cloud_tex;
	// 结合太阳颜色和光照效果
	vec3 cloud_tex_with_light_with_color = cloud_tex_with_light * Sun_Color.rgb * sun_texture.rgb;
	vec3 cloud_tex_with_light_with_color_with_glow = vec3(Glow_Power) * cloud_tex_with_light_with_color;
	// 使用三平面映射获取噪声纹理
	vec3 noise_tex = triplanar_texture(vertex_pos, NORMAL, result_offset, emission_noise).rgb;
	vec3 result = cloud_tex_with_light_with_color * noise_tex;
	// 计算最终的发光效果
	EMISSION = cloud_tex_with_light_with_color_with_glow + vec3(fresnel_out) * result;
}