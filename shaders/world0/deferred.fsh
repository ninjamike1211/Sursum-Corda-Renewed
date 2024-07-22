#version 430 compatibility

#include "/lib/defines.glsl"
#include "/lib/functions.glsl"
#include "/lib/sky.glsl"

in vec2 texcoord;

uniform mat4 gbufferModelViewInverse;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform float eyeAltitude;
uniform float viewWidth;
uniform float viewHeight;
uniform int moonPhase;

/* RENDERTARGETS: 10 */

void main() {
	vec3 viewDir = unprojectSphere(texcoord);
	vec3 sunDir = mat3(gbufferModelViewInverse) * normalize(sunPosition);
	vec3 moonDir = mat3(gbufferModelViewInverse) * normalize(moonPosition);

	gl_FragData[0] = vec4(getSkyColor(eyeAltitude, viewDir, sunDir, moonDir, moonPhase), 1.0);
}