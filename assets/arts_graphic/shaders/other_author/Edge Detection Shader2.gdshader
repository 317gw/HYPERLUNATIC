// https://godotshaders.com/shader/edge-detection-shader/

//---------------------------------------------
// Edge-Detection Shader Pass 2
//
// Here's our fully lit and shaded model,
// but through the SCREEN_TEXTURE, we also have the world normals
// of all the visible parts of our model that the first pass gives us.
// LICENSE: MIT

shader_type spatial;
render_mode blend_mix,depth_draw_always,cull_back,diffuse_lambert,specular_disabled;
uniform vec4 albedo: source_color;
uniform sampler2D texture_albedo;
uniform float specular;
uniform float metallic;
uniform float roughness : hint_range(0,1);
uniform float edge_strength : hint_range(0,1) = 0.2;
uniform vec4 edge_color : source_color = vec4(0.5, 0.5, 0.5, 1.0);

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

// essentially a cheap "lightness" function
// returns the average of red, green and blue color channels
float vec3_avg(vec3 color) {
	return (color.r + color.g + color.b) / 3.0;
}

// transform a pixel coordinate to screen UV
vec2 pixel_to_screen_uv(vec2 viewport_size, vec2 pixel) {
	return vec2(pixel.x / viewport_size.x, pixel.y / viewport_size.y);
}

void fragment() {
	vec4 albedo_tex = texture(texture_albedo, UV);

	vec2 iuv = vec2(SCREEN_UV.x * VIEWPORT_SIZE.x, SCREEN_UV.y * VIEWPORT_SIZE.y);

	vec3 neighbour_left = texture(SCREEN_TEXTURE, pixel_to_screen_uv(VIEWPORT_SIZE, iuv + vec2(0, 0))).rgb;
	vec3 neighbour_right = texture(SCREEN_TEXTURE, pixel_to_screen_uv(VIEWPORT_SIZE, iuv + vec2(0.5, 0))).rgb;

	vec3 neighbour_top = texture(SCREEN_TEXTURE, pixel_to_screen_uv(VIEWPORT_SIZE, iuv + vec2(0, 0.0))).rgb;
	vec3 neighbour_bottom = texture(SCREEN_TEXTURE, pixel_to_screen_uv(VIEWPORT_SIZE, iuv + vec2(0, 0.5))).rgb;

	//ALBEDO = albedo.rgb * texture(texture_albedo, UV).rgb;
	ALBEDO = albedo.rgb * texture(SCREEN_TEXTURE, UV).rgb;

	// compare normals: if they differ, we draw an edge
	// by mixing in the edge_color, by edge_strength amount
	// feel free to try other ways to mix, such as multiply for more textured objects.
	if (abs(vec3_avg(neighbour_left) - vec3_avg(neighbour_right)) > 0.0) {
		ALBEDO = mix(ALBEDO, edge_color.rgb, edge_strength);
	}else if (abs(vec3_avg(neighbour_top) - vec3_avg(neighbour_bottom)) > 0.0) {
		ALBEDO = mix(ALBEDO, edge_color.rgb, edge_strength);
	}

	//METALLIC = metallic;
	//ROUGHNESS = roughness;
	//SPECULAR = specular;
}

// END OF SHADER PASS 2
//---------------------------------------------