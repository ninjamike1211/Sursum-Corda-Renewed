#version 430 compatibility

#include "/lib/defines.glsl"
#include "/lib/bloom.glsl"

uniform sampler2D colortex11;

uniform float viewWidth;
uniform float viewHeight;

in vec2 texcoord;

/* RENDERTARGETS: 11 */
layout(location = 0) out vec4 colorOut;

void main() {
	colorOut = vec4(bloomDownscale(vec2(1.0, 0.5) * texcoord, colortex11, vec2(0.5*viewWidth, viewHeight), vec4(0.0, 0.0, 1.0, 0.5)), 1.0);
}