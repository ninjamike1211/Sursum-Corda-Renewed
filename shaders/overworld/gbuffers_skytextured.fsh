#version 120

#include "/lib/functions.glsl"

uniform sampler2D texture;

varying vec2 texcoord;
varying vec4 glcolor;

void main() {
	vec4 color = texture2D(texture, texcoord) * glcolor;

	// color.rgb = sRGBToLinear3(color.rgb);

/* DRAWBUFFERS:2 */
	gl_FragData[0] = color; //gcolor
}