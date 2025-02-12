shader_type spatial;
render_mode
	skip_vertex_transform,
	depth_draw_always,
	alpha_to_coverage_and_one;

#include "res://addons/godot-polyliner/shaders/include/polyliner_inc.gdshaderinc"

group_uniforms Vertex;
uniform float line_width = 0.03;
uniform bool tangent_facing = false;
uniform bool rounded = false;
uniform bool tube_normal = true;
uniform bool uv_matches_width = true;
uniform vec2 tex_scale = vec2(1.0,1.0);

uniform sampler2D width_curve : source_color;

varying float is_end;
varying vec3 world_vertex;

void vertex(){
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX,1.0)).xyz;
	world_vertex = VERTEX;
	NORMAL = mat3(MODELVIEW_MATRIX) * NORMAL;
	TANGENT = mat3(MODELVIEW_MATRIX) * TANGENT;
	BINORMAL = mat3(MODELVIEW_MATRIX) * BINORMAL;

	quick_line(line_width, rounded);

	if (uv_matches_width) { UV.x /= line_width; }


	UV.x = 1.0-UV.x;

	float line_length = UV2.x;
	UV2 = UV;
	UV2.x *= line_length;

	// correct the texture coordinates at the rounded ends
	// TODO: doesn't take angle of the rounded end into account at all
	if (rounded) {
		// the world may never know
		// why 1.414 is the exact value which fixes the texcoords
		const float SQ2 = sqrt(2.0);
		float uv_correct = -is_end;

		if (uv_matches_width) { uv_correct *= line_width*SQ2; }
		else { uv_correct *= line_width/abs(tex_scale.x); }
//		if (abs(is_end) > 0.001) {
//			float i = acos(dot(TANGENT,normalize(cross(NORMAL,normalize(VERTEX)))));
//			float xe = 1.0/(i*0.5+0.5);
//			uv_correct *= xe*abs(tex_scale.x);
//		}
		UV.x += uv_correct;
		UV2.x += uv_correct;
	}

	// godot seems to reapply the modelview transform later
	// we have no choice but to do the inverse transform
	// af1d81d fixes this
	TANGENT =  TANGENT * mat3(MODELVIEW_MATRIX);
	BINORMAL = BINORMAL * mat3(MODELVIEW_MATRIX);
}


group_uniforms Fragment;
uniform vec3 color : source_color = vec3(1.0);
uniform float alpha : hint_range(0.0,1.0,0.005) = 1.0;

uniform float metallic  : hint_range(0.0,1.0,0.005) = 0.0;
uniform float specular  : hint_range(0.0,1.0,0.005) = 0.5;
uniform float roughness : hint_range(0.0,1.0,0.005) = 0.5;
uniform bool tex_stretch = true;

uniform sampler2D texture_alb : hint_default_white, source_color;
uniform sampler2D texture_rgh : hint_default_white;

group_uniforms Fade;
uniform float fade_distance = 2.0;
uniform float fade_power = 1.0;



void fragment() {
	if (!FRONT_FACING) { NORMAL = -NORMAL; }

	if (tube_normal && !tangent_facing) {
		NORMAL_MAP = getLineTubeNormal(UV,is_end,rounded);
	}

	if (rounded && abs(is_end) > 0.0001) {
		// pure heuristics
		float softner = magic_aa(6000.0,VERTEX,VIEWPORT_SIZE);
		softner *= (1.0/line_width) * (min(abs(is_end)*2.0,1.0));
		ALPHA *= smoothstep(1.0,1.0+softner,getDistToLineCenter(UV,is_end));
	}

	vec2 uv_alb = UV2;
	if (tex_stretch) {
		uv_alb = UV;
	}
	uv_alb *= tex_scale;
	uv_alb = uv_alb.yx; // more intuitive

	vec4 alb_sample = texture(texture_alb,uv_alb.yx);
	vec4 rgh_sample = texture(texture_rgh,uv_alb.yx);

	ALBEDO = alb_sample.rgb * alb_sample.a * color;
	ALPHA = alpha;
	SPECULAR = specular;
	ROUGHNESS = roughness * rgh_sample.r;
	METALLIC = metallic;

	//ALPHA_SCISSOR_THRESHOLD = 0.001; // comment out for alpha blending
	// 计算片段与目标的距离
	float chardistance = length(vec3(0.0) - world_vertex);
// 根据距离计算阿尔法值
	float alpha2 = smoothstep(fade_power, fade_distance, chardistance);
	//ALBEDO = color.rgb;
	ALPHA *= alpha2;
// 如果 alpha 为零，则丢弃片段
	if (alpha <= 0.0) {
		discard;
	}
}
