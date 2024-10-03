// NOTE: Shader automatically converted from Godot Engine 4.3.stable's StandardMaterial3D.
// BY 317GW 2024 09 05
shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, diffuse_lambert, specular_schlick_ggx, world_vertex_coords;


group_uniforms Color;
uniform vec3 color_surface: source_color = vec3(0.22, 0.66, 1.0);
uniform vec3 color_shallow: source_color = vec3(0.22, 0.66, 1.0);
uniform vec3 color_deep: source_color = vec3(0.0, 0.25, 0.45);


group_uniforms Roughness;
uniform float roughness: hint_range(0.0, 1.0) = 0.04;
uniform float specular: hint_range(0.0, 1.0, 0.01) = 0.5;


group_uniforms Refraction;
uniform float refraction: hint_range(-1.0, 1.0, 0.001) = 0.3;
uniform float refraction_lod: hint_range(0.0, 10.0) = 2.5;
uniform vec4 refraction_texture_channel = vec4(0.01);
uniform sampler2D texture_refraction: filter_linear_mipmap_anisotropic, repeat_enable;


group_uniforms Normal;
uniform float normal_scale: hint_range(0.0, 10.0);
uniform float normal_uv_scale: hint_range(0.0, 10.0);
uniform float normal_noise_scale: hint_range(0.0, 2.0) = 1.0;
uniform float normal_noise_lod: hint_range(0.0, 10.0) = 4.0;
uniform float normal_noise_angle = 3.1415926;
uniform sampler2D texture_normal: hint_roughness_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D texture_normal_noise1: source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D texture_normal_noise2: source_color, filter_linear_mipmap_anisotropic, repeat_enable;


group_uniforms uv;
uniform vec3 uv1_scale;
uniform vec3 uv2_scale;
uniform vec3 uv1_speed;
uniform vec3 uv2_speed;

varying vec3 uv1_triplanar_pos;
varying vec3 uv2_triplanar_pos;
varying vec3 uv_normal;


group_uniforms Waves;
uniform float wave_speed = 0.01;
uniform float wave_noise_scale = 10.0;
uniform float wave_height_scale = 0.15;
varying float height;
varying vec3 wave_pos;
uniform sampler2D wave: filter_linear_mipmap_anisotropic, repeat_enable;


group_uniforms Deep;
uniform float surface_beers_law = 0.4;
uniform float surface_depth_offset = -0.75;
uniform float beers_law = 0.4;
uniform float depth_offset = -0.75;

uniform float surface_scale = 3.0;
uniform float depth_multi = 6.0;
uniform float depth_blend_powor: hint_range(0.0, 10.0) = 0.5;
uniform float depth_lod: hint_range(0.0, 10.0) = 2.5;
uniform float depth_color_add: hint_range(0.0, 1.0) = 0.15;
uniform float depth_color_mix: hint_range(0.0, 1.0) = 0.15;

varying float model_depth;


group_uniforms Spume;
uniform vec3 spume_color: source_color = vec3(1.0);
uniform float spume_scale = 1.0;
uniform vec3 spume_uv_scale = vec3(0.5);
uniform vec3 spume_uv_speed = vec3(0.01);
uniform float spume_lod: hint_range(0.0, 10.0) = 6.0;
uniform float spume_fade_lod_min = 5.0;
uniform float spume_fade_lod_max = 200.0;
uniform bool spume_ues_depth = true;

uniform sampler2D texture_edge_noise: source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D texture_spume: source_color, filter_nearest_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_spume: source_color, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 spume_triplanar_pos;


group_uniforms ToFade;
uniform float distance_fade_min = 2700.0; // 2000
uniform float distance_fade_max = 4000.0; // 3000
uniform bool ues_near_fade = false;
uniform float near_fade_min = 0.2;
uniform float near_fade_max = 0.3;
varying vec3 world_coordinates;


uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform sampler2D DEPTH_TEXTURE: hint_depth_texture, repeat_disable, filter_linear_mipmap;


vec4 triplanar_textureLod(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos, float lod) {
	vec4 samp = vec4(0.0);
	samp += textureLod(p_sampler, p_triplanar_pos.xy, lod) * p_weights.z;
	samp += textureLod(p_sampler, p_triplanar_pos.xz, lod) * p_weights.y;
	samp += textureLod(p_sampler, p_triplanar_pos.zy * vec2(-1.0, 1.0), lod) * p_weights.x;
	return samp;
}

vec4 triplanar_texture_linear(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
	vec4 samp = vec4(0.0);
	samp += texture(p_sampler, p_triplanar_pos.xy) * p_weights.z;
	samp += texture(p_sampler, p_triplanar_pos.xz) * p_weights.y;
	samp += texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0, 1.0) ) * p_weights.x;
	return samp;
}

vec4 triplanar_textureLod_linear(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos, float lod) {
	vec4 samp = vec4(0.0);
	samp += textureLod(p_sampler, p_triplanar_pos.xy, lod) * p_weights.z;
	samp += textureLod(p_sampler, p_triplanar_pos.xz, lod) * p_weights.y;
	samp += textureLod(p_sampler, p_triplanar_pos.zy * vec2(-1.0, 1.0), lod) * p_weights.x;
	return samp;
}


vec4 triplanar_texture_linear_rotated(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos, float angle) {
	vec4 samp = vec4(0.0);
	// 旋转 UV 坐标
	vec2 uv_xy = vec2(
		p_triplanar_pos.x * cos(angle) - p_triplanar_pos.y * sin(angle),
		p_triplanar_pos.x * sin(angle) + p_triplanar_pos.y * cos(angle)
	);
	vec2 uv_xz = vec2(
		p_triplanar_pos.x * cos(angle) - p_triplanar_pos.z * sin(angle),
		p_triplanar_pos.x * sin(angle) + p_triplanar_pos.z * cos(angle)
	);
	vec2 uv_zy = vec2(
		p_triplanar_pos.z * cos(angle) - p_triplanar_pos.y * sin(angle),
		p_triplanar_pos.z * sin(angle) + p_triplanar_pos.y * cos(angle)
	);
	samp += texture(p_sampler, uv_xy) * p_weights.z;
	samp += texture(p_sampler, uv_xz) * p_weights.y;
	samp += texture(p_sampler, uv_zy * vec2(-1.0, 1.0) ) * p_weights.x;
	return samp;
}

void vertex() {
	vec3 normal = MODEL_NORMAL_MATRIX * NORMAL;
	TANGENT = normalize(inverse(MODEL_NORMAL_MATRIX) * vec3(abs(normal.y), abs(normal.x), abs(normal.z)));
	BINORMAL = normalize(inverse(MODEL_NORMAL_MATRIX) * vec3(abs(normal.x), abs(normal.z), abs(normal.y)));

	uv_normal = abs(normal) / dot(abs(normal), vec3(1.0) );
	vec3 vertex_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	uv1_triplanar_pos = vertex_pos * uv1_scale + uv1_speed * TIME;
	uv1_triplanar_pos *= vec3(1.0, -1.0, 1.0);
	uv2_triplanar_pos = vertex_pos * uv2_scale + uv2_speed * TIME;
	uv2_triplanar_pos *= vec3(1.0, -1.0, 1.0);

	height = texture(wave, uv1_triplanar_pos.xz / wave_noise_scale + TIME * wave_speed).r;
	VERTEX.y += height * wave_height_scale - wave_height_scale/2.0;

	spume_triplanar_pos = vertex_pos * spume_uv_scale + spume_uv_speed * TIME;
	spume_triplanar_pos *= vec3(1.0, -1.0, 1.0);

	world_coordinates = VERTEX;
}


void fragment() {
	// 截取片段
	ALPHA = 1.0;
	float distance_from_camera = distance(CAMERA_POSITION_WORLD, world_coordinates);
	ALPHA *= smoothstep(distance_fade_max, distance_fade_min, distance_from_camera);
	if (ALPHA <= 0.0) {
		discard;
	}
	if (ues_near_fade) {
		ALPHA *= smoothstep(near_fade_min, near_fade_max, distance_from_camera);
	}

	// 获取当前片段的深度值
	float depth_texture = textureLod(DEPTH_TEXTURE, SCREEN_UV, 0.0).r;
	float depth = PROJECTION_MATRIX[3][2] / fma(depth_texture, depth_multi, PROJECTION_MATRIX[2][2]);
	// 深度&边缘magic
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_texture);
	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec3 depth_texture_pos = world.xyz / world.w;
	vec3 vertex_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 depth_diff = abs(vertex_pos - depth_texture_pos);
	float combined_depth = clamp(max(depth_diff.x, max(depth_diff.y, depth_diff.z)) / surface_scale, 0.0, 1.0);
	// 混合的深度
	float depth_blend = exp((depth + depth_offset) * -beers_law);
	depth_blend = clamp(1.0 - depth_blend, 0.0, 1.0);
	// 模糊的深度
	float depth_blend_pow = clamp(pow(depth_blend, depth_blend_powor), 0.0, 1.0);
	vec3 screen_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, depth_blend_pow * depth_lod).rgb;
	vec3 depth_color = mix(color_shallow.rgb, color_deep.rgb, combined_depth);
	vec3 color = screen_color;
	color = fma(screen_color, depth_color, depth_color * depth_color_add);
	color = mix(color, depth_color, combined_depth * depth_color_mix);
	color = mix(screen_color * color_surface, color, combined_depth * depth_blend);
	color = clamp(color, vec3(0.0), vec3(1.0) );
	ALBEDO = color;


	SPECULAR = specular;
	ROUGHNESS = roughness;
	// Normal Map
	float normal_noise1 = triplanar_texture_linear(
		texture_normal_noise1,
		uv_normal,
		uv1_triplanar_pos * normal_noise_scale).r;
	float normal_noise2 = triplanar_textureLod_linear(
		texture_normal_noise2,
		uv_normal,
		uv1_triplanar_pos * normal_noise_scale + normal_noise1 * 0.5,
		normal_noise_lod).r;
	vec3 normal_blend = mix(
		triplanar_texture_linear_rotated(texture_normal, uv_normal, uv1_triplanar_pos * normal_uv_scale, PI*0.4).rgb,
		triplanar_texture_linear_rotated(texture_normal, uv_normal, uv2_triplanar_pos * normal_uv_scale, 0.0).rgb,
		normal_noise2);
	NORMAL_MAP = normal_blend;
	NORMAL_MAP_DEPTH = normal_scale;


	// Spume 泡沫
	float lod_spume = spume_lod * smoothstep(spume_fade_lod_min, spume_fade_lod_max, distance_from_camera);;
	vec3 spume_texture = triplanar_textureLod(texture_spume, uv_normal, spume_triplanar_pos, lod_spume).rgb;
	vec3 spume_normal = triplanar_textureLod_linear(normal_spume, uv_normal, spume_triplanar_pos, lod_spume).rgb;
	// 遮罩
	float edge_noise = triplanar_texture_linear(texture_edge_noise, uv_normal, uv1_triplanar_pos).r;
	vec3 spume_depth_diff = abs(vertex_pos - depth_texture_pos + edge_noise * spume_scale);
	float combined_spume = clamp(max(spume_depth_diff.x, max(spume_depth_diff.y, spume_depth_diff.z)) / spume_scale, 0.0, 1.0);
	float spume_mask = mix(spume_texture.r, 0.0, combined_spume);
	if (spume_ues_depth){
		spume_mask *= (1.0 - depth_blend_pow);
	}
	// 色
	ALBEDO = mix(ALBEDO, spume_color, spume_mask);
	ROUGHNESS = mix(ROUGHNESS, 0.0, spume_mask);
	NORMAL_MAP = mix(NORMAL_MAP, spume_normal, spume_mask);


	// Refraction (with normal map texture)
	vec3 unpacked_normal = NORMAL_MAP;
	unpacked_normal.xy = unpacked_normal.xy * 2.0 - 1.0;
	unpacked_normal.z = sqrt(max(0.0, 1.0 - dot(unpacked_normal.xy, unpacked_normal.xy)));
	vec3 ref_normal = normalize(mix(
			NORMAL,
			TANGENT * unpacked_normal.x + BINORMAL * unpacked_normal.y + NORMAL * unpacked_normal.z,
			NORMAL_MAP_DEPTH));
	vec2 ref_ofs = SCREEN_UV - ref_normal.xy * dot(triplanar_texture_linear(texture_refraction, uv_normal, uv1_triplanar_pos), refraction_texture_channel) * refraction;
	//ref_ofs *= combined_depth * 0.5;
	float ref_amount = 1.0 - dot(normalize(color), vec3(0.2126, 0.7152, 0.0722) ); // luminance(ALBEDO)
	ref_amount = pow(ref_amount, 2.0);
	float EMISSION_lod = fma(fma(ROUGHNESS, 0.5, 0.5), refraction_lod, ref_amount * 2.0);
	EMISSION += textureLod(SCREEN_TEXTURE, ref_ofs, EMISSION_lod).rgb * ALBEDO * ref_amount;
	EMISSION = mix(EMISSION, spume_texture, spume_mask);
}
