// By 317GW 2024 8
shader_type spatial;

//group_uniforms Vertex;
//uniform bool set_position = true;

group_uniforms Pixel;
uniform vec2 screen_uv_offset = vec2(0.0);
uniform float pixelate: hint_range(1, 1024, 1) = 4;

uniform float brightness = 3.275; //2.245   3.275
uniform float contrast = 1.036; //1.036
uniform float saturation = 1.0;
uniform vec3 mix_colour: source_color = vec3(1.0, 0.878, 0.8); //ffe0cc

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap_anisotropic;
uniform sampler2D NORMAL_TEXTURE : hint_normal_roughness_texture, filter_nearest;

uniform float exposure_adaptation_speed : hint_range(0.0, 1.0) = 0.1;
uniform float min_exposure = 0.01;
uniform float max_exposure = 10.0;
uniform vec2 exposure_clamp = vec2(0.0, 1.0);


group_uniforms Luminance;
uniform int average_luminance_offset_x : hint_range(0, 10) = 1;
uniform int average_luminance_offset_y : hint_range(0, 10) = 1;
uniform float gaussian_sigma : hint_range(0.0001, 12) = 1.0; // 标准差
uniform float LOD1 : hint_range(0.0, 9.0) = 0.0;
uniform float LOD2 : hint_range(0.0, 9.0) = 0.0;
uniform float LuminanceA_cap = 0.0;

group_uniforms Remap;
uniform bool black_mask = false;
uniform bool ues_alpha = true;
uniform float truncut = 3;
uniform float truncut_offset : hint_range(0.0001, 0.9999) = 0.1;

uniform float original_min = 0.0;
uniform float original_max = 0.0;
uniform float target_min = 0.0;
uniform float target_max = 1.0;

group_uniforms Outline;
uniform float thickness : hint_range(0.0, 100.0);
uniform int ring_count : hint_range(1,128) = 16;
uniform float ring_offset : hint_range(0.0, 1.0, 0.01);
uniform vec4 outline_color : source_color;
uniform vec4 uv_outcolor : source_color;
uniform float clr_power = 1.0;
uniform float aspect_ratio : hint_range(0.1, 10.0, 0.01) = 1.0;
uniform bool square_border = false;
uniform vec2 outline_offset;
uniform bool max_or_add = false;


void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}


float remap(float value, float in_min, float in_max, float out_min, float out_max) {
	return out_min + (value - in_min) * (out_max - out_min) / (in_max - in_min);
}

// vec2 remapUV(vec2 value, vec2 uv) {
// 	return vec2(
// 		remap(value.x,),
// 		remap(value.y,));
// }

// 计算亮度
float luminance(vec3 color) {
	return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

// luminance texture  , float lod
float lumi_tex(sampler2D texture_outcolor, vec2 uv) {
	return luminance(textureLod(texture_outcolor, uv, LOD1).rgb);
}

// 计算平均亮度
float average_luminance(sampler2D texture_outcolor, vec2 uv, vec2 viewport_size) {
	vec2 one_pixel = 1.0 / viewport_size;
	float sum = 0.0;
	int sample_count = 0;
	for (int x = -average_luminance_offset_x; x <= average_luminance_offset_x; x++) {
		for (int y = -average_luminance_offset_y; y <= average_luminance_offset_y; y++) {
			vec2 offset = vec2(float(x), float(y)) * one_pixel;
			sum += lumi_tex(texture_outcolor, uv + offset);
			sample_count++;
		}
	}
	return sum / float(sample_count);
}

float gaussian_weight(int x, int y, float sigma) {
	float exponent = -(float(x*x) + float(y*y)) / (2.0 * sigma * sigma);
	return exp(exponent) / (TAU * sigma * sigma);
}

 float luminance_gaussian(sampler2D texture_outcolor, vec2 uv, vec2 viewport_size, float sigma) {
 	vec2 one_pixel = 1.0 / viewport_size;
 	float sum = 0.0;
 	float weight_sum = 0.0;
 	int radius = int(ceil(3.0 * sigma)); // 通常取3倍标准差作为半径

 	for (int x = -radius; x <= radius; x++) {
 		for (int y = -radius; y <= radius; y++) {
 			vec2 offset = vec2(float(x), float(y)) * one_pixel;
 			float weight = gaussian_weight(x, y, sigma);
 			sum += lumi_tex(texture_outcolor, uv + offset) * weight;
 			weight_sum += weight;
 		}
 	}
 	return sum / weight_sum;
 }



// samples a square pattern
vec2 square(float i){
	i *= 2.0;
	return (vec2(
		clamp(abs(mod(i,    2.0)-1.0),0.25,0.75),
		clamp(abs(mod(i+0.5,2.0)-1.0),0.25,0.75)
		)-0.5)*4.0;
}

vec4 texture_outcolor(sampler2D sampler, vec2 uv){  // , float lod, vec4 outcolor
	vec4 clr;
	if (uv.x > 0.0 && uv.y > 0.0 && uv.x < 1.0 && uv.y < 1.0){ // bleeding texture sampling fix
		clr = textureLod(sampler, uv, LOD2);
	}else{
		clr = uv_outcolor;
		}
	return clr;
}





void fragment() {
	vec2 one_pixel_size = 1.0 / VIEWPORT_SIZE;
	vec2 cell_size = one_pixel_size * pixelate;

	vec2 uv = SCREEN_UV;
	vec2 screen_uv = SCREEN_UV + vec2(cell_size / 2.0) + screen_uv_offset;//减去像素一半距离 对齐位置


	vec3 Color1 = textureLod(SCREEN_TEXTURE, uv, 0.0).rgb;
	vec3 luminance_color = vec3(luminance(Color1));


	// 计算当前帧的平均亮度
	float current_average_luminance = average_luminance(SCREEN_TEXTURE, uv, VIEWPORT_SIZE);
	//current_average_luminance = luminance_gaussian(SCREEN_TEXTURE, uv, VIEWPORT_SIZE, gaussian_sigma);
	// 计算曝光值
	//float exposure = 1.0 / clamp(current_average_luminance, min_exposure, max_exposure);
	// 映射范围
	float ori_min = original_min + truncut * 0.01;
	float ori_max = original_max + (truncut + (1.0/truncut_offset)-1.0) * 0.01;
	float remap_luminance = remap(current_average_luminance, ori_min, ori_max, target_min, target_max);
	vec3 luminance_v3 = vec3(remap_luminance);
	float luminance_a = clamp(-remap_luminance, 0.0, 1.0);


	//***********轮廓边缘***********
	vec2 o = outline_offset / VIEWPORT_SIZE;
	vec2 size = vec2(thickness) / VIEWPORT_SIZE;


	float alpha = luminance_a;
	if (square_border) {
		for(int i = 0; i < ring_count; ++i) {
			float r = float(i) / float(ring_count) + ring_offset;
			vec2 uv2 = uv + o + size * square(r) * vec2(aspect_ratio, 1.0);
			vec4 txe = texture(SCREEN_TEXTURE, uv2);
			alpha = max(alpha, txe.a * outline_color.a * clr_power);
		} // texture sampling fix is disabled because both with and without give the same result
	}else{
		for(int i = 0; i < ring_count; ++i) {
			float r = float(i) / float(ring_count) * TAU + ring_offset;
			vec2 uv2 = uv + o + vec2(size.x * sin(r) * aspect_ratio, size.y * cos(r));
			vec4 txe = texture_outcolor(SCREEN_TEXTURE, uv2);
			float clr = txe.a * outline_color.a * clr_power;
			if (max_or_add) {
				alpha = alpha + clr;
			}else{
				alpha = max(alpha, clr);
			}
		}
	}
	vec3 final_color = mix(outline_color.rgb, luminance_v3, luminance_a);
	//COLOR = vec4(final_color, clamp(alpha, 0.0, 1.0));
	//***********


	uv = floor(screen_uv / cell_size) * cell_size;
	vec3 Color = textureLod(SCREEN_TEXTURE, uv, 0.0).rgb;
	// 调色
	Color = mix(vec3(0.0), Color, brightness);
	Color = mix(vec3(0.5), Color, contrast);
	Color = mix(vec3(dot(vec3(1.0), Color) / 3.0), Color, saturation);
	Color *= mix_colour;

	ALBEDO = Color;
	if (black_mask) {
		ALBEDO = luminance_v3;
	}

	//ALBEDO = final_color;

	//ALBEDO = vec3(luminance(Color));
	ALBEDO = vec3(alpha);

	//float Alpha = textureLod(SCREEN_TEXTURE, uv, 0.0).a;
	//ALPHA = Alpha;
	if (ues_alpha) {
		ALPHA = luminance_a;
	}
	//ALPHA = clamp(alpha, 0.0, 1.0);
}
