
#include "/lib/defines.glsl"
#include "/lib/exposure.glsl"
#include "/lib/functions.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex11;

uniform float viewWidth;
uniform float viewHeight;

in vec2 texcoord;

/* RENDERTARGETS: 0*/
layout(location = 0) out vec3 sceneColor;

void main() {
	sceneColor = texture(colortex0, texcoord).rgb;

	#if Bloom_Levels > 0
		vec3 bloomColor = texture(colortex11, texcoord*vec2(1.0, 0.5)).rgb;
		sceneColor = mix(sceneColor, bloomColor, 0.01);
	#endif

	sceneColor /= 9.6 * averageLum * 0.5;
	sceneColor = ACESFitted(linearToSRGB3(sceneColor));
}