#version 120

#include "/lib/functions.glsl"

uniform sampler2D lightmap;
uniform sampler2D gtexture;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;

/* DRAWBUFFERS:2 */

void main() {
	vec4 color = texture2D(gtexture, texcoord) * glcolor;
	color *= texture2D(lightmap, lmcoord);

	// color.rgb = sRGBToLinear3(color.rgb);

	gl_FragData[0] = color; //gcolor
}