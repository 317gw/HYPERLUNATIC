shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx, vertex_lighting, depth_prepass_alpha;

uniform sampler2D texture_albedo : source_color, filter_nearest_mipmap, repeat_enable;
uniform float emission = 0.4;

uniform vec3 uv1_scale = vec3(1.0);
uniform vec3 uv1_offset;

varying vec4 color_lucency;


void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;

	// Billboard Mode: Enabled
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			MAIN_CAM_INV_VIEW_MATRIX[0],
			MAIN_CAM_INV_VIEW_MATRIX[1],
			MAIN_CAM_INV_VIEW_MATRIX[2],
			MODEL_MATRIX[3]);

	// Billboard Keep Scale: Enabled
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
			vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
			vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
			vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);

	color_lucency = INSTANCE_CUSTOM;
}


void fragment() {
	vec2 base_uv = UV;

	vec4 albedo_tex = texture(texture_albedo, base_uv);
	ALBEDO = mix(color_lucency.rgb, COLOR.rgb, albedo_tex.g);
	ALPHA = mix(color_lucency.a, COLOR.a, albedo_tex.g) * albedo_tex.a;
	EMISSION = ALBEDO * ALPHA * emission;
}
