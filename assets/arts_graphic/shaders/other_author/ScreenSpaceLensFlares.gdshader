shader_type canvas_item;
render_mode blend_add;

#include "res://assets/arts_graphic/shaders/library/CLREDIT.gdshaderinc"

uniform lowp sampler2D Screen_Sample : hint_screen_texture, filter_linear_mipmap_anisotropic;
uniform lowp sampler2D FlareMult;
uniform lowp sampler2D FlareMult2;

uniform float Blur = 2.5;
uniform float FlareThreshold;
uniform int Flares;
uniform float FlareSpacing;

uniform float Intensity;
uniform float Saturation_;

void fragment(){
	vec2 FlippedUV = vec2(1.0) - SCREEN_UV;
	vec2 FlareVector = (vec2(0.5) - SCREEN_UV) * FlareSpacing;
	vec3 FinalFlare = vec3(0.0);

	for (int i = 0; i < Flares; ++i){
		vec2 SUV = fract(SCREEN_UV + FlareVector * vec2(float(i)));
		float Dist = distance(SUV, vec2(0.5));
		float Weight = 1.0 - smoothstep(0.0, 0.75, Dist);
		vec3 BlurredScreen = texture(Screen_Sample, SUV, Blur).rgb;
		BlurredScreen = ApplyThreshold(BlurredScreen, FlareThreshold);
		FinalFlare += BlurredScreen * Weight;
	}
	FinalFlare *= texture(FlareMult, SCREEN_UV).rgb;
	FinalFlare *= texture(FlareMult2, SCREEN_UV).rgb;
	COLOR.rgb = FinalFlare * Intensity;
	COLOR.rgb = Saturation(COLOR.rgb, Saturation_);
}