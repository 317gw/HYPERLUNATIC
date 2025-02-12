shader_type spatial;

uniform float alpha = 0.5;
uniform vec2 uv_speed = vec2(0);

uniform sampler2D texture_noise: source_color, filter_linear_mipmap_anisotropic, repeat_enable;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;


void vertex() {
	vec2 uv = vec2(NODE_POSITION_WORLD.x, NODE_POSITION_WORLD.z);
	float size =  texture(texture_noise, uv * uv_speed).r;
	VERTEX = VERTEX * size;
}

void fragment() {

	ALPHA = alpha;
}