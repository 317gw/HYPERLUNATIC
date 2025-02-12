shader_type spatial;
render_mode blend_mix, cull_back, specular_disabled;


// Used as the height map, averaging the rgb values to get the depth value
uniform sampler2D texture_emission : source_color, hint_default_black, filter_nearest, repeat_enable;
// Applies color to texture after all the parallax math stuff, expects a GradientTexture1D
uniform sampler2D emission_color : source_color, hint_default_black, filter_nearest;
// Controls depth level of parallax effect
uniform float depth_scale = 0.1;
// Controls if values outside the mesh bounds are sampled
uniform bool discard_boundaries = false;
uniform float emission_energy;
uniform vec2 uv1_scale = vec2(1.0, 1.0);
uniform vec2 uv1_offset = vec2(0.0, 0.0);

// Determines the amount of samples for each fragment
const float min_layers = 8.0;
const float max_layers = 128.0;

#define COLOR_TO_FLOAT(color) (color.r + color.g + color.b) / 3.0


// Expects a float between (0.0, 1.0)
float flip_float(float val) {
	return -(val - 1.0);
}

// Converts provided UV coordinates to parallax UV coordinates using tex as the depth map
vec2 get_parallax_uvs(vec2 uv, vec3 view_dir, sampler2D tex) {
	vec2 vec_p = view_dir.xy / view_dir.z * -depth_scale;

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


varying mat4 model;
varying mat3 TBN;
void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;

	model = transpose(inverse(MODELVIEW_MATRIX));
	TBN = mat3(
		-(model * vec4(TANGENT, 0.0)).xyz,
		(model * vec4(BINORMAL, 0.0)).xyz,
		(model * vec4(NORMAL, 0.0)).xyz
	);
}

varying vec3 view_dir;
void fragment() {
	view_dir = normalize(normalize(-VERTEX) * TBN);
	vec2 base_uv = UV;

	vec2 parallax_uv = get_parallax_uvs(base_uv, view_dir, texture_emission);

	if (discard_boundaries) {
		if (parallax_uv.x > 1.0 || parallax_uv.x < 0.0 || parallax_uv.y > 1.0 || parallax_uv.y < 0.0) {
			discard;
		}
	}

	vec3 emission_tex = texture(texture_emission, parallax_uv).rgb;
	vec3 color_tex = texture(emission_color,vec2(COLOR_TO_FLOAT(emission_tex), 0.0)).rgb;

	EMISSION = emission_tex * color_tex * emission_energy;
}