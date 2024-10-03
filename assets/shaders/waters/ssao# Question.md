# Question

@FCPS 如何在gdshader着色器中实现ssao

# Answer

在 Godot 中实现屏幕空间环境遮挡（SSAO）可以通过编写自定义的 `gdshader` 着色器来实现。SSAO 是一种用于模拟环境光遮挡的技术，通过在屏幕空间中对每个像素周围的区域进行采样，来计算该像素的遮挡因子。以下是一个简单的 SSAO 实现步骤和示例代码。

### 1. 准备输入数据
SSAO 需要以下输入数据：
- 视图空间中的顶点位置（`g_buffer_pos`）
- 视图空间中的顶点法线（`g_buffer_norm`）
- 随机向量纹理（`g_random`）

### 2. 编写 SSAO 着色器

以下是一个简单的 SSAO 着色器的示例代码：

```glsl
shader_type spatial;

uniform sampler2D g_buffer_pos;
uniform sampler2D g_buffer_norm;
uniform sampler2D g_random;

uniform float random_size;
uniform float g_sample_rad;
uniform float g_intensity;
uniform float g_scale;
uniform float g_bias;

void fragment() {
    vec3 p = texture(g_buffer_pos, SCREEN_UV).xyz;
    vec3 n = normalize(texture(g_buffer_norm, SCREEN_UV).xyz * 2.0 - 1.0);
    vec2 rand = normalize(texture(g_random, SCREEN_SIZE * SCREEN_UV / random_size).xy * 2.0 - 1.0);
    
    float ao = 0.0;
    float rad = g_sample_rad / p.z;
    
    vec2 vec[4] = vec2[](
        vec2(1, 0),
        vec2(-1, 0),
        vec2(0, 1),
        vec2(0, -1)
    );
    
    int iterations = 4;
    for (int j = 0; j < iterations; ++j) {
        vec2 coord1 = reflect(vec[j], rand) * rad;
        vec2 coord2 = vec2(coord1.x * 0.707 - coord1.y * 0.707, coord1.x * 0.707 + coord1.y * 0.707);
        
        ao += doAmbientOcclusion(SCREEN_UV, coord1 * 0.25, p, n);
        ao += doAmbientOcclusion(SCREEN_UV, coord2 * 0.5, p, n);
        ao += doAmbientOcclusion(SCREEN_UV, coord1 * 0.75, p, n);
        ao += doAmbientOcclusion(SCREEN_UV, coord2, p, n);
    }
    
    ao /= float(iterations) * 4.0;
    
    ALBEDO = vec3(1.0 - ao * g_intensity);
}

float doAmbientOcclusion(vec2 tcoord, vec2 uv, vec3 p, vec3 cnorm) {
    vec3 diff = texture(g_buffer_pos, tcoord + uv).xyz - p;
    vec3 v = normalize(diff);
    float d = length(diff) * g_scale;
    return max(0.0, dot(cnorm, v) - g_bias) * (1.0 / (1.0 + d));
}
```

### 3. 解释代码

- **输入数据**：
  - `g_buffer_pos`：视图空间中的顶点位置纹理。
  - `g_buffer_norm`：视图空间中的顶点法线纹理。
  - `g_random`：随机向量纹理，用于增加采样的随机性。

- **采样**：
  - 在 `fragment` 函数中，对当前像素周围的区域进行采样，计算每个采样点的遮挡贡献。
  - 使用 `doAmbientOcclusion` 函数计算每个采样点的遮挡因子。

- **遮挡因子计算**：
  - `doAmbientOcclusion` 函数计算每个采样点的遮挡因子，考虑了法线方向和距离衰减。

- **结果应用**：
  - 最终的遮挡因子 `ao` 被应用到 `ALBEDO` 中，通过 `1.0 - ao * g_intensity` 来调整环境光的颜色。

### 4. 调整参数

你可以通过调整以下参数来控制 SSAO 的效果：
- `g_sample_rad`：采样半径。
- `g_intensity`：遮挡因子的强度。
- `g_scale`：距离衰减的比例。
- `g_bias`：遮挡的最小阈值。

### 5. 进一步优化

- **模糊处理**：为了减少噪点，可以在 SSAO 计算后应用一个模糊处理。
- **LOD 系统**：可以根据距离调整采样数量，以提高性能。

通过以上步骤，你可以在 Godot 中实现一个简单的 SSAO 效果。根据需要，你可以进一步优化和调整参数，以获得更好的视觉效果。

**Reference**   
[1][3d-game-shaders-for-beginners/sections/ssao.md at master - GitHub](https://github.com/lettier/3d-game-shaders-for-beginners/blob/master/sections/ssao.md)  
[2][[ShaderX 7] 6.1 屏幕空间环境遮挡SSAO - 知乎 - 知乎专栏](https://zhuanlan.zhihu.com/p/350927580)  
[3][Shading language — Godot Engine (stable) documentation in English](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html)  
[4][A Simple and Practical Approach to SSAO - GameDev.net](https://gamedev.net/tutorials/programming/graphics/a-simple-and-practical-approach-to-ssao-r2753/)  
[5][你的第一个着色器 — Godot Engine (4.x) 简体中文文档](https://docs.godotengine.org/zh-cn/4.x/tutorials/shaders/your_first_shader/index.html)