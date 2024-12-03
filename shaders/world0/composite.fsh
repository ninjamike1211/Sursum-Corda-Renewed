#version 430 compatibility

#define WaterVolumetrics

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

#include "/lib/defines.glsl"
#include "/lib/functions.glsl"
#include "/lib/sample.glsl"
#include "/lib/spaceConvert.glsl"
#include "/lib/shadows.glsl"
#include "/lib/water.glsl"
#include "/lib/sky.glsl"

uniform sampler2D  colortex0;
uniform sampler2D  colortex1;
uniform usampler2D colortex6;
uniform sampler2D  depthtex0;
uniform sampler2D  depthtex1;
// uniform sampler2D shadowtex0;

uniform int isEyeInWater;
uniform int frameCounter;
uniform float eyeAltitude;
uniform float viewWidth;
uniform float viewHeight;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

varying vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec3 colorOut;


void main() {
	uint mask = texture(colortex6, texcoord).r;

	colorOut = texture2D(colortex0, texcoord).rgb;
	vec4 transparentColor = texture2D(colortex1, texcoord);

	float waterDepth = texture(depthtex0, texcoord).r;
	float solidDepth = texture(depthtex1, texcoord).r;

	vec3 viewPosWater = screenToView(texcoord, waterDepth, frameCounter, vec2(viewWidth, viewHeight), gbufferProjectionInverse);
	vec3 viewPosSolid = screenToView(texcoord, solidDepth, frameCounter, vec2(viewWidth, viewHeight), gbufferProjectionInverse);

	vec3 scenePosWater = (gbufferModelViewInverse * vec4(viewPosWater, 1.0)).xyz;
	vec3 scenePosSolid = (gbufferModelViewInverse * vec4(viewPosSolid, 1.0)).xyz;

	float randomAngle = interleaved_gradient(ivec2(gl_FragCoord.xy), frameCounter) * TAU;
	// randomAngle = 0.0;

	if(isEyeInWater == 0) {
		if(mask == Mask_Water) {
			// float fogDist = length(viewPosWater - viewPosSolid);
			// simpleWaterFog(colorOut, fogDist, skyLight.skyAmbient);
			volumetricWaterFog(colorOut, scenePosWater, scenePosSolid, eyeAltitude, skyLight.skyDirect, skyLight.skyAmbient, randomAngle, shadowtex1);
		}
	}
	else if(isEyeInWater == 1) {
		vec3 farPos = scenePosSolid;

		if(waterDepth < 1.0 && mask == Mask_Water)
			farPos = scenePosWater;

		float fogDist = length(farPos);
		// simpleWaterFog(colorOut, fogDist, skyLight.skyAmbient);
		volumetricWaterFog(colorOut, vec3(0.0), farPos, eyeAltitude, skyLight.skyDirect, skyLight.skyAmbient, randomAngle, shadowtex1);

		// volumetricWaterFog(transparentColor.rgb, vec3(0.0), viewPosWater, skyLight.skyDirect, skyLight.skyAmbient, shadowtex1);
	}

	if(transparentColor.a > EPS) {
		colorOut = mix(colorOut, transparentColor.rgb / transparentColor.a, transparentColor.a), 1.0;
	}
}