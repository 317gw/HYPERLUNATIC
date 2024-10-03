// https://github.com/StayAtHomeDev-Git/FPS-Godot-Basic-Setup
shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;

uniform vec4 albedo : source_color;
uniform float point_size : hint_range(0,128);

uniform float roughness : hint_range(0,1);
uniform float specular;
uniform float metallic;
uniform vec4 metallic_texture_channel;

uniform float uv1_blend_sharpness;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform float scale : hint_range(0,2) = 0.01;

varying vec3 uv1_triplanar_pos;
varying vec3 uv1_power_normal;

uniform sampler2D texture_albedo : source_color,filter_nearest_mipmap,repeat_enable;
uniform sampler2D texture_metallic : hint_default_white,filter_nearest_mipmap,repeat_enable;
uniform sampler2D texture_roughness : hint_roughness_r,filter_nearest_mipmap,repeat_enable;


// TRIPLANAR FUNCTION 三平面函数
vec4 triplanar_texture2(vec3 position, vec3 normal, vec2 offset, sampler2D noise) {
	vec4 colX = texture(noise, position.xy * scale + offset);
	vec4 colY = texture(noise, position.xz * scale + offset);
	vec4 colZ = texture(noise, position.zy * scale + offset);

	vec3 blendWeight = abs(normal);
	blendWeight = vec3(pow(blendWeight.x, uv1_blend_sharpness), pow(blendWeight.y, uv1_blend_sharpness), pow(blendWeight.z, uv1_blend_sharpness));
	blendWeight /= (blendWeight.x + blendWeight.y + blendWeight.z);

	return colX * blendWeight.x + colY * blendWeight.y + colZ * blendWeight.z;
}

vec4 triplanar_texture(sampler2D p_sampler,vec3 p_weights,vec3 p_triplanar_pos) {
	vec4 samp=vec4(0.0);
	samp+= texture(p_sampler,p_triplanar_pos.xy) * p_weights.z;
	samp+= texture(p_sampler,p_triplanar_pos.xz) * p_weights.y;
	samp+= texture(p_sampler,p_triplanar_pos.zy * vec2(-1.0,1.0)) * p_weights.x;
	return samp;
}

void vertex() {
	TANGENT = vec3(0.0,0.0,-1.0) * abs(NORMAL.x);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.y);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.z);
	TANGENT = normalize(TANGENT);

	BINORMAL = vec3(0.0,1.0,0.0) * abs(NORMAL.x);
	BINORMAL+= vec3(0.0,0.0,-1.0) * abs(NORMAL.y);
	BINORMAL+= vec3(0.0,1.0,0.0) * abs(NORMAL.z);
	BINORMAL = normalize(BINORMAL);

	uv1_power_normal=pow(abs(NORMAL),vec3(uv1_blend_sharpness));
	uv1_power_normal/=dot(uv1_power_normal,vec3(1.0));
	uv1_triplanar_pos = VERTEX * uv1_scale + uv1_offset;
	uv1_triplanar_pos *= vec3(1.0,-1.0, 1.0);
}

void fragment() {
	vec4 albedo_tex = triplanar_texture(texture_albedo,uv1_power_normal,uv1_triplanar_pos);
	ALBEDO = (albedo.rgb * albedo_tex.r) + albedo_tex.g + albedo_tex.b;
	float metallic_tex = dot(triplanar_texture(texture_metallic,uv1_power_normal,uv1_triplanar_pos),metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	vec4 roughness_texture_channel = vec4(1.0,0.0,0.0,0.0);
	float roughness_tex = dot(triplanar_texture(texture_roughness,uv1_power_normal,uv1_triplanar_pos),roughness_texture_channel);
	ROUGHNESS = (1.0 - albedo_tex.g) * roughness;
	SPECULAR = specular;
}
