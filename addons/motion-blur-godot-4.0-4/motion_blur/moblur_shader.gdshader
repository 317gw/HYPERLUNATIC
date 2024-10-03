shader_type spatial; // 指定着色器类型为spatial
render_mode depth_test_disabled, depth_draw_never, unshaded, cull_disabled; // 设置渲染模式

uniform vec3 linear_velocity; // 线性速度
uniform vec3 angular_velocity; // 角速度（弧度）
uniform int iteration_count : hint_range(2, 50); // 迭代次数，范围2到50
uniform float intensity : hint_range(0, 1); // 强度，范围0到1
uniform float startRadius; // 开始半径
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap; // 深度纹理
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap; // 屏幕纹理


void fragment()
{ 
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).r; // 获取深度值
	
	// 将当前像素从NDC（归一化设备坐标）转换到世界坐标
	vec3 pixel_pos_ndc = vec3(SCREEN_UV*2.0-1.0, depth*2.0-1.0); 
    vec4 pixel_pos_clip = INV_PROJECTION_MATRIX * vec4(pixel_pos_ndc,1.0);
    vec3 pixel_pos_cam = pixel_pos_clip.xyz / pixel_pos_clip.w;
	vec3 pixel_pos_world = (inverse(INV_VIEW_MATRIX) * vec4(pixel_pos_cam, 1.0)).xyz;
	
	// 计算总速度，结合线性速度和角速度
	vec3 cam_pos = inverse(INV_VIEW_MATRIX)[3].xyz; // 获取相机位置
	vec3 r = pixel_pos_world - cam_pos; // 世界坐标下像素位置与相机位置的差
	vec3 total_velocity = linear_velocity + cross(angular_velocity, r); // 计算总速度，包括线性速度和角速度的叉积
	
	// 通过总速度偏移世界位置，然后投影回NDC坐标
	vec3 pixel_prevpos_world = pixel_pos_world - total_velocity; // 计算前一位置的世界坐标
	vec3 pixel_prevpos_cam =  ((INV_VIEW_MATRIX) * vec4(pixel_prevpos_world, 1.0)).xyz; // 转换到相机坐标
	vec4 pixel_prevpos_clip =  PROJECTION_MATRIX * vec4(pixel_prevpos_cam, 1.0); // 转换到裁剪空间
	vec3 pixel_prevpos_ndc = pixel_prevpos_clip.xyz / pixel_prevpos_clip.w; // 转换到NDC坐标
	
	// 计算像素在NDC空间移动的距离
	vec2 pixel_diff_ndc = pixel_prevpos_ndc.xy - pixel_pos_ndc.xy; // NDC空间的像素差
	
	vec3 col = vec3(0.0); // 初始化颜色
	float counter = 0.0; // 初始化计数器
	if(length(r) >= startRadius){ // 如果像素位置距离大于开始半径
		for (int i = 0; i < iteration_count; i++) // 迭代模糊效果
		{
			vec2 offset = pixel_diff_ndc * (float(i) / float(iteration_count) - 0.5) * intensity; // 计算偏移量
			col += textureLod(SCREEN_TEXTURE, SCREEN_UV + offset,0.0).rgb; // 累加颜色值
			counter++; // 增加计数器
		}
		ALBEDO = col / counter; // 计算平均颜色值
	}
	else
		ALBEDO = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgb; // 如果小于开始半径，使用原始颜色
}