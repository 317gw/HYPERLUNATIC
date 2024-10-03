shader_type canvas_item;

void fragment() {
    // 设置准星的尺寸和颜色
    vec2 center = vec2(0.5, 0.5);
    float size = 0.01;
    vec4 color = vec4(1.0, 1.0, 1.0, 1.0);

    // 创建横线
    float horizontal = smoothstep(center.x - size, center.x + size, UV.x);

    // 创建竖线
    float vertical = smoothstep(center.y - size, center.y + size, UV.y);

    // 将横线和竖线相乘以形成十字准星
    float crosshair = min(horizontal, vertical);

    // 输出最终颜色
    COLOR = color * crosshair;
}