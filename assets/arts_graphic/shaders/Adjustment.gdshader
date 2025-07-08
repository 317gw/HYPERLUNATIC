shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled;

uniform vec3 replace : source_color = vec3(1.0);
uniform vec3 target : source_color = vec3(1.0);
// 权重（H色相权重较高）
uniform float hue_weight: hint_range(0.0, 1.0) = 0.7;
uniform float sat_weight: hint_range(0.0, 1.0) = 0.2;
uniform float val_weight: hint_range(0.0, 1.0) = 0.1;
uniform float replace_power: hint_range(0.0, 100.0) = 1.0;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear, repeat_disable;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// HSV转RGB
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float hue_lerp(float h1, float h2, float t) {
    float delta = mod(h2 - h1 + 0.5, 1.0) - 0.5; // 计算最短方向差值（-0.5~0.5）
    return mod(h1 + delta * t, 1.0); // 沿最短方向插值
}

void fragment() {
	vec3 screen = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;

    // 转换为HSV
	vec3 screen_hsv = rgb2hsv(screen);
    vec3 target_hsv = rgb2hsv(target);
    vec3 replace_hsv = rgb2hsv(replace);

    // 计算HSV差异
    float hue_diff = abs(screen_hsv.r - target_hsv.r);
    hue_diff = min(hue_diff, 1.0 - hue_diff); // 处理色相环形差异
    float sat_diff = abs(screen_hsv.g - target_hsv.g);
    float val_diff = abs(screen_hsv.b - target_hsv.b);

    // 加权计算总差异（0~1）
    float total_diff = (
        hue_weight * hue_diff +
        sat_weight * sat_diff +
        val_weight * val_diff
    );

    // 相似度 = 1 - 差异（可调整）
    float similarity = clamp(pow((1.0 - total_diff), replace_power), 0.0, 1.0);

	//float screen_gray = 0.299 * screen.r + 0.587 * screen.g + 0.114 * screen.b;
	//ALBEDO = mix(screen, replace * screen_gray, vec3(similarity));

	//float lerp_h;
	//float delta1 = (target_hsv.x - screen_hsv.x);
	//float delta2 = (screen_hsv.x - target_hsv.x);
	//if (delta1 <= delta2)
		//lerp_h = (screen_hsv.x + delta1 * similarity);
	//else
		//lerp_h = (screen_hsv.x - delta2 * similarity);

	ALBEDO = hsv2rgb(vec3(hue_lerp(screen_hsv.x, replace_hsv.x, similarity), screen_hsv.y, screen_hsv.z));
	//ALBEDO = hsv2rgb(vec3(lerp_h, screen_hsv.y, screen_hsv.z));
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
