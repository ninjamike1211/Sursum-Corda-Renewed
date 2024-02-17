#version 430 compatibility

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

#include "/lib/defines.glsl"
#include "/lib/material.glsl"
#include "/lib/spaceConvert.glsl"
#include "/lib/shadows.glsl"
#include "/lib/sky.glsl"

uniform sampler2D  depthtex0;
uniform sampler2D  depthtex2;
uniform sampler2D  colortex2;
uniform sampler2D  colortex3;
uniform sampler2D  colortex4;
uniform sampler2D  colortex5;
uniform usampler2D colortex6;
uniform sampler2D  colortex7;
uniform sampler2D  colortex10;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform vec3 sunPosition;
uniform vec3 shadowLightPosition;
uniform float viewWidth;
uniform float viewHeight;
uniform int frameCounter;

in vec2 texcoord;
in vec3 viewVector;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 colorOut;

void main() {
	float depth = texture(depthtex0, texcoord).r;
	uint mask = texture(colortex6, texcoord).r;
	vec3 albedo = texture(colortex2, texcoord).rgb;
	albedo.rgb = sRGBToLinear3(albedo.rgb);

	// Hand depth fix
	if((mask & Mask_Hand) != 0) {
		depth = convertHandDepth(depth);
	}

	vec3 viewPos = calcViewPos(viewVector, depth, gbufferProjection);
	vec3 scenePos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

	if(depth != 1.0) {
		vec4 rawNormal = texture(colortex3, texcoord);
		vec4 specular = texture(colortex4, texcoord);
		vec2 lmcoord = texture(colortex5, texcoord).rg;
		vec2 pomShadow = texture(colortex7, texcoord).rg;

		vec3 normal = unpackNormalVec2(rawNormal.xy);
		vec3 normalGeom = unpackNormalVec2(rawNormal.zw);
		vec3 lightDir = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);
		float NGdotL = dot(normalGeom, lightDir);
		vec3 directLight = skyLight.skyDirect * pomShadow.r;

        #ifdef Shadow_NoiseAnimated
            float randomAngle = interleaved_gradient(ivec2(gl_FragCoord.xy), frameCounter) * TAU;
        #else
            float randomAngle = interleaved_gradient(ivec2(gl_FragCoord.xy), 0) * TAU;
        #endif

		// Shadows disabled
		#if Shadow_Type == 0
			directLight *= lmcoord.g;

		// Shadows no filtering
		#elif Shadow_Type == 1
			vec3 shadowPos = calcShadowPosScene(scenePos);

			#ifdef Shadow_NormalBias
				directLight *= sampleShadowNormalBias(shadowPos, normalGeom);
			#else
				directLight *= sampleShadow(shadowPos, NGdotL);
			#endif

		// PCF shadows
		#elif Shadow_Type == 2
			vec3 shadowPos = calcShadowPosScene(scenePos);

			#ifdef Shadow_NormalBias
				directLight *= sampleShadowPCFNormalBias(shadowPos, normalGeom, Shadow_PCF_BlurRadius, Shadow_PCF_Samples, randomAngle);
			#else
				directLight *= sampleShadowPCF(shadowPos, NGdotL, Shadow_PCF_BlurRadius, Shadow_PCF_Samples, randomAngle);
			#endif

		// PCSS shadows
		#elif Shadow_Type == 3
			vec3 shadowPos = calcShadowPosScene(scenePos + lightDir * pomShadow.g);

			#ifdef Shadow_NormalBias
				directLight *= sampleShadowPCSSNormalBias(shadowPos, normalGeom, randomAngle);
			#else
				directLight *= sampleShadowPCSS(shadowPos, NGdotL, randomAngle);
			#endif
		#endif

		vec3 color = cookTorrancePBRLighting(albedo, normalize(-scenePos), normal, specular, directLight, lightDir);

		color += albedo * (calcLightmap(lmcoord, skyLight.skyAmbient) + getEmissiveStrength(specular));

		colorOut = vec4(color, 1.0);
	}
	else {
		vec3 sceneDir = normalize(scenePos);
		vec3 sunDir = mat3(gbufferModelViewInverse) * normalize(sunPosition);
		vec2 skySamplePos = projectSphere(sceneDir);
		vec3 skyColor = texture(colortex10, skySamplePos).rgb;
		applySunDisk(skyColor, sceneDir, sunDir);
		albedo.rgb *= horizonFadeFactor(sceneDir);
		albedo.rgb += skyColor;
		colorOut= vec4(albedo, 1.0);
	}
}