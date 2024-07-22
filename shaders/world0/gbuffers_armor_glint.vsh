#version 120

uniform float viewWidth;
uniform float viewHeight;
uniform int frameCounter;

#include "/lib/defines.glsl"
#include "/lib/spaceConvert.glsl"

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;

void main() {
	gl_Position = ftransform();

	#ifdef TAA
		gl_Position.xy += taaOffset(frameCounter, vec2(viewWidth, viewHeight)) * gl_Position.w;
	#endif

	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = gl_MultiTexCoord1.xy / 240.0;
	glcolor = gl_Color;
}