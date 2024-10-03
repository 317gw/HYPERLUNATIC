// BY 317GW 2024 09 19
shader_type canvas_item;

// Ripple effect
uniform vec4 color: source_color = vec4(1.0);
uniform float value_all = 1.0;
uniform float ripple_speed = 1.5;
uniform float ripple_density = 10.0;
uniform float ripple_strength = 0.02;
uniform float blur_radius = 0.1;
uniform float blur_count = 2.0;

uniform sampler2D screen_texture: hint_screen_texture;


void fragment() {
	vec2 uv = SCREEN_UV;
	// Calculate angle and distance from the center of the screen
	vec2 center = vec2(0.5, 0.5);
	vec2 delta = uv - center;
	float distance = length(delta);
	float angle = atan(delta.y, delta.x);
	// Apply the ripple effect
	float x = angle * ripple_density + TIME * ripple_speed * value_all;
	//x *= value_all;
	uv.x += cos(x) * ripple_strength * distance;
	uv.y += sin(x) * ripple_strength * distance;
	// Simple blur effect
	vec4 c = vec4(0.0);
	float total = 0.0;
	float count = blur_count;
	count *= value_all;
	for (float x = -count; x <= count; x++) {
		for (float y = -count; y <= count; y++) {
			vec2 samplePos = uv + vec2(x, y) * blur_radius * 0.01 * pow(value_all, 2.0); // Blur radius
			c += texture(screen_texture, samplePos);
			total += 1.0;
		}
	}
	c /= total;
	// Output the final color
	COLOR = c * color;
}
