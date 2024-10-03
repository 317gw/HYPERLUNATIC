// By 317GW 2024 7
shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_disabled;

uniform vec2 scroll_speed = vec2(0.0,0.0);
uniform vec2 effect_center = vec2(0.5);

uniform float effect_scale = 1.0;
uniform float effect_repeat = 1.0;
uniform float repeat_offset = 0.25;

uniform float ring_noise_scale = 1.0;
uniform float ring_noise_offset = 1.0;

uniform float edge_smooth: hint_range(0.01,10) = 0.01;
uniform float range: hint_range(0,2) = 0.9;
uniform float convexity = -0.2;

uniform float glow_power = 5.0;
uniform float light_ring_power = 10.0;
uniform float dark_ring_power = 10.0;

uniform vec4 albedo : source_color;

// 要模糊插值 → filter_nearest_mipmap 改 filter_linear_mipmap
uniform sampler2D texture_albedo : source_color,filter_nearest_mipmap,repeat_enable;
uniform sampler2D ring_noise : source_color,filter_nearest_mipmap,repeat_enable,hint_default_black;
//uniform sampler2D ring_noise_big : source_color,filter_nearest_mipmap,repeat_enable,hint_default_black;
uniform sampler2D texture_extra_light : source_color,filter_nearest_mipmap,repeat_enable;
uniform sampler2D texture_extra_dark : source_color,filter_nearest_mipmap,repeat_enable;

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
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 camera_offset = vec2((luminance(CAMERA_DIRECTION_WORLD))) * 0.0001; // 相机位移模拟
	vec2 time = scroll_speed * TIME * 0.1 + camera_offset; // 时间偏移
	vec2 base_uv = coordinates(UV,effect_center, effect_scale, effect_repeat);
	vec4 image_tex = texture(texture_albedo,base_uv + time);
	//float extra_light = luminance(texture(texture_extra_light, UV).rgb);
	float tex_noise = texture(ring_noise, base_uv + time).x * convexity - base_uv.y + range; // 环形噪声
	float glow = smoothstep(0.0, 0.1 * edge_smooth, tex_noise);
	ALPHA = glow; // * extra_light
	ALBEDO = image_tex.rgb;
	EMISSION = albedo.rgb * image_tex.rgb * vec3(glow_power);
	EMISSION += image_tex.rgb * vec3(light_ring_power) * texture(texture_extra_light, UV).rgb;
	ALBEDO -= image_tex.rgb * vec3(dark_ring_power) * texture(texture_extra_dark, UV).rgb;
	EMISSION -= image_tex.rgb * vec3(dark_ring_power) * texture(texture_extra_dark, UV).rgb;
}
