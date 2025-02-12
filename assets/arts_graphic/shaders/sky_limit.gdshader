shader_type spatial;
render_mode blend_mix, specular_disabled, cull_disabled, depth_prepass_alpha, world_vertex_coords, shadows_disabled;

uniform sampler2D noise_texture: source_color, filter_linear;

uniform vec3 color: source_color = vec3(0.6764, 0.980092, 1.0);
uniform float alpha = 1.0;
uniform float parallax_mix: hint_range(0.0, 1.0) = 0.5;

uniform float near_fade_min = 40;
uniform float near_fade_max = 50;

uniform vec3 uv_scale = vec3(0.5);
uniform vec3 uv_offset = vec3(0.0);
//uniform vec2 _offset = vec2(0.0);
varying vec3 uv1_power_normal;
varying vec3 uv1_triplanar_pos;
varying vec3 worldPos;


vec4 triplanar_texture_nearest(sampler2D p_sampler,vec3 p_weights,vec3 p_triplanar_pos) {
	vec4 samp = vec4(0.0);
	samp+= texture(p_sampler, p_triplanar_pos.xy) * p_weights.z;
	samp+= texture(p_sampler, p_triplanar_pos.xz) * p_weights.y;
	samp+= texture(p_sampler, p_triplanar_pos.zy) * p_weights.x;
	return samp ;
}


void vertex() {
	uv1_power_normal = pow(abs(NORMAL),vec3(1.0) );
	uv1_power_normal /= dot(uv1_power_normal,vec3(1.0) );
	uv1_triplanar_pos = (VERTEX * uv_scale + uv_offset + TIME * 0.01) * vec3(1.0,-1.0, 1.0);
	worldPos = VERTEX;
}


void fragment(){
	float distance_from_camera = distance(CAMERA_POSITION_WORLD, worldPos);
	ALPHA = smoothstep(near_fade_max, near_fade_min, distance_from_camera);
	if (ALPHA < 0.01){
		discard;
	}
	
	vec2 uv = UV * uv_scale.xy + uv_offset.xy;
	float _texture = triplanar_texture_nearest(noise_texture, uv1_power_normal, uv1_triplanar_pos).r;
	ALBEDO = color;
	//EMISSION = color;
	ALPHA *= alpha * step(_texture, parallax_mix + 0.05 * sin(TIME) * _texture);
}