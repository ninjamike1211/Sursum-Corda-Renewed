#version 120

#include "/lib/defines.glsl"
#include "/lib/functions.glsl"

uniform float viewHeight;
uniform float viewWidth;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform vec3 sunPosition;
uniform float sunAngle;
uniform float eyeAltitude;

varying vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.


void main() {
	vec3 color = vec3(0.0);
	if (starData.a > 0.5) {
		color = starData.rgb;
	}

	color.rgb = sRGBToLinear3(color.rgb);

/* DRAWBUFFERS:2 */
	gl_FragData[0] = vec4(color, 1.0); //gcolor
}