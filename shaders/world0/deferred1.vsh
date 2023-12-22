#version 430 compatibility

#include "/lib/functions.glsl"
#include "/lib/spaceConvert.glsl"

uniform int frameCounter;
uniform float viewWidth;
uniform float viewHeight;
uniform mat4 gbufferProjectionInverse;

out vec2 texcoord;
out vec3 viewVector;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	viewVector = calcViewVector(texcoord, frameCounter, vec2(viewWidth, viewHeight), gbufferProjectionInverse);
}