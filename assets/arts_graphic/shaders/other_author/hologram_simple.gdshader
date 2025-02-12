// https://godotshaders.com/shader/hologram-simple-canvasitem-shader/
shader_type canvas_item;

uniform int lines = 100;
uniform vec4 color1 : source_color = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec4 color2 : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float speed : hint_range(0.0, 2.0, 0.01) = 0.4;
uniform float alpha : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float noise_amount : hint_range(0.0, 1.0, 0.01) = 0.05;
uniform float effect_factor : hint_range(0.0, 1.0, 0.01) = 0.4;


void noise(in vec2 uv, inout vec4 color) {
	float a = fract(sin(dot(uv, vec2(12.9898, 78.233) * TIME)) * 438.5453) * 1.9;
	color.rgb = mix(color.rgb, vec3(a), noise_amount);
}


vec4 color_shift(in vec2 uv, in sampler2D image, vec2 shift_vector) {
	return texture(image, uv - shift_vector);
}


void fragment() {
	float lineN = floor((UV.y - TIME*speed) * float(lines));
	float line_grade = abs(sin(lineN*PI/4.0));
	float smooth_line_grade = abs(sin((UV.y - TIME*speed) * float(lines)));

	vec4 line_color = mix(color1, color2, line_grade);

	// change the "240.0" literal to control line color shifting
	COLOR = color_shift(UV, TEXTURE, vec2(1.0, 0.0)*smooth_line_grade/240.0*effect_factor);

	noise(UV, COLOR);

	COLOR.rgb = mix(COLOR.rgb, line_color.rgb, effect_factor);
	COLOR.a = alpha * COLOR.a * line_color.a;
}
