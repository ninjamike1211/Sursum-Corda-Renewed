#version 430 compatibility

#include "/lib/defines.glsl"
#include "/lib/functions.glsl"
#include "/lib/spaceConvert.glsl"
#include "/lib/sky.glsl"

uniform sampler2D  colortex0;
uniform sampler2D  colortex1;
uniform usampler2D colortex6;
uniform sampler2D  depthtex0;
uniform sampler2D  depthtex1;

uniform int isEyeInWater;
uniform int frameCounter;
uniform float viewWidth;
uniform float viewHeight;
uniform mat4 gbufferProjectionInverse;

varying vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec3 colorOut;

void applyWaterFog(inout vec3 sceneColor, float vectorLen) {
	float fogFactor = exp(-vectorLen*0.07);
	sceneColor = mix(0.2*vec3(0.4, 0.7, 0.8)*skyLight.skyAmbient, sceneColor, fogFactor);
}

void main() {
	uint mask = texture(colortex6, texcoord).r;

	colorOut = texture2D(colortex0, texcoord).rgb;
	vec4 transparentColor = texture2D(colortex1, texcoord);

	float waterDepth = texture(depthtex0, texcoord).r;
	float solidDepth = texture(depthtex1, texcoord).r;

	vec3 viewPosWater = screenToView(texcoord, waterDepth, frameCounter, vec2(viewWidth, viewHeight), gbufferProjectionInverse);
	vec3 viewPosSolid = screenToView(texcoord, solidDepth, frameCounter, vec2(viewWidth, viewHeight), gbufferProjectionInverse);

	if(isEyeInWater == 0) {
		if(mask == Mask_Water) {
			float fogDist = length(viewPosWater - viewPosSolid);
			applyWaterFog(colorOut, fogDist);
		}
	}
	else if(isEyeInWater == 1) {
		vec3 farPos = viewPosSolid;

		if(waterDepth < 1.0 && mask == Mask_Water)
			farPos = viewPosWater;

		float fogDist = length(farPos);
		applyWaterFog(colorOut, fogDist);
	}

	if(transparentColor.a > EPS) {
		colorOut = mix(colorOut, transparentColor.rgb / transparentColor.a, transparentColor.a), 1.0;
	}
}