// https://godotshaders.com/shader/edge-detection-shader/

//---------------------------------------------
// Edge-Detection Shader Pass 1
//
// Here we simply pass the vertex normals to the albedo
// so we can access it through the SCREEN_TEXTURE in our Shader Pass 2
// LICENSE: MIT

shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_toon,specular_disabled,shadows_disabled;

varying vec3 world_normal;

void vertex() {
	world_normal = NORMAL;
}

void fragment() {
	ALBEDO = world_normal.rgb;
}

// END OF SHADER PASS 1
//---------------------------------------------