#version 430 compatibility

#include "/lib/defines.glsl"
#include "/lib/functions.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex11;

uniform float viewWidth;
uniform float viewHeight;

in vec2 texcoord;

layout(std430, binding = 0) buffer Histogram {
    uint HistogramGlobal[256];
    float averageLum;
};

/* RENDERTARGETS: 0*/
layout(location = 0) out vec3 sceneColor;

void main() {
	sceneColor = texture(colortex0, texcoord).rgb;

	#if Bloom_Levels > 0
		vec3 bloomColor = texture(colortex11, texcoord*0.5).rgb;
		sceneColor = mix(sceneColor, bloomColor, 0.01);
	#endif

	sceneColor /= 9.6 * averageLum * 0.5;
	sceneColor = ACESFitted(linearToSRGB3(sceneColor));
}