// By 317GW 2024 8 9
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
uniform float alpha_pow: hint_range(0,10) = 1.0;
uniform float alpha_power: hint_range(0,1) = 1.0;
uniform float albedo_clamp_max = 10.0;
uniform sampler2D texture_cloud : source_color,filter_nearest_mipmap,repeat_enable;

group_uniforms Particles_anim;
uniform int particles_anim_h_frames = 1;
uniform int particles_anim_v_frames = 1;
uniform float frame = 0.0;
uniform bool particles_anim_loop = true; // INSTANCE_CUSTOM.z

group_uniforms Modulation;
uniform float brightness = 1.0; //
uniform float contrast = 1.0; //
uniform float saturation = 1.0;
uniform vec3 mix_color: source_color = vec3(1.0); //
uniform float noise_speed1 = 0.01;
uniform float noise_max1 : hint_range(0.0, 0.9999) = 0.5;
uniform float noise_mix1 : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D color_noise : source_color,filter_nearest_mipmap,repeat_enable;

group_uniforms AlphaNoise;
uniform float noise_speed2 = 0.01;
uniform float noise_max2 : hint_range(0.0, 0.9999) = 0.5;
uniform float noise_mix2 : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D alpha_noise : source_color,filter_nearest_mipmap,repeat_enable;

// 双向散射分布函数
group_uniforms BSDF;
uniform float roughness = 1.0; // 粗糙度
uniform float fresnel = 1.0; // 菲涅尔反射系数
uniform float bsdf_back_clamp: hint_range(-0.14,0) = -0.03;
uniform float bsdf_clamp_min: hint_range(-0.2,0) = -0.2;
uniform float bsdf_clamp_max: hint_range(0,2.0) = 1.0;
uniform float back_power = 1.0;
uniform float back_color_pow = 1.0;
uniform vec3 bsdf_color : source_color = vec3(1.0);
uniform bool enable_geometric_masking_functions = false;

group_uniforms Fade_by_distance;
uniform bool ues_fade_by_distance = false;
uniform float fade_distance = 6.0;
uniform float fade_power = 15.0;
uniform float multi = 100.0;
uniform vec3 character_position;

varying vec3 world_vertex;


void vertex() {
	world_vertex = (MODELVIEW_MATRIX * vec4(VERTEX,1.0)).xyz;

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


vec3 mixed_color(vec3 in_color, vec2 uv) {
	vec3 color = in_color;
	vec3 noise = texture(color_noise, uv + TIME * noise_speed1).rgb;
	noise = clamp(noise, 0.0, 1.0);

	//if (alpha == clamp(alpha, 0.01, noise_max2 + noise*(1.0-noise_max2))) {
		//alpha = smoothstep(alpha, alpha*noise, noise_mix2 + noise*(1.0-noise_mix2));
	//}
	color = mix(color, color*noise, noise_mix1 + noise*(1.0-noise_mix1));

	color = mix(vec3(0.0), color, brightness);
	color = mix(vec3(0.5), color, contrast);
	color = mix(vec3(dot(vec3(1.0), color) / 3.0), color, saturation);
	color *= mix_color;

	return color;
}


float noise_alpha(float in_alpha, vec2 uv) {
	float noise = texture(alpha_noise, uv + TIME * noise_speed2).r;
	noise = clamp(noise, 0.0, 1.0);
	float alpha = clamp(pow(in_alpha, alpha_pow), 0.0, 1.0);
	if (alpha == clamp(alpha, 0.01, noise_max2 + noise*(1.0-noise_max2))) {
		alpha = smoothstep(alpha, alpha*noise, noise_mix2 + noise*(1.0-noise_mix2));
	}
	// 计算片段与目标的距离
	float chardistance = length(character_position - world_vertex);
	float fade = 1.0;
	if (ues_fade_by_distance) {
		fade = smoothstep(fade_power*multi, fade_distance*multi, chardistance);
	}
	return clamp(alpha * alpha_power * fade, 0.0, 1.0);
}

void fragment() {
	vec3 color = texture(texture_cloud,UV).rgb;
	color = mixed_color(color, UV);
	color = albedo.rgb * pow(color, vec3(albedo_power)) * ex_power;
	float alpha = texture(texture_cloud,UV).a;
	ALBEDO = clamp(color / alpha, 0.0, albedo_clamp_max);
	ALPHA = noise_alpha(alpha, UV);
	if (ALPHA < 0.01) {
		discard;
	}
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
	vec4 color = texture(texture_cloud,UV);
	color.rgb = mixed_color(color.rgb, UV);

	float bsdf = (D * F * G)/(4.0 * n_dot_v * n_dot_l + 0.001); //给DIFFUSE_LIGHT乘上
	//if (n_dot_l < 0.0) {bsdf = -bsdf * back_power * pow(color.r, back_color_pow);}
	bsdf *= n_dot_l;
	if (n_dot_l < 0.0) {
		float b = back_power * pow(color.r, back_color_pow);
		bsdf *= ((-n_dot_l)*(b-1.0)+1.0);
		}
	bsdf = clamp(bsdf, bsdf_back_clamp, 1.0);

	vec3 final_color = bsdf * bsdf_color * ATTENUATION * LIGHT_COLOR;
	final_color = clamp(final_color, vec3(bsdf_clamp_min), vec3(bsdf_clamp_max));
	DIFFUSE_LIGHT += final_color;

	float alpha = noise_alpha(color.a, UV);
	ALPHA = alpha;
}
