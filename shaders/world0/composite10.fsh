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
	colorOut = vec4(bloomUpscale(texcoord*0.015625 + vec2(0.46875, 0.5), colortex11, vec2(viewWidth, viewHeight), vec4(0.46875, 0.5, 0.484375, 0.515625)), 1.0);
}