////////////// THIS IS THE SHADERCODE FOR THE TOP PART, BOTTOM PART CAN BE FOUND LOWER //////////////

shader_type spatial;

render_mode blend_mix, cull_disabled;

//This is where we set up the shader parameters so we can tweak the shader in real time later.

uniform sampler2D Noise1;
uniform float timeScale1;
uniform float timeScale2;
uniform float cloud1worldScale;
uniform float cloud2worldScale;
uniform float displacementStrength;

//This is the vertexshader

void vertex()
{
	//Time is multiplied by cloudSpeed1 & cloudSpeed2, to give us control to tweak how fast the clouds are moving.
	float cloudSpeed1 = timeScale1 * TIME;
	float cloudSpeed2 = timeScale2 * TIME;

	//Here we set the UV for the texture to be world position stretched over X and Z axis
	vec2 world_pos = (vec4(VERTEX,1.f) ).xz;

	//Two different UV's are made here for the clouds, they will move in different directions in the world x-axis but in the same direction in world z-axis
	vec2 Cloud1UV = vec2((world_pos.x * cloud1worldScale) + cloudSpeed1 ,(world_pos.y * cloud1worldScale) + cloudSpeed1);
	vec2 Cloud2UV = vec2((world_pos.x * cloud2worldScale) - cloudSpeed2 ,(world_pos.y * cloud2worldScale) + cloudSpeed2);

	//Noise-textures are sampled and assigned the UV's created earlier
	vec4 Cloud1 = texture(Noise1, Cloud1UV) ;
	vec4 Cloud2 = texture(Noise1, Cloud2UV) ;

	//Multiplying the Cloud noise-textures here, this resulting in them seemingly "melting together". We then normalize the result to make sure it's between -1 and 1.
	vec4 CloudCombined = normalize(Cloud1 * Cloud2);

	//Position of the vertex in y-space is moved based on the combined clouds and the parameter displacementStrength so we can tweak it in real time.
	VERTEX.y = VERTEX.y + CloudCombined.r * displacementStrength;
}

uniform float discardHeight;

//This is the pixelshader/fragmentshader

void fragment() {

	//Pixels are taken from viewspace to worldspace by multiplying with the inverse view matrix.
	vec4 worldVertex = INV_VIEW_MATRIX * vec4(VERTEX, 1.0);

	//Checking if the pixels world position is above the discardheight, if not we discard them since we dont want to render them.
	if (worldVertex.y > discardHeight)
		ALBEDO = vec3(1.f,1.f,1.f);
	else
		discard;
}