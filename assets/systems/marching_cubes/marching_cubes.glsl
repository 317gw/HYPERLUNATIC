#[compute]
#version 460


struct Triangle {
	vec4 v[3];
	vec4 normal;
};


layout(set = 0, binding = 0, std430) restrict buffer ParamsBuffer {
	float size_x;
	float size_y;
	float size_z;
	float iso;
	float flat_shaded; // this is just a bool!
	float data[];
}
params;

layout(set = 0, binding = 1, std430) coherent buffer Counter {
	uint counter;
};

layout(set = 0, binding = 2, std430) restrict buffer OutputBuffer {
	Triangle data[];
}
output_buffer;

layout(set = 0, binding = 3, std430) restrict buffer LutBuffer {
	int table[256][16];
}
lut;


const vec3 points[8] =
{
	{ 0, 0, 0 },
	{ 0, 0, 1 },
	{ 1, 0, 1 },
	{ 1, 0, 0 },
	{ 0, 1, 0 },
	{ 0, 1, 1 },
	{ 1, 1, 1 },
	{ 1, 1, 0 }
};

const ivec2 edges[12] =
{
	{ 0, 1 },
	{ 1, 2 },
	{ 2, 3 },
	{ 3, 0 },
	{ 4, 5 },
	{ 5, 6 },
	{ 6, 7 },
	{ 7, 4 },
	{ 0, 4 },
	{ 1, 5 },
	{ 2, 6 },
	{ 3, 7 }
};


float voxel_value(vec3 position) {
	return params.data[int(position.x + params.size_x * (position.y + params.size_y * position.z))];
}

vec3 calculate_interpolation(vec3 v1, vec3 v2)
{
	if (params.flat_shaded == 1.0) {
		return (v1 + v2) * 0.5;
	} else {
		float val1 = voxel_value(v1);
		float val2 = voxel_value(v2);
		return mix(v1, v2, (params.iso - val1) / (val2 - val1));
	}
}

layout(local_size_x = 8, local_size_y = 8, local_size_z = 8) in;
void main() {
	vec3 grid_position = gl_GlobalInvocationID;

	int triangulation = 0;
	for (int i = 0; i < 8; ++i) {
		triangulation |= int(voxel_value(grid_position + points[i]) > params.iso) << i;
	}

	for (int i = 0; i < 16; i += 3) {
		if (lut.table[triangulation][i] < 0) {
			break;
		}
		
		// you can't just add vertices to your output array like in CPU
		// or you'll get vertex spaghetti
		Triangle t;
		for (int j = 0; j < 3; ++j) {
			ivec2 edge = edges[lut.table[triangulation][i + j]];
			vec3 p0 = points[edge.x];
			vec3 p1 = points[edge.y];
			vec3 p = calculate_interpolation(grid_position + p0, grid_position + p1);
			t.v[j] = vec4(p, 0.0);
		}
		
		// calculate normals
		vec3 ab = t.v[1].xyz - t.v[0].xyz;
		vec3 ac = t.v[2].xyz - t.v[0].xyz;
		t.normal = -vec4(normalize(cross(ab,ac)), 0.0);
		
		output_buffer.data[atomicAdd(counter, 1u)] = t;
	}
}
