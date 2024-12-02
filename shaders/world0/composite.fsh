#version 430 compatibility

#include "/lib/defines.glsl"
#include "/lib/functions.glsl"
#include "/lib/spaceConvert.glsl"
#include "/lib/sky.glsl"

uniform sampler2D  colortex0;
uniform sampler2D  colortex1;
uniform usampler2D colortex6;
uniform sampler2D  depthtex0;
uniform sampler2D  depthtex1;

uniform int frameCounter;
uniform float viewWidth;
uniform float viewHeight;
uniform mat4 gbufferProjectionInverse;

varying vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec3 colorOut;

void main() {
	uint mask = texture(colortex6, texcoord).r;

	colorOut = texture2D(colortex0, texcoord).rgb;
	vec4 transparentColor = texture2D(colortex1, texcoord);

	if(mask == Mask_Water) {
		float waterDepth = texture(depthtex0, texcoord).r;
		float solidDepth = texture(depthtex1, texcoord).r;

		vec3 viewPosWater = screenToView(texcoord, waterDepth, frameCounter, vec2(viewWidth, viewHeight), gbufferProjectionInverse);
		vec3 viewPosSolid = screenToView(texcoord, solidDepth, frameCounter, vec2(viewWidth, viewHeight), gbufferProjectionInverse);

		float fogDist = length(viewPosWater - viewPosSolid);
		float fogFactor = exp(-fogDist*0.07);
		colorOut = mix(0.2*vec3(0.4, 0.7, 0.8)*skyLight.skyAmbient, colorOut, fogFactor);
	}

	if(transparentColor.a > EPS) {
		colorOut = mix(colorOut, transparentColor.rgb / transparentColor.a, transparentColor.a), 1.0;
	}
}