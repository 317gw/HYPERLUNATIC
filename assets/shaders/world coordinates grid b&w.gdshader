shader_type spatial;

uniform float gridSize: hint_range(0.3,10) = 2;
varying vec3 world_position;

void vertex() {
	world_position = VERTEX;
}

float to_float(float pos){
	return float(int(pos * 2.0))/ 2.0;
}

void fragment(){
	vec3 pos = world_position;
	pos /= gridSize;
	pos += gridSize * 20.0;
	//to offset a bug that appears when one of the coordinate is close to 0
	//以抵消一个坐标接近 0 时出现的bug
	//can be tweaked if the bug is visible
	//如果错误可见，可以进行调整
	pos.y += 1.0 * to_float(pos.x);
	pos.z += to_float(pos.y);
	vec3 col = vec3(fract(to_float(pos.z)));
	ROUGHNESS = col.x / 2.0 + 0.2;
	ALBEDO = col;
}