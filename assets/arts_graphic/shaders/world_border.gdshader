// https://godotshaders.com/shader/simple-worldborder/
shader_type spatial;
render_mode unshaded, blend_add, world_vertex_coords, cull_disabled;

varying vec3 worldPos;

uniform float freq = 5.0;
uniform float speed = 1.0;
uniform float cutoff: hint_range(0.0, 1.0) = 0.5;
uniform vec3 color: source_color = vec3(0.0, 0.5, 1.0);
uniform float near_fade_min = 40;
uniform float near_fade_max = 50;

void vertex() {
	worldPos = VERTEX;
}

void fragment() {
	float distance_from_camera = distance(CAMERA_POSITION_WORLD, worldPos);
	float o = dot(worldPos, vec3(freq));
	float f = fract(speed * TIME - o);
	ALBEDO = color * step(cutoff, f);
	ALPHA = 1.0 * smoothstep(near_fade_max, near_fade_min, distance_from_camera);
}