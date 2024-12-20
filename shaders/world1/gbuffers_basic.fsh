#version 430 compatibility

uniform float alphaTestRef;

#include "/lib/defines.glsl"
#include "/lib/material.glsl"


// ------------------------ File Contents -----------------------
	// Gbuffers basic objects fragment shader
	// Motion vector calculations for TAA or Motion Blur
    // Position calculations
    // Normals calculations


/* RENDERTARGETS: 1,2,3,6 */
layout(location = 0) out vec4  albedoOut;
layout(location = 1) out uvec3 materialOut;
layout(location = 2) out vec4  lightmapOut;
layout(location = 3) out vec4  velocityOut;

flat in vec4 glColor;
flat in vec3 glNormal;

#if defined TAA || defined MotionBlur
	in vec4 oldClipPos;
	in vec4 newClipPos;
#endif

void main() {
// ---------------------- TAA Velocity ----------------------
	#if defined TAA || defined MotionBlur
		vec2 oldPos = oldClipPos.xy / oldClipPos.w;
		oldPos = oldPos * 0.5 + 0.5;

		vec2 newPos = newClipPos.xy / newClipPos.w;
		newPos = newPos * 0.5 + 0.5;

		velocityOut = vec4(newPos - oldPos, 0.0, 1.0);
	#endif
	
    albedoOut = glColor;
    if (albedoOut.a < alphaTestRef) discard;

    materialOut.r = NormalEncode(glNormal);
    materialOut.g = materialOut.r;
	materialOut.b = SpecularEncode(vec4(0.0));

	lightmapOut = vec4(1.0, 1.0, 0.0, 1.0);
}