// https://godotshaders.com/shader/radical-blur-shader/
shader_type canvas_item;

uniform vec2 blur_center = vec2(0.5, 0.5);
uniform float un_blur_radius_min: hint_range(0.0, 1.0) = 0.2;
uniform float un_blur_radius_max: hint_range(0.0, 1.0) = 0.5;
uniform float blur_power: hint_range(0.0, 1.0) = 0.01;
uniform int sampling_count: hint_range(1, 64) = 8;
uniform float lod = 0.5;

//uniform sampler2D screen_texture: repeat_disable;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

void fragment( )
{
	vec2 direction = SCREEN_UV - blur_center;
	vec2 direction_center = SCREEN_UV - vec2(0.5);
	if (length(direction_center) < un_blur_radius_min) {
		discard;
	}

	float r = smoothstep(un_blur_radius_min, un_blur_radius_max, length(direction_center));
	direction -= normalize(direction) * un_blur_radius_min;
	vec3 c = vec3( 0.0, 0.0, 0.0 );
	float f = 1.0 / float(sampling_count );
	for(int i=0; i < sampling_count; i++ ) {
		c += textureLod(SCREEN_TEXTURE, SCREEN_UV - blur_power * direction * float(i) * r, lod * r).rgb * f;
	}

	vec3 screen = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	COLOR.rgb = mix(screen, c, r);
}
