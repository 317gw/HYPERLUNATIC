shader_type canvas_item;

uniform int iterations : hint_range(1, 10) = 3; // 模糊迭代次数
uniform float offset : hint_range(0.0, 10.0) = 2.0; // 采样偏移量
uniform float lod : hint_range(0.0, 10.0) = 2.0;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec2 uv = UV;
    vec4 color = textureLod(SCREEN_TEXTURE, uv, lod);

    // 双重模糊下采样核心算法
    for (int i = 0; i < iterations; i++) {
        color += textureLod(SCREEN_TEXTURE, uv + vec2(offset, 0.0) * SCREEN_PIXEL_SIZE, lod);
        color += textureLod(SCREEN_TEXTURE, uv + vec2(-offset, 0.0) * SCREEN_PIXEL_SIZE, lod);
        color += textureLod(SCREEN_TEXTURE, uv + vec2(0.0, -offset) * SCREEN_PIXEL_SIZE, lod);
        color += textureLod(SCREEN_TEXTURE, uv + vec2(0.0, -offset) * SCREEN_PIXEL_SIZE, lod);
        color /= 5.0; // 平均采样值
    }

    COLOR = color;
}