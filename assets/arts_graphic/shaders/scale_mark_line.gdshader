shader_type canvas_item;

group_uniforms mark_up;
uniform vec4 up_color: source_color = vec4(1.0);
uniform int up_count: hint_range(2, 100, 1) = 5;
uniform float up_width: hint_range(0.0, 0.5, 0.01) = 0.05;
uniform float up_margin_left: hint_range(-0.5, 0.5, 0.01) = 0;
uniform float up_margin_right: hint_range(-0.5, 0.5, 0.01) = 0;
uniform float up_margin_top: hint_range(0.0, 0.5, 0.01) = 0;
uniform float up_margin_bottom: hint_range(0.0, 0.5, 0.01) = 0;

group_uniforms mark_below;
uniform vec4 below_color: source_color = vec4(1.0);
uniform int below_count = 5;
uniform float below_width: hint_range(0.0, 0.5, 0.01) = 0.05;
uniform float below_margin_left: hint_range(-0.5, 0.5, 0.01) = 0;
uniform float below_margin_right: hint_range(-0.5, 0.5, 0.01) = 0;
uniform float below_margin_top: hint_range(0.0, 0.5, 0.01) = 0;
uniform float below_margin_bottom: hint_range(0.0, 0.5, 0.01) = 0;


float make_mark(vec2 uv, float left, float right, float top, float bottom) {
	return step(left, uv.x) * step(uv.x, right) * step(top, uv.y) * step(uv.y, bottom);
}

float for_mark(vec2 uv, int count, float width, float margin_left, float margin_right, float margin_top, float margin_bottom) {
	int _count = max(count, 2);
	// 1.0 = margin_left + margin_right + count * width + (count - 1) * step_length
	float step_length = (1.0 - float(_count) * width - margin_left - margin_right) / float(_count - 1);
	float mark = 0.0;
	for (int i = 0; i < _count; i++) {
		float _step = float(i) * (step_length + width) + margin_left;
		mark += make_mark(
			uv,
			_step, _step + width,
			margin_top, 1.0 - margin_bottom
			);
	}
	return mark;
}


void fragment() {
	float mark_up = for_mark(UV, up_count, up_width, up_margin_left, up_margin_right, up_margin_top, up_margin_bottom);
	float mark_below = for_mark(UV, below_count, below_width, below_margin_left, below_margin_right, below_margin_top, below_margin_bottom);

	//float mark = make_mark(UV.x, 0.1, 0.2);
	//COLOR = vec4(UV, 1.0, 1.0);
	COLOR = below_color * vec4(mark_below);
	if (mark_up > 0.0) {
		COLOR = up_color * vec4(mark_up);
	}

}
