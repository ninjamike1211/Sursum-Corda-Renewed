#version 430 compatibility

#include "/lib/defines.glsl"
#include "/lib/bloom.glsl"

uniform sampler2D colortex0;

uniform float viewWidth;
uniform float viewHeight;

in vec2 texcoord;

/* RENDERTARGETS: 11 */
layout(location = 0) out vec4 colorOut;

void main() {
	colorOut = vec4(bloomDownscale(texcoord, colortex0, vec2(viewWidth, viewHeight), vec4(0.0, 0.0, 1.0, 1.0)), 1.0);
}