#version 400 compatibility

uniform float viewWidth;
uniform float viewHeight;
uniform int frameCounter;

#include "/lib/defines.glsl"
#include "/lib/spaceConvert.glsl"

flat out vec4 glcolor;
out vec2 lmcoord;

void main() {
	gl_Position = ftransform();
	
	#ifdef TAA
		gl_Position.xy += taaOffset(frameCounter, vec2(viewWidth, viewHeight)) * gl_Position.w;
	#endif

	glcolor = gl_Color;
	lmcoord = gl_MultiTexCoord1.xy / 240.0;
}