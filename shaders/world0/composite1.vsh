#version 400 compatibility

#include "/lib/spaceConvert.glsl"

uniform int frameCounter;
uniform float viewWidth;
uniform float viewHeight;
uniform mat4 gbufferProjectionInverse;

out vec2 texcoord;
out vec3 viewVector;

void main() {
	gl_Position = ftransform();
	texcoord = gl_Position.xy * 0.5 + 0.5;

	viewVector = calcViewVector(texcoord, frameCounter, vec2(viewWidth, viewHeight), gbufferProjectionInverse);
}