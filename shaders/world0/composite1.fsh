#version 430 compatibility

#include "/lib/defines.glsl"
#include "/lib/functions.glsl"
#include "/lib/material.glsl"
#include "/lib/spaceConvert.glsl"
#include "/lib/raytrace.glsl"
#include "/lib/sky.glsl"
#include "/lib/DOF.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform usampler2D colortex6;
uniform sampler2D colortex10;
uniform sampler2D depthtex0;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform vec3 sunPosition;
uniform float sunAngle;
uniform float viewWidth;
uniform float viewHeight;
uniform float centerDepthSmooth;
uniform float near;
uniform float far;
uniform int frameCounter;

in vec2 texcoord;
in vec3 viewVector;

layout(std430, binding = 0) buffer Histogram {
    uint HistogramGlobal[256];
    float averageLum;
};

vec3 getSkyReflection(vec3 reflectDir, vec2 texcoord) {
	float skyLightmap = texture(colortex5, texcoord).g;
	vec3 sceneReflectDir = mat3(gbufferModelViewInverse) * reflectDir;
	vec2 skySamplePos = projectSphere(sceneReflectDir);
	vec3 reflectColor = texture(colortex10, skySamplePos).rgb;
	reflectColor *= linstep(0.0, 0.5, skyLightmap);
	return reflectColor;
}


/* RENDERTARGETS: 0,12 */
layout(location = 0) out vec4 colorOut;
layout(location = 1) out float cocOut;

void main() {

	float depth = texture(depthtex0, texcoord).r;
	uint mask = texture(colortex6, texcoord).r;
	vec3 linearColor = texture(colortex0, texcoord).rgb;

	// Hand depth fix
	if((mask & Mask_Hand) != 0) {
		depth = convertHandDepth(depth);
	}

	#if Reflections > 0
	if(depth < 1.0) {
		vec3 albedo = texture(colortex2, texcoord).rgb;
		vec4 rawNormal = texture(colortex3, texcoord);
		vec4 specular = texture(colortex4, texcoord);

		vec3 viewPos = calcViewPos(viewVector, depth, gbufferProjection);
		vec3 viewDir = normalize(viewPos);
		vec3 normal = mat3(gbufferModelView) * unpackNormalVec2(rawNormal.xy);

		vec3 fresnel = calcFresnel(max(dot(normal, normalize(-viewPos)), 0.0), specular, albedo);

		vec3 reflectDir = reflect(viewDir, normal);
		vec3 hitPos;
		vec3 reflectColor = vec3(0.0);

		#if Reflections == 2
			bool hit = screenspaceRaymarch(vec3(texcoord, depth), viewPos, reflectDir, 32, 4, 1.0, hitPos, frameCounter, vec2(viewWidth, viewHeight), near, far, depthtex0, gbufferProjection);
			if(hit) {
				reflectColor = texture(colortex0, hitPos.xy).rgb;
			}
			else 
		#endif
			reflectColor = getSkyReflection(reflectDir, texcoord);


		linearColor.rgb += fresnel * specular.r * reflectColor;
	}
	#endif

	linearColor /= 9.6 * averageLum * 0.5;


	// linearColor = ACESFilm(linearColor);
	colorOut = vec4(ACESFitted(linearToSRGB3(linearColor)), 1.0);

	#ifdef DOF
		float depthLinear = linearizeDepthFast(depth, near, far);
		float centerDepthLinear = linearizeDepthFast(centerDepthSmooth, near, far);

		cocOut = getCoCFromDepth(depthLinear, centerDepthLinear);
	#endif
}