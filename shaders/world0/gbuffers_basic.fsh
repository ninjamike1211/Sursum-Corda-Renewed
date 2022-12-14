#version 400 compatibility

uniform mat4 gbufferModelView;
uniform bool inNether;
uniform bool inEnd;
uniform float alphaTestRef;

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform mat4  gbufferModelViewInverse;
uniform mat4  gbufferProjection;
uniform mat4  gbufferProjectionInverse;
uniform mat4  shadowModelView;
uniform mat4  shadowProjection;
uniform vec3  cameraPosition;
uniform float rainStrength;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform int   frameCounter;
uniform int   worldTime;
uniform bool  cameraMoved;

#include "/lib/defines.glsl"
#include "/lib/material.glsl"
#include "/lib/kernels.glsl"
#include "/lib/functions.glsl"

/* RENDERTARGETS: 1,2,4,6 */
layout(location = 0) out uvec2 normalOut;
layout(location = 1) out vec4 albedoOut;
layout(location = 2) out vec4 specMapOut;
layout(location = 3) out vec4 velocityOut;

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

    normalOut.r = NormalEncode(glNormal);
    normalOut.g = normalOut.r;

    specMapOut = vec4(0.0);
}