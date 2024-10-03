shader_type spatial;
// https://godotshaders.com/shader/fade-by-distance-to-character/

uniform vec3 character_position;
uniform float fade_distance = 2.0;
uniform float fade_power = 1.0;

varying vec3 world_vertex;

//uniform vec4 color : source_color = vec4(0.94, 0.54, 0.15, 1.0);
void vertex() {
	world_vertex = (MODELVIEW_MATRIX * vec4(VERTEX,1.0)).xyz;
}

void fragment() {
// 计算片段与目标的距离
	float chardistance = length(character_position - world_vertex);
// 根据距离计算阿尔法值
	float alpha = smoothstep(fade_power, fade_distance, chardistance);
	//ALBEDO = color.rgb;
	ALPHA = alpha;
// 如果 alpha 为零，则丢弃片段
	if (alpha <= 0.0) {
		discard;
	}
}