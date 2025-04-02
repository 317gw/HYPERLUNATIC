shader_type spatial;

void fragment() {
	vec3 color = vec3(1.0 * sin(TIME*5.0)*0.5 +0.5, 0.0, 0.0);
	ALBEDO = vec3(1.0, 0.0, 0.0);
	EMISSION = color * 2.0;
}
