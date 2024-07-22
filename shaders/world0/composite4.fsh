#version 430 compatibility

#define taaFragment

#include "/lib/defines.glsl"
#include "/lib/functions.glsl"
#include "/lib/spaceConvert.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex15;
uniform sampler2D depthtex0;

in vec2 texcoord;

/* RENDERTARGETS: 0,15 */
layout(location = 0) out vec4 colorOut;
layout(location = 1) out vec4 historyOut;

void main() {
	colorOut = texture(colortex0, texcoord);

	#ifdef TAA
		float outputDepth;
		applyTAA(texcoord, colorOut.rgb, outputDepth, colortex0, colortex15, depthtex0);
		historyOut = vec4(colorOut.rgb, outputDepth);
	#endif
}