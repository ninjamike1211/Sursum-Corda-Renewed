#version 420 compatibility

uniform sampler2D colortex0;
uniform sampler2D colortex6;
uniform sampler2D colortex15;

uniform float viewWidth;
uniform float viewHeight;
uniform int frameCounter;
uniform bool cameraMoved;

#define taaFragment

#include "/lib/defines.glsl"
#include "/lib/TAA.glsl"


// ------------------------ File Contents -----------------------
    // Apply Temporal Anti-aliasing


in vec2 texcoord;

/* RENDERTARGETS: 0,15 */
layout(location = 0) out vec4 colorOut;
layout(location = 1) out vec4 historyOut;

void main() {
	colorOut = texture(colortex0, texcoord);


// ----------------------------- TAA ----------------------------
	#ifdef TAA
		applyTAA(colorOut, historyOut, texcoord, colortex0, colortex15, colortex6);
	#endif
}