#version 400 compatibility

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

#include "/lib/defines.glsl"
#include "/lib/material.glsl"
#include "/lib/spaceConvert.glsl"
#include "/lib/shadows.glsl"

uniform sampler2D  depthtex0;
uniform sampler2D  depthtex2;
uniform sampler2D  colortex2;
uniform sampler2D  colortex3;
uniform sampler2D  colortex4;
uniform sampler2D  colortex5;
uniform usampler2D colortex6;
uniform sampler2D  colortex8;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform vec3 shadowLightPosition;
uniform float viewWidth;
uniform float viewHeight;
uniform int frameCounter;

in vec2 texcoord;
in vec3 viewVector;

/* RENDERTARGETS: 0 */

void main() {
	float depth = texture(depthtex0, texcoord).r;
	vec3 albedo = texture(colortex2, texcoord).rgb;
	albedo.rgb = sRGBToLinear3(albedo.rgb);

	if(depth != 1.0) {
		vec4 rawNormal = texture(colortex3, texcoord);
		vec4 specular = texture(colortex4, texcoord);
		vec2 lmcoord = texture(colortex5, texcoord).rg;
		uint mask = texture(colortex6, texcoord).r;
		vec2 pomShadow = texture(colortex8, texcoord).rg;


		// Hand depth fix, not perfect, doesn't properly account for perspective
		if((mask & Mask_Hand) != 0) {
			// depth = texture(depthtex2, texcoord).r;
			// depth = 0.9;
			// depth += MC_HAND_DEPTH / depth * 100.0;
			// viewPos = screenToViewHand(texcoord, depth, gbufferProjectionInverse);
			
			// depth *= 1.67;
			depth *= 0.208 / MC_HAND_DEPTH;
		}

		vec3 viewPos = calcViewPos(viewVector, depth, gbufferProjection);
		vec3 scenePos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

		vec3 normal = unpackNormalVec2(rawNormal.xy);
		vec3 normalGeom = unpackNormalVec2(rawNormal.zw);
		vec3 lightDir = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);
		float NGdotL = dot(normalGeom, lightDir);
		vec3 directLight = vec3(4.0) * pomShadow.r;

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
				directLight *= sampleShadowPCFNormalBias(shadowPos, normalGeom, Shadow_PCF_BlurRadius, 32, randomAngle);
			#else
				directLight *= sampleShadowPCF(shadowPos, NGdotL, Shadow_PCF_BlurRadius, 32, randomAngle);
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

		color += albedo * calcLightmap(lmcoord, vec3(0.2));

		gl_FragData[0] = vec4(color, 1.0);
	}
	else {
		gl_FragData[0] = vec4(albedo, 1.0);
	}
}