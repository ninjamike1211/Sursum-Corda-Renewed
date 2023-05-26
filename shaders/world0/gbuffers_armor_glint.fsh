#version 430 compatibility

uniform sampler2D tex;
// uniform float alphaTestRef;

#include "/lib/defines.glsl"


// ------------------------ File Contents -----------------------
	// Gbuffers basic objects fragment shader
	// Motion vector calculations for TAA or Motion Blur
    // Position calculations
    // Normals calculations


/* RENDERTARGETS: 1 */
layout(location = 0) out vec4  albedoOut;

in vec2 texcoord;
flat in vec4 glColor;

void main() {
	
    albedoOut = texture(tex, texcoord) * glColor;
    // if (albedoOut.a < alphaTestRef) discard;

}