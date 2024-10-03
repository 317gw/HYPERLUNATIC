shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_disabled,diffuse_burley,specular_schlick_ggx,unshaded;

uniform vec4 albedo_f : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float inner_alpha = 0.0;
uniform float Strength = 2.20;

void fragment() {
	//This was partly converted from a visual shader:
	// VectorOp:17
	vec3 n_out17p0 = NORMAL * VIEW;
	// VectorDecompose:18
	float n_out18p2 = n_out17p0.z;
	// FloatParameter:21
	float n_out21p0 = Strength;
	// FloatOp:20
	float n_out20p0 = n_out18p2 * n_out21p0;
	// FloatFunc:19
	float n_out19p0 = 1.0 - n_out20p0;
	// FloatOp:23
	float n_out23p0 = min(max(n_out19p0, 0.0),1.0);
	ALBEDO = albedo_f.rgb;
	ALPHA = min(inner_alpha+n_out23p0,1.0);
}
