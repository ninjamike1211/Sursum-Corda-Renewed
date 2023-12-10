#version 400 compatibility

#include "/lib/defines.glsl"
#include "/lib/functions.glsl"
#include "/lib/sky.glsl"

in vec2 texcoord;

uniform mat4 gbufferModelViewInverse;
uniform vec3 sunPosition;
uniform float eyeAltitude;
uniform float viewWidth;
uniform float viewHeight;

/* RENDERTARGETS: 10 */

void main() {
	vec3 viewDir = unprojectSphere(texcoord);
	vec3 sunDir = mat3(gbufferModelViewInverse) * normalize(sunPosition);

	gl_FragData[0] = vec4(getSkyColor(eyeAltitude, viewDir, sunDir), 1.0);
}