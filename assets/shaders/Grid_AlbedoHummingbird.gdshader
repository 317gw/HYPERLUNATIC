shader_type spatial;

varying vec3 uv1_triplanar_pos;
varying vec3 uv1_power_normal;

uniform float uv1_blend_sharpness;
uniform float scale : hint_range(0,2) = 0.01;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform bool use_embellishments = true;

// 网格
group_uniforms Grid;
uniform float subdivisions : hint_range(1, 1024, 1.0) = 32; // 细分网格的数量
uniform float grid_width : hint_range(0.0, 1.0, 0.01) = 0.02; // 网格线的宽度
uniform vec3 background_color : source_color = vec3(0.2, 0.2, 0.2); // 背景颜色，默认深灰色
uniform vec3 background_color_two : source_color = vec3(0.1, 0.1, 0.1); // 第二种背景颜色，默认更深
uniform vec3 grid_color : source_color = vec3(0.5, 0.5, 0.5); // 网格线的颜色，默认灰色

// 虚线
group_uniforms Dashed;
uniform float dashed_scale_x : hint_range(0.0, 0.99, 0.01) = 0.02; // 水平虚线的比例
uniform float dashed_scale_y : hint_range(0.0, 0.99, 0.01) = 0.02; // 垂直虚线的比例
uniform float dashed_count_x : hint_range(0.0, 16.0, 1.0) = 1.0; // 水平虚线的数量
uniform float dashed_count_y : hint_range(0.0, 16.0, 1.0) = 1.0; // 垂直虚线的数量

// 点
group_uniforms Point;
uniform float point_width : hint_range(0.0, 1.0, 0.01) = 0.021; // 点的宽度
uniform vec3 point_color : source_color = vec3(0.0, 0.0, 0.0); // 点的颜色
uniform float point_scale_x : hint_range(0.0, 1.0, 0.01) = 0.05; // 点的水平缩放
uniform float point_scale_y : hint_range(0.0, 1.0, 0.01) = 0.05; // 点的垂直缩放

// 内部网格
group_uniforms InsideGrid;
uniform float inside_width : hint_range(0.0, 1.0, 0.01) = 0.01; // 内部网格的宽度
uniform float inside_subdivisions : hint_range(1, 9, 1) = 6; // 内部网格的细分数量
uniform vec3  inside_color : source_color = vec3(0.4, 0.4, 0.4); // 内部网格的颜色
uniform float in_dashed_scale_x : hint_range(0.0, 0.99, 0.01) = 0.3; // 内部虚线的水平缩放
uniform float in_dashed_scale_y : hint_range(0.0, 0.99, 0.01) = 0.3; // 内部虚线的垂直缩放
uniform float in_dashed_count_x : hint_range(0.0, 18.0, 1.0) = 6.0; // 内部虚线的水平数量
uniform float in_dashed_count_y : hint_range(0.0, 18.0, 1.0) = 6.0; // 内部虚线的垂直数量


// 网格函数
float grid(vec2 uv, vec2 lineWidth,bool check) {
	// 计算uv的导数
	vec4 uvDDXY = vec4(dFdx(uv), dFdy(uv));
	vec2 uvDeriv = vec2(length(uvDDXY.xz), length(uvDDXY.yw));
	// 判断是否需要反转线条宽度
	bvec2 invertLine = bvec2(lineWidth.x > 0.5, lineWidth.y > 0.5); //RV
	vec2 targetWidth = vec2(
		invertLine.x ? 1.0 - lineWidth.x : lineWidth.x,
		invertLine.y ? 1.0 - lineWidth.y : lineWidth.y
		);
	// 计算抗锯齿的线条宽度
	vec2 lineAA = uvDeriv * 1.5;
	vec2 gridUV = abs((fract(uv)) * 2.0 - 1.0);
	// 根据check参数调整线条宽度和抗锯齿
	if (check == true){
		targetWidth = vec2(1.0);
		lineAA *= 1.5;

		float index = 0.0;
		index += step(1.0, mod(uv.x, 2.0));
		index += step(1.0, mod(uv.y, 2.0)) * 2.0;

		if (index == 1.0 || index == 2.0) {
			lineAA = -lineAA;
		}
	} else  {
		gridUV = vec2(
			invertLine.x ? gridUV.x : 1.0 - gridUV.x,
			invertLine.y ? gridUV.y : 1.0 - gridUV.y
		);
	}
	// 计算绘制宽度
	vec2 drawWidth = clamp(targetWidth, uvDeriv, vec2(1.0));
	vec2 gridBase = smoothstep(drawWidth + lineAA, drawWidth - lineAA, gridUV);
	//
	gridBase *= clamp(targetWidth / drawWidth, 0.0, 1.0);
	gridBase = mix(gridBase , targetWidth , clamp((uvDeriv * 2.0 - 1.0) , 0.0, 1.0));
	gridBase.x = invertLine.x ? 1.0 - gridBase.x : gridBase.x;
	gridBase.y = invertLine.y ? 1.0 - gridBase.y : gridBase.y;

	return mix(gridBase.x, 1.0, gridBase.y);
}


// 虚线网格函数
float dashed_grid(vec2 uv, vec2 lineWidth, vec2 dot_width, vec2 count, float add){
	lineWidth = 1.0 - lineWidth; // 倒置宽度值
	float gridX = 1.0 - grid(vec2(uv.x * count.x, uv.y + add), vec2(dot_width.x, lineWidth.x), false);
	float gridY = 1.0 - grid(vec2(uv.y * count.y, uv.x + add), vec2(dot_width.y, lineWidth.y), false);
	float grid = mix(gridX, 1.0, gridY); // 合并遮罩X，Y
	return grid;
}


// 获取世界坐标uv
void vertex() {
	TANGENT = vec3(0.0,0.0,-1.0) * abs(NORMAL.x);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.y);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.z);
	TANGENT = normalize(TANGENT);

	BINORMAL = vec3(0.0,1.0,0.0) * abs(NORMAL.x);
	BINORMAL+= vec3(0.0,0.0,-1.0) * abs(NORMAL.y);
	BINORMAL+= vec3(0.0,1.0,0.0) * abs(NORMAL.z);
	BINORMAL = normalize(BINORMAL);

	uv1_power_normal = pow(abs(NORMAL), vec3(uv1_blend_sharpness));
	uv1_power_normal/= dot(uv1_power_normal, vec3(1.0));
	uv1_triplanar_pos = VERTEX * uv1_scale + uv1_offset;
	uv1_triplanar_pos *= vec3(1.0, -1.0, 1.0);
}


vec3 sample_color(vec3 color, vec2 uv) {
	float intensity = uv.x * uv.y; // 简单的强度调整
	return color * intensity; // 颜色
}


vec3 triplanar_color(vec3 color, vec3 position, vec2 offset, vec3 normal) {
	vec3 colX = sample_color(color, position.xy * scale + offset);
	vec3 colY = sample_color(color, position.xz * scale + offset);
	vec3 colZ = sample_color(color, position.zy * scale + offset);

	vec3 blendWeight = abs(normal);
	blendWeight = vec3(
		pow(blendWeight.x, uv1_blend_sharpness),
		pow(blendWeight.y, uv1_blend_sharpness),
		pow(blendWeight.z, uv1_blend_sharpness));
	blendWeight /= (
		blendWeight.x +
		blendWeight.y +
		blendWeight.z);
	return colX * blendWeight.x + colY * blendWeight.y + colZ * blendWeight.z;
}


void fragment() {
	vec2 uv = UV * subdivisions; // Subdividing uv 细分 uv
	//uv = uv1_triplanar_pos.xy;
	float checkeredGrid = grid(uv , vec2(0.5), true); // CheckerBoard 棋盘格
	//Add final color 添加最终颜色
	vec3 grid = mix(background_color, background_color_two, checkeredGrid);
	// grid = sample_color(grid, uv);


	if (use_embellishments) {
		float mainGrid = dashed_grid( //Grid 网格
				uv , vec2(grid_width), vec2(dashed_scale_x, dashed_scale_y),
				vec2(dashed_count_x, dashed_count_y), 0.5);

		float insideGrid = dashed_grid( //Inside Grid 内部网格
				uv * inside_subdivisions, vec2(inside_width),
				vec2(in_dashed_scale_x, in_dashed_scale_y),
				vec2(in_dashed_count_x, in_dashed_count_y), 0.5);

		float pointGrid = dashed_grid( //Points 点
				uv + 0.5, vec2(point_width),
				1.0 - vec2(point_scale_x , point_scale_y),
				vec2(1.0), 0.0);

		if (mainGrid != 0.0) grid = mix(grid, grid_color, mainGrid);
		if (insideGrid != 0.0) grid = mix(grid, inside_color, insideGrid);
		if (pointGrid != 0.0) grid = mix(grid, point_color, pointGrid);
	}

	ALBEDO = grid;
	//ALBEDO = triplanar_color(grid, uv1_triplanar_pos, vec2(1.0), uv1_power_normal);
}

// 在gdshader中
// texture()函数用于执行纹理读取，通常第一个参数是sampler2D类型的纹理，第二个参数是UV，返回值为vec4类型的颜色。
// colour是vec3类型的变量，储存了程序生成的颜色。
// 写一个函数，将colour像texture()函数一样处理，对colour按照uv进行采样，函数的第一个参数是vec3类型的颜色，第二个参数是vec2类型的uv，函数的返回值是vec4类型的颜色。
