// https://github.com/nekotogd/Godot_Parallax_Ice_3D
shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;

uniform sampler2D over_texture : source_color, filter_nearest_mipmap;
uniform sampler2D under_texture : source_color, filter_nearest_mipmap;
uniform sampler2D surface_normalmap : hint_normal, filter_nearest_mipmap;


uniform vec4 top_color : source_color = vec4(0.6764, 0.980092, 1.0, 1.0);
uniform float depth = 0.1;
uniform float normal_depth = 1.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.0;
uniform float metallic : hint_range(0.0, 1.0) = 0.7;
uniform float refractive_index = 0.1;



float blendOverlay_f(float base, float blend) {
	float branchless = step (base,0.5);
	return (2.0*base*blend)*branchless + (1.0-2.0*(1.0-base)*(1.0-blend))*(1.0-branchless); //This is branchless version
}


vec3 blendOverlay(vec3 base, vec3 blend) {
	return vec3(blendOverlay_f(base.r,blend.r),blendOverlay_f(base.g,blend.g),blendOverlay_f(base.b,blend.b));
}


varying vec3 ro;
varying vec3 p;
varying vec3 vertex_normal_ws;

uniform vec3 uv1_scale = vec3(0.5);
uniform vec3 uv1_offset = vec3(0.0);

varying vec3 uv1_power_normal;
varying vec3 uv1_triplanar_pos;
void vertex()
{
	ro = (VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;// Get camera position in World space coordinates
	p = ((MODEL_MATRIX)*vec4(VERTEX,1.0)).xyz;// Get fragment position in world space coordinates


	uv1_power_normal = pow(abs(NORMAL),vec3(1.0) );
	uv1_power_normal /= dot(uv1_power_normal,vec3(1.0) );

	uv1_triplanar_pos = (VERTEX * uv1_scale + uv1_offset) * vec3(1.0,-1.0, 1.0);
}


vec4 triplanar_texture(sampler2D p_sampler,vec3 p_weights,vec3 p_triplanar_pos) {
	vec4 samp = vec4(0.0);
	//p_triplanar_pos *= (250.0/256.0);
	samp+= texture(p_sampler, p_triplanar_pos.xy) * p_weights.z;
	samp+= texture(p_sampler, p_triplanar_pos.xz) * p_weights.y;
	samp+= texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0,1.0) ) * p_weights.x;
	return samp ;
}


void fragment(){
	vec3 texture_normal = triplanar_texture(surface_normalmap, uv1_power_normal, uv1_triplanar_pos).rgb;
	vec3 normal = texture_normal * 2.0 - 1.0;
	NORMAL_MAP = texture_normal;
	NORMAL_MAP_DEPTH = normal_depth;

	vec3 refraction;
	vec3 rd = normalize(p - ro - normal * refractive_index) * depth;

	vec3 texture_over = triplanar_texture(over_texture, uv1_power_normal, uv1_triplanar_pos).rgb;
	vec3 over_color = texture(over_texture, UV).rgb;

	vec3 color = blendOverlay(texture_over, top_color.rgb);
	vec2 offset = rd.xz;

	vec3 texture_under = triplanar_texture(under_texture, uv1_power_normal, uv1_triplanar_pos + rd).rgb;
	vec3 under_color = texture(under_texture, UV + offset + (normal.xy)).rgb;
	ALBEDO = blendOverlay(color, texture_under);
	ROUGHNESS = roughness;
	METALLIC = metallic;
}