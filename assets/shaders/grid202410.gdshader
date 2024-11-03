// By 317GW 2024 10
shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx, world_vertex_coords;

uniform vec3 back_colour: source_color = vec3(0.4);
uniform vec3 line1_colour: source_color = vec3(1.0);
uniform vec3 line2_colour: source_color = vec3(0.8);

uniform float roughness: hint_range(0,1) = 0.8;
uniform float texture_roughness_mix: hint_range(0,1) = 0.9;
uniform float specular = 0.5;

uniform float uv1_blend_sharpness = 1.0;
uniform vec3 uv1_scale = vec3(0.5);
uniform vec3 uv1_offset = vec3(0.0);

uniform sampler2D texture_grid: source_color,filter_nearest_mipmap,repeat_enable;
uniform sampler2D texture_roughness: hint_roughness_r,filter_nearest_mipmap,repeat_enable;

varying vec3 uv1_power_normal;
varying vec3 uv1_triplanar_pos;
varying vec3 uv2_triplanar_pos;


void vertex() {
	TANGENT =  vec3(0.0, 0.0,-1.0) * abs(NORMAL.x);
	TANGENT += vec3(1.0, 0.0, 0.0) * abs(NORMAL.y);
	TANGENT += vec3(1.0, 0.0, 0.0) * abs(NORMAL.z);
	TANGENT =  normalize(TANGENT);

	BINORMAL =  vec3(0.0, 1.0, 0.0) * abs(NORMAL.x);
	BINORMAL += vec3(0.0, 0.0,-1.0) * abs(NORMAL.y);
	BINORMAL += vec3(0.0, 1.0, 0.0) * abs(NORMAL.z);
	BINORMAL =  normalize(BINORMAL);

	uv1_power_normal = pow(abs(NORMAL),vec3(uv1_blend_sharpness) );
	uv1_power_normal /= dot(uv1_power_normal,vec3(1.0) );

	vec3 vertex_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	uv1_triplanar_pos = (VERTEX * uv1_scale + uv1_offset) * vec3(1.0,-1.0, 1.0);
	uv2_triplanar_pos = (VERTEX * uv1_scale + uv1_offset) * vec3(1.0,-1.0, 1.0);
}


vec4 triplanar_texture(sampler2D p_sampler,vec3 p_weights,vec3 p_triplanar_pos) {
	vec4 samp = vec4(0.0);
	//p_triplanar_pos *= (250.0/256.0);
	samp+= texture(p_sampler, p_triplanar_pos.xy) * p_weights.z;
	samp+= texture(p_sampler, p_triplanar_pos.xz) * p_weights.y;
	samp+= texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0,1.0) ) * p_weights.x;
	return samp ;
}


void fragment() {
	//vec3 VERTEX_WORLD = CaMERA
	vec4 albedo_tex = triplanar_texture(texture_grid, uv1_power_normal, uv1_triplanar_pos);
	ALBEDO = (back_colour * albedo_tex.r) + (line1_colour * albedo_tex.g ) + (line2_colour * albedo_tex.b);

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(triplanar_texture(texture_roughness, uv1_power_normal, uv2_triplanar_pos), roughness_texture_channel);
	roughness_tex = mix(roughness_tex, (1.0 - albedo_tex.g), texture_roughness_mix);
	ROUGHNESS = roughness_tex * roughness;
	SPECULAR = specular;
}
