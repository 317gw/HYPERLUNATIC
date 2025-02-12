// By 317GW 2024 7
shader_type spatial;
render_mode
	blend_mix,
	depth_prepass_alpha,
	sss_mode_skin,
	cull_disabled,
	diffuse_lambert_wrap,
	specular_schlick_ggx;


uniform vec4 albedo : source_color = vec4(1.0);
uniform float albedo_power: hint_range(0,10) = 1.0;
uniform float ex_power: hint_range(0,10) = 1.0;
uniform float alpha_power: hint_range(0,10) = 1.0;
uniform sampler2D texture_cloud : source_color,filter_nearest_mipmap,repeat_enable;

group_uniforms Particles_anim;
uniform int particles_anim_h_frames = 1;
uniform int particles_anim_v_frames = 1;
uniform float frame = 0.0;
uniform bool particles_anim_loop = true; // INSTANCE_CUSTOM.z

// 双向散射分布函数
group_uniforms BSDF;
uniform float roughness = 1.0; // 粗糙度
uniform float fresnel = 1.0; // 菲涅尔反射系数
uniform float bsdf_back_clamp: hint_range(-0.14,0) = -0.03;
uniform float bsdf_clamp_min: hint_range(-0.2,0) = -0.2;
uniform float bsdf_clamp_max: hint_range(0,2.0) = 1.0;
uniform float back_power = 1.0;
uniform vec3 bsdf_color : source_color = vec3(1.0);
uniform bool enable_geometric_masking_functions = false;


void vertex() {
	float h_frames = float(particles_anim_h_frames);
	float v_frames = float(particles_anim_v_frames);
	float particle_total_frames = float(particles_anim_h_frames * particles_anim_v_frames);
	float particle_frame = floor(frame * float(particle_total_frames) * 0.1);

	if (!particles_anim_loop) {
		particle_frame = clamp(particle_frame, 0.0, particle_total_frames - 1.0);
	} else {
		particle_frame = mod(particle_frame, particle_total_frames);
	}
	UV /= vec2(h_frames, v_frames);
	UV += vec2(
		mod(particle_frame, h_frames) / h_frames,
		floor((particle_frame + 0.5) / h_frames) / v_frames);
}

void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_cloud,base_uv);
	ALBEDO = albedo.rgb * pow(albedo_tex.rgb, vec3(albedo_power)) * ex_power;
	ALPHA *= pow(albedo_tex.a, alpha_power);
}

void light() {
	vec3 normal = normalize(NORMAL);
	vec3 view_dir = normalize(VIEW);
	vec3 light_dir = normalize(LIGHT);

	float n_dot_l = dot(normal, light_dir);
	float n_dot_v = dot(normal, view_dir);

	// 计算双向散射分布函数
	float D = pow(roughness, 2) / (PI * pow(1.0 + (pow(roughness, 2) - 1.0)* pow(n_dot_l, 2), 2.0));
	// 微表面分布函数，描述微表面的法线分布。
	float F = fresnel + (1.0 - fresnel)* pow(1.0 - n_dot_v, 5.0);
	// 菲涅尔反射系数，描述光线在表面反射的比例。
	float G = 1.0;
	if (enable_geometric_masking_functions) {
		G = min(1.0, min(
			2.0 * n_dot_v*n_dot_l / dot(view_dir, light_dir),
			2.0 * n_dot_v*n_dot_l / dot(view_dir, light_dir)
			)); // 几何遮蔽函数，描述微表面之间的遮蔽效果。
	}
//float v_dot_l = dot(view_dir, light_dir);

	float bsdf = (D * F * G)/(4.0 * n_dot_v * n_dot_l + 0.001); //给DIFFUSE_LIGHT乘上
	if (n_dot_l < 0.0) {
		bsdf = -bsdf * back_power;
	}
	bsdf = clamp(bsdf, bsdf_back_clamp, 1.0);

	vec3 final_color = bsdf * bsdf_color * ATTENUATION * LIGHT_COLOR;
	final_color = clamp(final_color, vec3(bsdf_clamp_min), vec3(bsdf_clamp_max));
	DIFFUSE_LIGHT += final_color;

	vec4 albedo_tex = texture(texture_cloud,UV);
	ALPHA *= pow(albedo_tex.a, alpha_power);
}
