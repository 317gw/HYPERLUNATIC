// This shader is based on Minionsart's stylized fire
// https://twitter.com/minionsart/status/1132593681452683264?s=20
shader_type spatial;
render_mode blend_mix;

uniform vec4 albedo : source_color;
uniform sampler2D noise_texture;
uniform sampler2D texture_mask;
uniform float emission_intensity = 2.0;
uniform float time_scale = 3.0;
uniform vec2 texture_scale = vec2(1.0);
uniform float edge_softness = 0.1;

varying vec3 world_coord;
varying float world_x_dot;


void vertex() {
    // Billboard code, taken directly from a spatial material
    // create a spatial material, enable billboard with billboard keep scale, and then convert
    // to shader material, and it will create a shader with this code.
    mat4 mat_world = mat4(
			vec4(normalize(cross(vec3(0.0, 1.0, 0.0), MAIN_CAM_INV_VIEW_MATRIX[2].xyz)), 0.0),
			vec4(0.0, 1.0, 0.0, 0.0),
			vec4(normalize(cross(MAIN_CAM_INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
			MODEL_MATRIX[3]);
    mat_world = mat_world * mat4(
		vec4(cos(INSTANCE_CUSTOM.x),-sin(INSTANCE_CUSTOM.x), 0.0, 0.0),
		vec4(sin(INSTANCE_CUSTOM.x), cos(INSTANCE_CUSTOM.x), 0.0, 0.0),
		vec4(0.0, 0.0, 1.0, 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
	// Billboard Mode: Y-Billboard
	MODELVIEW_MATRIX = VIEW_MATRIX * mat_world;
    
    // We map the coordinates on the vertical planes xy and zy
    // we also calculate how to blend between the two based on where the world space normal
    // is pointing.
    world_coord = (mat_world * vec4(VERTEX, 1.0)).rgb;
    vec4 world_normal = (mat_world * vec4(NORMAL, 0.0));
    world_x_dot =  abs(dot(normalize(world_normal.rgb), vec3(1.0,0.0,0.0)));
}


void fragment() {
	float mask = texture(texture_mask, UV).r;
	
	vec2 time_based_pan = vec2(0.2, 1.0) * (- TIME * time_scale);
	float noise_xy = texture(noise_texture, world_coord.xy * texture_scale + time_based_pan).r;
	float noise_zy = texture(noise_texture, world_coord.zy * texture_scale + time_based_pan + vec2(0.7, 0.3)).r;
	
	float noise = mix(noise_xy, noise_zy, clamp(world_x_dot, 0.0, 1.0));
	
	ALBEDO = COLOR.rgb * albedo.rgb;
	EMISSION = ALBEDO * emission_intensity;
	
	float erosion_amount = (1.0 - COLOR.a);
	float alpha = (noise * mask) - erosion_amount;
	
	alpha = clamp(alpha, 0.0, 1.0);
	ALPHA = smoothstep(0.0, edge_softness, alpha) * albedo.a;
}