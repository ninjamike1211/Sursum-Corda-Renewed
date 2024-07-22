#version 430 compatibility

#include "/lib/defines.glsl"
#include "/lib/functions.glsl"
#include "/lib/spaceConvert.glsl"

in vec2 texcoord;

#include "/lib/DOF.glsl"

uniform sampler2D colortex0;
uniform usampler2D colortex6;
uniform sampler2D colortex12;
uniform sampler2D depthtex0;
uniform float centerDepthSmooth;
uniform float aspectRatio;
uniform float near;
uniform float far;

/* RENDERTARGETS: 12 */
layout(location = 0) out float cocOut;

void main() {
	float depth = texture(depthtex0, texcoord).r;
	uint mask = texture(colortex6, texcoord).r;
	// sceneColor = texture(colortex0, texcoord).rgb;
	// foregroundColor = vec3(0.0);

	// Hand depth fix
	if((mask & Mask_Hand) != 0) {
		depth = convertHandDepth(depth);
	}

	float depthLinear = linearizeDepthFast(depth, near, far);
	float centerDepthLinear = linearizeDepthFast(centerDepthSmooth, near, far);

	cocOut = getCoCFromDepth(depthLinear, centerDepthLinear);

	// if(cocOut < 0.0) {
	// 	foregroundColor = sceneColor;
	// 	sceneColor = vec3(0.0);
	// }

}