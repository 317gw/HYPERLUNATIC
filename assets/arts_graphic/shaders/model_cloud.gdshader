shader_type spatial;
render_mode unshaded, depth_draw_always;

// 云层参数
uniform float amplitude = 0.2;  // 波动幅度
uniform float frequency = 0.8; // 波动频率
uniform float speed = 0.3;     // 波动速度
uniform vec3 wind_direction = vec3(0.5, 0.0, 0.7); // 风向

// 云层外观
uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 0.8);
uniform vec4 shadow_color : source_color = vec4(0.7, 0.7, 0.8, 0.6);
uniform float density = 0.5; // 云层密度

// 光照参数
uniform float light_absorption = 0.7;
uniform float ambient_light = 0.4;

// 高度参数
uniform float height_effect = 0.3; // 高度对位移的影响

// 噪声纹理
uniform sampler2D noise_tex : source_color;




// 顶点偏移函数
vec3 vertex_offset(vec3 vertex, vec3 normal, mat4 matrix) {
    // 基于高度调整位移强度
    float height_factor = clamp(vertex.y * height_effect, 0.0, 1.0);

    // 使用世界坐标和时间创建动态偏移
    vec3 world_pos = (matrix * vec4(vertex, 1.0)).xyz;
    vec3 offset = vec3(0.0);

    // 多层噪声叠加创建自然云运动
    vec3 sample_pos1 = world_pos * frequency + TIME * speed * normalize(wind_direction);
    vec3 sample_pos2 = world_pos * frequency * 1.7 + TIME * speed * 0.7 * normalize(wind_direction);

    // 采样噪声纹理
    float noise1 = texture(noise_tex, sample_pos1.xz * 0.1).r;
    float noise2 = texture(noise_tex, sample_pos2.xz * 0.2).r;

    // 组合噪声值
    float combined_noise = (noise1 * 0.7 + noise2 * 0.3);

    // 计算位移向量
    offset = normal * combined_noise * amplitude * height_factor;

    return offset;
}

void vertex() {
    // 应用顶点偏移
    vec3 offset = vertex_offset(VERTEX, NORMAL, MODELVIEW_MATRIX);
    VERTEX += offset;

    // 传递数据到片段着色器
    TANGENT = normalize(vec3(0.0, 1.0, 0.0) * NORMAL);
    BINORMAL = normalize(cross(NORMAL, TANGENT));
}

void fragment() {
    // 基于视角方向的光照计算
    vec3 view_dir = normalize(-VIEW);
    vec3 light_dir = normalize(-LIGHT_VERTEX);

    // 使用菲涅尔效应增强边缘光照
    float fresnel = dot(view_dir, NORMAL);
    fresnel = pow(1.0 - fresnel, 2.0);

    // 计算基础光照
    float diffuse = max(dot(NORMAL, light_dir), 0.0);
    diffuse = mix(ambient_light, 1.0, diffuse);

    // 光照吸收效果
    diffuse = pow(diffuse, light_absorption);

    // 结合菲涅尔效应
    diffuse = mix(diffuse, 1.0, fresnel * 0.3);

    // 颜色混合
    vec4 cloud_color = mix(shadow_color, base_color, diffuse);

    // 最终颜色输出
    ALBEDO = cloud_color.rgb;
    ALPHA = cloud_color.a * density;

    // 雾效增强深度感
    float fog_amount = exp(-pow(FRAGCOORD.z * 0.5, 2.0));
	ALBEDO = mix(vec3(0.8, 0.85, 0.9), ALBEDO, fog_amount);
}