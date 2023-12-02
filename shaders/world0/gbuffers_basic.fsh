#version 400 compatibility

#include "/lib/defines.glsl"

flat in vec4 glcolor;

/* RENDERTARGETS: 2 */
layout(location = 0) out vec4 albedoOut;

void main() {
	albedoOut = glcolor;
	// albedoOut.rgb = sRGBToLinear3(albedoOut.rgb);
}