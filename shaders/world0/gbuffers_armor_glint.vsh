#version 120

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = gl_MultiTexCoord1.xy / 240.0;
	glcolor = gl_Color;
}