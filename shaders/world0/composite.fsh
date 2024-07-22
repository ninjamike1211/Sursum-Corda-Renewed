#version 120

#include "/lib/defines.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex1;

varying vec2 texcoord;

/* DRAWBUFFERS:0 */

void main() {
	vec3 opaqueColor = texture2D(colortex0, texcoord).rgb;
	vec4 transparentColor = texture2D(colortex1, texcoord);

	gl_FragData[0] = vec4(mix(opaqueColor, transparentColor.rgb / transparentColor.a, transparentColor.a), 1.0);
}