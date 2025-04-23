shader_type spatial;
//render_mode ;

#define IS_POSTPROCESSOR
#include "res://assets/arts_graphic/shaders/library/color_dither_include.gdshaderinc"

uniform float screen_lod = 1.0;

//uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_nearest_mipmap, repeat_disable;
//uniform sampler2D NORMR_TEXTURE : hint_normal_roughness_texture, filter_nearest_mipmap, repeat_disable;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_nearest_mipmap, repeat_disable;

//void vertex() {
	//POSITION = vec4(VERTEX, 1.0);
//}

void fragment() {
	// screen_texture access inlined due to bug in shader compiler in Godot 4.2.2
	//vec4 depth = textureLod(DEPTH_TEXTURE, SCREEN_UV, screen_lod);
	vec4 color = textureLod(SCREEN_TEXTURE, SCREEN_UV, screen_lod) * vec4(albedo.rgb * albedo_strength, 1.0);
	vec2 pixel = floor(SCREEN_UV * vec2(textureSize(SCREEN_TEXTURE, 0)) / dither_pixel_size + dither_pixel_offset) + 0.5;

	float dither_value = get_dither_value(pixel);
	//ALBEDO = get_dither_color(dither_value, color).rgb;
	//ALBEDO = depth.rgb;
	ALBEDO = color.rgb;
	//ALBEDO = li.rgb;
	//ALBEDO = BACKLIGHT;
}

//void light() {
	//float light_contrib = clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION;
	//DIFFUSE_LIGHT += light_contrib * LIGHT_COLOR / PI;
//}