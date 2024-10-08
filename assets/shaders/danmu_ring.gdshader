shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_schlick_ggx, unshaded;

group_uniforms Color;
uniform vec4 albedo:  source_color;
uniform sampler2D texture_albedo:  source_color, filter_linear_mipmap, repeat_enable;

group_uniforms Circle;
uniform float outer_radius: hint_range(0.0, 1.0) = 1.0;
uniform float inner_radius: hint_range(0.0, 1.0) = 0.75;
uniform float blur: hint_range(0.0, 1.0, 0.0001) = 0.005;
uniform bool blur_blend_add = false;

void vertex() {
	// Billboard Mode: Enabled
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			MAIN_CAM_INV_VIEW_MATRIX[0],
			MAIN_CAM_INV_VIEW_MATRIX[1],
			MAIN_CAM_INV_VIEW_MATRIX[2],
			MODEL_MATRIX[3]);
}

float remap(float i_min, float i_max, float o_min, float o_max, float val) {
	float t = (val - i_min) / (i_max - i_min);
	return o_min + (o_max - o_min) * t;
}

vec2 rotate_uv(vec2 uv, vec2 pivot, float rotation) {
	float cosa = cos(rotation);
	float sina = sin(rotation);
	uv -= pivot;
	return vec2(
		cosa * uv.x - sina * uv.y,
		cosa * uv.y + sina * uv.x
	) + pivot;
}

float circle(vec2 uv, float value) {
	float d = length(uv);
	float t = (
		smoothstep(inner_radius + blur, inner_radius - blur, d) - 
		smoothstep(outer_radius + blur, outer_radius - blur, d) );
	return t;
}

void fragment() {
	vec2 uv = (UV * 2.0) - 1.0;
	vec2 origin = vec2(0.0, 0.0);
	uv = rotate_uv(uv, origin, TAU);
	float c = circle(uv, 1.0);
	if (blur_blend_add) {
		ALBEDO = vec4(c).rgb * albedo.rgb;
		ALPHA = vec4(c).a;
	} else {
		ALBEDO = albedo.rgb;
		ALPHA = -vec4(c).a;
	}
}
