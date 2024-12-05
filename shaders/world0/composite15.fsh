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
	colorOut = vec4(bloomDownscale(vec2(0.0625, 0.03125) * texcoord + vec2(0.0, 0.9375), colortex11, vec2(0.5*viewWidth, viewHeight), vec4(0.0, 0.9375, 0.0625, 0.96875)), 1.0);
}