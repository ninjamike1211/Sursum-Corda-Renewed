#version 430 compatibility

uniform sampler2D colortex11;

in vec2 texcoord;

/* RENDERTARGETS: 11,0*/
layout(location = 0) out vec3 bloomOut;
layout(location = 1) out vec3 testOut;

// Debug pass, adds the alt and main buffer for bloom to view all parts of the texture

void main() {
	bloomOut = texture(colortex11, texcoord).xyz;

	testOut = vec3(1.0);
}