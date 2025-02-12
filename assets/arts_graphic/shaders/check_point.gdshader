shader_type spatial;
render_mode blend_add, cull_disabled, shadows_disabled, specular_disabled, unshaded;

uniform sampler2D noise_texture: source_color, filter_linear;
uniform float noise_speed = 0.5;
uniform float noise_range = 0.3;
uniform vec4 color : source_color = vec4(0.6764, 0.980092, 1.0, 1.0);
uniform float round_scale = 10.0;
uniform vec2 uv_scale = vec2(0.5);
uniform vec2 uv_offset = vec2(0.0);


void vertex(){
	float t = TIME * noise_speed;
	vec4 _noise_texture = texture(noise_texture, UV + t);
	float n = _noise_texture.r * _noise_texture.g;
	VERTEX *= vec3(1.0, 1.0 + sin(t*n*0.05) * 0.1 + n * noise_range, 1.0);
}


void fragment(){
	vec2 uv = UV * uv_scale + uv_offset;
	ALBEDO = color.rgb;
	EMISSION = color.rgb;
	ALPHA = clamp(round(uv.y * round_scale)/round_scale * color.a, 0.0, 1.0);
}