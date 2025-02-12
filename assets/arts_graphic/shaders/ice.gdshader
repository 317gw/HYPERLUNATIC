shader_type spatial;
render_mode blend_mix, cull_back, specular_disabled;

uniform sampler2D over_texture: source_color, filter_nearest;
uniform sampler2D under_texture: source_color, filter_linear;

uniform vec4 top_color: source_color = vec4(0.6764, 0.980092, 1.0, 1.0);
uniform float depth = 0.1;
uniform float parallax_mix: hint_range(0.0, 1.0) = 0.5;
// Determines the amount of samples for each fragment
uniform float min_layers: hint_range(0.0, 16.0) = 8.0;
uniform float max_layers: hint_range(0.0, 256.0) = 128.0;
uniform float roughness: hint_range(0.0, 1.0) = 0.0;
uniform float metallic: hint_range(0.0, 1.0) = 0.7;

uniform vec3 uv1_scale = vec3(0.5);
uniform vec3 uv1_offset = vec3(0.0);

varying vec3 uv1_power_normal;
varying vec3 uv1_triplanar_pos;

varying mat3 TBN;

void vertex() {
	uv1_power_normal = pow(abs(NORMAL),vec3(1.0) );
	uv1_power_normal /= dot(uv1_power_normal,vec3(1.0) );

	uv1_triplanar_pos = (VERTEX * uv1_scale + uv1_offset) * vec3(1.0,-1.0, 1.0);

	mat4 model = transpose(inverse(MODELVIEW_MATRIX));
	TBN = mat3(
		-(model * vec4(TANGENT, 0.0)).xyz,
		(model * vec4(BINORMAL, 0.0)).xyz,
		(model * vec4(NORMAL, 0.0)).xyz
	);
}


vec4 triplanar_texture_nearest(sampler2D p_sampler,vec3 p_weights,vec3 p_triplanar_pos) {
	vec4 samp = vec4(0.0);
	samp+= texture(p_sampler, p_triplanar_pos.xy) * p_weights.z;
	samp+= texture(p_sampler, p_triplanar_pos.xz) * p_weights.y;
	samp+= texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0,1.0) ) * p_weights.x;
	return samp ;
}


vec2 triplanar_uv(vec3 p_weights,vec3 p_triplanar_pos) {
	vec2 _x = p_triplanar_pos.zy * p_weights.x * vec2(-1.0,1.0);
	vec2 _y = p_triplanar_pos.xz * p_weights.y;
	vec2 _z = p_triplanar_pos.xy * p_weights.z;
	return _x + _y + _z;
}


#define COLOR_TO_FLOAT(color) (color.r + color.g + color.b) / 3.0

// Expects a float between (0.0, 1.0)
float flip_float(float val) {
	return -(val - 1.0);
}

// Converts provided UV coordinates to parallax UV coordinates using tex as the depth map
vec2 get_parallax_uvs(vec2 uv, vec3 view_dir, sampler2D tex) {
	vec2 vec_p = view_dir.xy / view_dir.z * depth;

	// Steep Parallax Mapping
	float num_layers = mix(min_layers, max_layers, max(dot(vec3(0.0, 0.0, 1.0), view_dir), 0.0));
	float shift_amt = 1.0 / num_layers;
	vec2 delta_tex_coords = vec_p / num_layers;
	vec2 cur_tex_coords = uv;
	float cur_layer_depth = 0.0;
	float cur_depth = flip_float(COLOR_TO_FLOAT(texture(tex, cur_tex_coords)));
	while(cur_layer_depth < cur_depth) {
		cur_tex_coords -= delta_tex_coords;
		cur_depth = flip_float(COLOR_TO_FLOAT(texture(tex, cur_tex_coords)));
		cur_layer_depth += shift_amt;
	}

	// Parallax Occlusion Mapping
	vec2 prev_tex_coords = cur_tex_coords + delta_tex_coords;
	float after_depth = cur_depth - cur_layer_depth;
	float before_depth = flip_float(COLOR_TO_FLOAT(texture(tex, prev_tex_coords))) - cur_layer_depth + shift_amt;
	float weight = after_depth / (after_depth - before_depth);
	vec2 final_tex_coords = prev_tex_coords * weight + cur_tex_coords * (1.0 - weight);

	return final_tex_coords;
}


void fragment(){
	vec2 base_uv = triplanar_uv(uv1_power_normal, uv1_triplanar_pos);

	vec3 texture_over = triplanar_texture_nearest(over_texture, uv1_power_normal, uv1_triplanar_pos).rgb;

	vec3 view_dir = normalize(normalize(-VERTEX) * TBN);
	vec2 parallax_uv = get_parallax_uvs(base_uv, view_dir, under_texture);
	vec3 emission_tex = texture(under_texture, parallax_uv).rgb;

	ALBEDO = mix(texture_over, emission_tex, parallax_mix);
	ROUGHNESS = roughness;
	METALLIC = metallic;
}