#version 400 compatibility

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

#include "/lib/defines.glsl"
#include "/lib/functions.glsl"
#include "/lib/material.glsl"
#include "/lib/spaceConvert.glsl"
#include "/lib/shadows.glsl"

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D normals;
uniform sampler2D specular;
uniform mat4 gbufferModelViewInverse;
uniform vec3 shadowLightPosition;
uniform float alphaTestRef;
uniform float viewWidth;
uniform float viewHeight;
uniform int frameCounter;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 scenePos;
flat in vec3 glNormal;
flat in vec4 tangent;
flat in uint mcEntity;

/* RENDERTARGETS: 1,2,3,4,5,6 */
layout(location = 0) out vec4 colorOut;
layout(location = 1) out vec4 albedoOut;
layout(location = 2) out vec4 normalOut;
layout(location = 3) out vec4 specularOut;
layout(location = 4) out vec2 lightmapOut;
layout(location = 5) out uint maskOut;

void main() {
	vec4 albedo = texture(gtexture, texcoord) * glcolor;
	albedoOut = albedo;
	if (albedo.a < alphaTestRef) discard;

	albedo.rgb = sRGBToLinear3(albedo.rgb);

	specularOut = texture(specular, texcoord);
	lightmapOut = lmcoord;


	vec3 normal = glNormal;
	if(!gl_FrontFacing)
		normal *= -1.0;
	
	mat3 tbn = tbnNormalTangent(normal, tangent);


	vec3 texNormal = tbn * extractNormalZ(texture(normals, texcoord).xy * 2.0 - 1.0);

	normalOut.rg = packNormalVec2(texNormal);
	normalOut.ba = packNormalVec2(tbn[2]);

	maskOut = mcEntityMask(mcEntity);


	vec3 lightDir = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);
	float NGdotL = dot(glNormal, lightDir);
	vec3 directLight = vec3(4.0);

	#ifdef Shadow_NoiseAnimated
		float randomAngle = interleaved_gradient(ivec2(gl_FragCoord.xy), frameCounter) * TAU;
	#else
		float randomAngle = interleaved_gradient(ivec2(gl_FragCoord.xy), 0) * TAU;
	#endif

	#if Shadow_Type == 0
		directLight *= lmcoord.g;

	#elif Shadow_Type == 1
		vec3 shadowPos = calcShadowPosScene(scenePos);

		#ifdef Shadow_NormalBias
			directLight *= sampleShadowNormalBias(shadowPos, tbn[2]);
		#else
			directLight *= sampleShadow(shadowPos, NGdotL);
		#endif

	#elif Shadow_Type == 2
		vec3 shadowPos = calcShadowPosScene(scenePos);

		#ifdef Shadow_NormalBias
			directLight *= sampleShadowPCFNormalBias(shadowPos, tbn[2], Shadow_PCF_BlurRadius, 32, randomAngle);
		#else
			directLight *= sampleShadowPCF(shadowPos, NGdotL, Shadow_PCF_BlurRadius, 32, randomAngle);
		#endif

	#elif Shadow_Type == 3
		vec3 shadowPos = calcShadowPosScene(scenePos);

		#ifdef Shadow_NormalBias
			directLight *= sampleShadowPCSSNormalBias(shadowPos, tbn[2], randomAngle);
		#else
			directLight *= sampleShadowPCSS(shadowPos, NGdotL, randomAngle);
		#endif
	#endif

	colorOut.rgb = cookTorrancePBRLighting(albedo.rgb, normalize(-scenePos), texNormal, specularOut, directLight, lightDir);
	colorOut.rgb += albedo.rgb * calcLightmap(lmcoord, vec3(0.3));
	colorOut.a = albedo.a;
}