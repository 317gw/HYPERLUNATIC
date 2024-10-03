// NOTE: Shader automatically converted from Godot Engine 4.3.stable's StandardMaterial3D.
// BY 317GW 2024 09 05
shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, diffuse_burley, specular_schlick_ggx;


group_uniforms Albedo;
uniform vec4 albedo: source_color;
uniform vec4 albedo2: source_color;
uniform float saturation: hint_range(0.0, 1.0);
uniform sampler2D texture_albedo: source_color, filter_linear_mipmap_anisotropic, repeat_enable;


group_uniforms Roughness;
uniform float roughness: hint_range(0.0, 1.0);
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness: hint_roughness_r, filter_linear_mipmap_anisotropic, repeat_enable;


group_uniforms Refraction;
uniform float refraction: hint_range(-1.0, 1.0, 0.001);
uniform vec4 refraction_texture_channel;
uniform sampler2D texture_refraction: filter_linear_mipmap_anisotropic, repeat_enable;


group_uniforms Normal;
uniform float normal_scale: hint_range(-16.0, 16.0);
uniform sampler2D texture_normal1: hint_roughness_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D texture_normal2: hint_roughness_normal, filter_linear_mipmap_anisotropic, repeat_enable;


group_uniforms uv;
varying vec3 uv1_triplanar_pos;
varying vec3 uv2_triplanar_pos;

uniform float uv1_blend_sharpness: hint_range(0.0, 150.0, 0.001);
uniform float uv2_blend_sharpness: hint_range(0.0, 150.0, 0.001);
varying vec3 uv1_power_normal;
varying vec3 uv2_power_normal;

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

uniform vec3 uv1_speed;
uniform vec3 uv2_speed;


group_uniforms Waves;
uniform float wave_speed = 0.01;
uniform float wave_noise_scale = 10.0;
uniform float wave_height_scale = 0.15;
varying float height;
varying vec3 world_pos;

//uniform sampler2D texture_noise: filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D wave: filter_linear_mipmap_anisotropic, repeat_enable;


uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, repeat_disable, filter_linear_mipmap_anisotropic;


vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
	vec4 samp = vec4(0.0);
	samp += texture(p_sampler, p_triplanar_pos.xy) * p_weights.z;
	samp += texture(p_sampler, p_triplanar_pos.xz) * p_weights.y;
	samp += texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0, 1.0)) * p_weights.x;
	return samp;
}

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

void vertex() {
	vec3 normal = MODEL_NORMAL_MATRIX * NORMAL;

	TANGENT = vec3(0.0, 0.0, -1.0) * abs(normal.x);
	TANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.y);
	TANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.z);
	TANGENT = inverse(MODEL_NORMAL_MATRIX) * normalize(TANGENT);

	BINORMAL = vec3(0.0, 1.0, 0.0) * abs(normal.x);
	BINORMAL += vec3(0.0, 0.0, -1.0) * abs(normal.y);
	BINORMAL += vec3(0.0, 1.0, 0.0) * abs(normal.z);
	BINORMAL = inverse(MODEL_NORMAL_MATRIX) * normalize(BINORMAL);

	// UV1 Triplanar: Enabled (with World Triplanar)
	uv1_power_normal = pow(abs(normal), vec3(uv1_blend_sharpness));
	uv1_power_normal /= dot(uv1_power_normal, vec3(1.0)) ;
	uv1_triplanar_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * uv1_scale + uv1_offset + uv1_speed * TIME;
	uv1_triplanar_pos *= vec3(1.0, -1.0, 1.0);

	uv2_power_normal = pow(abs(normal), vec3(uv2_blend_sharpness));
	uv2_power_normal /= dot(uv2_power_normal, vec3(1.0)) ;
	uv2_triplanar_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * uv2_scale + uv2_offset + uv2_speed * TIME;
	uv2_triplanar_pos *= vec3(1.0, -1.0, 1.0);

	world_pos = mix(uv1_triplanar_pos, uv2_triplanar_pos, 0.5);
	//vec3 normal12 = mix(uv1_power_normal, uv2_power_normal, 0.5) / TIME;
	height = texture(wave, world_pos.xz / wave_noise_scale + TIME * wave_speed).r;
	VERTEX.y += height * wave_height_scale - wave_height_scale/2.0;
}


void fragment() {
	vec4 albedo_tex = triplanar_texture(texture_albedo, uv1_power_normal, uv1_triplanar_pos);
	float fresnel = fresnel(5.0, NORMAL, VIEW);
	vec3 surface_color = mix(albedo.rgb, albedo2.rgb, fresnel) * albedo_tex.rgb;
	ALBEDO = mix(vec3(dot(vec3(1.0), surface_color) / 3.0), surface_color, saturation);;

	// ROUGHNESS
	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(triplanar_texture(texture_roughness, uv1_power_normal, uv1_triplanar_pos), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;

	// Normal Map: Enabled
	vec3 normal_blend = mix(triplanar_texture(texture_normal1, uv1_power_normal, uv1_triplanar_pos).rgb, triplanar_texture(texture_normal2, uv2_power_normal, uv2_triplanar_pos).rgb, 0.5);
	NORMAL_MAP = normal_blend;
	NORMAL_MAP_DEPTH = normal_scale;

	// Refraction: Enabled (with normal map texture)
	vec3 unpacked_normal = NORMAL_MAP;
	unpacked_normal.xy = unpacked_normal.xy * 2.0 - 1.0;
	unpacked_normal.z = sqrt(max(0.0, 1.0 - dot(unpacked_normal.xy, unpacked_normal.xy)));
	vec3 ref_normal = normalize(mix(
			NORMAL,
			TANGENT * unpacked_normal.x + BINORMAL * unpacked_normal.y + NORMAL * unpacked_normal.z,
			NORMAL_MAP_DEPTH));
	vec2 ref_ofs = SCREEN_UV - ref_normal.xy * dot(triplanar_texture(texture_refraction, uv1_power_normal, uv1_triplanar_pos), refraction_texture_channel) * refraction;

	float ref_amount = 1.0 - albedo.a * albedo_tex.a;
	ref_amount = 1.0 - surface_color.x;
	EMISSION += textureLod(SCREEN_TEXTURE, ref_ofs, ROUGHNESS * 8.0).rgb * ref_amount * EXPOSURE;
	ALBEDO *= 1.0 - ref_amount;
	// Force transparency on the material (required for refraction).
	ALPHA = 1.0;
}
