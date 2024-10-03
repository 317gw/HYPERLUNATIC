// NOTE: Shader automatically converted from Godot Engine 4.2.2.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_disabled;
uniform vec4 albedo : source_color;
// 要模糊插值 → filter_nearest_mipmap 改 filter_linear_mipmap
uniform sampler2D texture_albedo : source_color,filter_nearest_mipmap,repeat_enable;
uniform sampler2D texture_multiplier : source_color,filter_nearest_mipmap,repeat_enable;
uniform sampler2D texture_add : source_color,filter_nearest_mipmap,repeat_enable,hint_default_black;
uniform sampler2D texture_gradient_tint : source_color,filter_nearest_mipmap,repeat_enable,hint_default_black;

uniform float point_size : hint_range(0,128);
uniform float roughness : hint_range(0,1);
uniform sampler2D texture_metallic : hint_default_white,filter_nearest_mipmap,repeat_enable;

uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r,filter_nearest_mipmap,repeat_enable;

uniform float specular;
uniform float metallic;
//跟教学没有使用自带的uv调整
//uniform vec3 uv1_scale;
//uniform vec3 uv1_offset;
//uniform vec3 uv2_scale;
//uniform vec3 uv2_offset;

uniform vec2 scroll_speed = vec2(0.0,0.0);
uniform vec2 effect_center = vec2(0.5);
uniform float effect_scale = 1.0;
uniform float effect_repeat = 1.0;
uniform float repeat_offset = 0.25;

uniform float power = 1.0;
uniform float glow_power = 5.0;
uniform bool use_gradient_tint = false;
uniform bool alpha_reversal = false;



// 计算极坐标UV
vec2 coordinates(vec2 uv,vec2 center,float scale,float repeat) {
	vec2 direction = uv - center;
	float radius = length(direction) * 2.0;
	float angle = atan(direction.y, direction.x) / TAU + repeat_offset;
	return(vec2(angle * repeat, radius * scale));
}

// 计算亮度
float luminance(vec3 color){
	return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

void vertex() {
	//UV=UV*uv1_scale.xy+uv1_offset.xy;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 time = scroll_speed * TIME * 0.1;
	vec2 base_uv = coordinates(UV,effect_center, effect_scale * 0.25, effect_repeat);
	vec4 image_tex = texture(texture_albedo,base_uv + time + abs(luminance(CAMERA_DIRECTION_WORLD)) * 0.0001);
	image_tex *= texture(texture_multiplier, UV);
	image_tex += texture(texture_add, UV);

	if (use_gradient_tint) {
		ALBEDO = textureLod(texture_gradient_tint, vec2(clamp(image_tex.r, 0.0, 1.0) * power, 0.0), 1.0).rgb * power;
	} else {
		ALBEDO = image_tex.rgb;
	}

	EMISSION = albedo.rgb * image_tex.rgb * vec3(glow_power);

	//临时借用texture_multiplier
	//vec4 txt_mult = texture(texture_multiplier, UV);
	//ALPHA = luminance(txt_mult.rgb);
	if (alpha_reversal) {
		ALPHA = 1.0 - ALPHA;
	}

// 金属和粗糙度，暂且没有测试
	float metallic_tex = dot(texture(texture_metallic,base_uv),metallic_texture_channel);
	METALLIC = metallic_tex * metallic;

	vec4 roughness_texture_channel = vec4(1.0,0.0,0.0,0.0);
	float roughness_tex = dot(texture(texture_roughness,base_uv),roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;

	SPECULAR = specular;
}
