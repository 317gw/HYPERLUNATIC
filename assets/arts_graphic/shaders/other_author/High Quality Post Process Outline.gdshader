shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled;

/*
	AUTHOR: Hannah "EMBYR" Crawford
	ENGINE_VERSION: 4.3

	HOW TO USE:
		1. Create a MeshInstance3D node and place it in your scene.
		2. Set its size to 2x2.
		3. Enable the "Flip Faces" option.
		4. Create a new shader material with this shader.
		5. Assign the material to the MeshInstance3D
		6. Set the MeshInstance3D as a child of your camera OR set the Geometry property extra_cull_margin as large as possible in the QuadMesh

	LIMITATIONS:
		Does not work well with TAA enabled.
*/

group_uniforms outline;
uniform vec4 outlineColor: source_color = vec4(0.0, 0.0, 0.0, 0.78);
uniform float depth_threshold = 0.025;
uniform float normal_threshold : hint_range(0.0, 1.5) = 0.5;
uniform float normal_smoothing : hint_range(0.0, 1.0) = 0.25;

group_uniforms thickness;
uniform float max_thickness: hint_range(0.0, 5.0) = 1.3;
uniform float min_thickness = 0.5;
uniform float max_distance = 75.0;
uniform float min_distance = 2.0;

group_uniforms grazing_prevention;
uniform float grazing_fresnel_power = 5.0;
uniform float grazing_angle_mask_power = 1.0;
uniform float grazing_angle_modulation_factor = 50.0;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear, repeat_disable;
uniform sampler2D NORMR_TEXTURE : hint_normal_roughness_texture, filter_linear, repeat_disable;


struct UVNeighbors {
	vec2 center;
	vec2 left;     vec2 right;     vec2 up;          vec2 down;
	vec2 top_left; vec2 top_right; vec2 bottom_left; vec2 bottom_right;
};

struct NeighborDepthSamples {
	float c_d;
	float l_d;  float r_d;  float u_d;  float d_d;
	float tl_d; float tr_d; float bl_d; float br_d;
};

UVNeighbors getNeighbors(vec2 center, float width, float aspect) {
	vec2 h_offset = vec2(width * aspect * 0.001, 0.0);
	vec2 v_offset = vec2(0.0, width * 0.001);
	UVNeighbors n;
	n.center = center;
	n.left   = center - h_offset;
	n.right  = center + h_offset;
	n.up     = center - v_offset;
	n.down   = center + v_offset;
	n.top_left     = center - (h_offset - v_offset);
	n.top_right    = center + (h_offset - v_offset);
	n.bottom_left  = center - (h_offset + v_offset);
	n.bottom_right = center + (h_offset + v_offset);
	return n;
}

float getMinimumDepth(NeighborDepthSamples ds){
	return min(ds.c_d, min(ds.l_d, min(ds.r_d, min(ds.u_d, min(ds.d_d, min(ds.tl_d, min(ds.tr_d, min(ds.bl_d, ds.br_d))))))));
}

float getLinearDepth(float depth, vec2 uv, mat4 inv_proj) {
	vec3 ndc = vec3(uv * 2.0 - 1.0, depth);
	vec4 view = inv_proj * vec4(ndc, 1.0);
	view.xyz /= view.w;
	return -view.z;
}

NeighborDepthSamples getLinearDepthSamples(UVNeighbors uvs, sampler2D depth_tex, mat4 invProjMat) {
	NeighborDepthSamples result;
	result.c_d  = getLinearDepth(texture(depth_tex, uvs.center).r, uvs.center, invProjMat);
	result.l_d  = getLinearDepth(texture(depth_tex, uvs.left).r  , uvs.left  , invProjMat);
	result.r_d  = getLinearDepth(texture(depth_tex, uvs.right).r , uvs.right , invProjMat);
	result.u_d  = getLinearDepth(texture(depth_tex, uvs.up).r    , uvs.up    , invProjMat);
	result.d_d  = getLinearDepth(texture(depth_tex, uvs.down).r  , uvs.down  , invProjMat);
	result.tl_d = getLinearDepth(texture(depth_tex, uvs.top_left).r, uvs.top_left, invProjMat);
	result.tr_d = getLinearDepth(texture(depth_tex, uvs.top_right).r, uvs.top_right, invProjMat);
	result.bl_d = getLinearDepth(texture(depth_tex, uvs.bottom_left).r, uvs.bottom_left, invProjMat);
	result.br_d = getLinearDepth(texture(depth_tex, uvs.bottom_right).r, uvs.bottom_right, invProjMat);
	return result;
}

float remap(float v, float from1, float to1, float from2, float to2) {
	return (v - from1) / (to1 - from1) * (to2 - from2) + from2;
}

float fresnel(float amount, vec3 normal, vec3 view) {
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

float getGrazingAngleModulation(vec3 pixel_normal, vec3 view) {
	float x = clamp(((fresnel(grazing_fresnel_power, pixel_normal, view) - 1.0) / grazing_angle_mask_power) + 1.0, 0.0, 1.0);
	return (x + grazing_angle_modulation_factor) + 1.0;
}

float detectEdgesDepth(NeighborDepthSamples depth_samples, vec3 pixel_normal, vec3 view) {
	float n_total =
		depth_samples.l_d +
		depth_samples.r_d +
		depth_samples.u_d +
		depth_samples.d_d +
		depth_samples.tl_d +
		depth_samples.tr_d +
		depth_samples.bl_d +
		depth_samples.br_d;

	float t = depth_threshold * getGrazingAngleModulation(pixel_normal, view);
	return step(t, n_total - (depth_samples.c_d * 8.0));
}

// This is a hack needed for this to work with Godot 4.3
// See https://github.com/godotengine/godot-docs/issues/9591
vec4 normal_roughness_compatibility(vec4 p_normal_roughness) {
    float roughness = p_normal_roughness.w;

    if (roughness > 0.5) {
        roughness = 1.0 - roughness;
    }

    roughness /= (127.0 / 255.0);
    return vec4(normalize(p_normal_roughness.xyz * 2.0 - 1.0) * 0.5 + 0.5, roughness);
}

float detectEdgesNormal(UVNeighbors uvs, sampler2D normTex, vec3 camDirWorld){
	vec3 n_u = normal_roughness_compatibility(texture(normTex, uvs.up)).xyz;
	vec3 n_d = normal_roughness_compatibility(texture(normTex, uvs.down)).xyz;
	vec3 n_l = normal_roughness_compatibility(texture(normTex, uvs.left)).xyz;
	vec3 n_r = normal_roughness_compatibility(texture(normTex, uvs.right)).xyz;
	vec3 n_tl = normal_roughness_compatibility(texture(normTex, uvs.top_left)).xyz;
	vec3 n_tr = normal_roughness_compatibility(texture(normTex, uvs.top_right)).xyz;
	vec3 n_bl = normal_roughness_compatibility(texture(normTex, uvs.bottom_left)).xyz;
	vec3 n_br = normal_roughness_compatibility(texture(normTex, uvs.bottom_right)).xyz;

	vec3 normalFiniteDifference0 = n_tr - n_bl;
	vec3 normalFiniteDifference1 = n_tl - n_br;
	vec3 normalFiniteDifference2 = n_l - n_r;
	vec3 normalFiniteDifference3 = n_u - n_d;

	float edgeNormal = sqrt(
		dot(normalFiniteDifference0, normalFiniteDifference0) +
		dot(normalFiniteDifference1, normalFiniteDifference1) +
		dot(normalFiniteDifference2, normalFiniteDifference2) +
		dot(normalFiniteDifference3, normalFiniteDifference3)
	);

	return smoothstep(normal_threshold - normal_smoothing, normal_threshold + normal_smoothing, edgeNormal);
}

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	float aspect = float(VIEWPORT_SIZE.y) / float(VIEWPORT_SIZE.x);

	UVNeighbors n = getNeighbors(SCREEN_UV, max_thickness, aspect);
	NeighborDepthSamples depth_samples = getLinearDepthSamples(n, DEPTH_TEXTURE, INV_PROJECTION_MATRIX);

	float min_d = getMinimumDepth(depth_samples);
	float thickness = clamp(remap(min_d, min_distance, max_distance, max_thickness, min_thickness), min_thickness, max_thickness);
	float fade_a = clamp(remap(min_d, min_distance, max_distance, 1.0, 0.0), 0.0, 1.0);

	n = getNeighbors(SCREEN_UV, thickness, aspect);
	depth_samples = getLinearDepthSamples(n, DEPTH_TEXTURE, INV_PROJECTION_MATRIX);

	vec3 pixel_normal = texture(NORMR_TEXTURE, SCREEN_UV).xyz;

	float depthEdges = detectEdgesDepth(depth_samples, pixel_normal, VIEW);

	float normEdges = min(detectEdgesNormal(n, NORMR_TEXTURE, CAMERA_DIRECTION_WORLD), 1.0);

	ALBEDO.rgb = outlineColor.rgb;
	ALPHA = max(depthEdges, normEdges) * outlineColor.a * fade_a;
}
