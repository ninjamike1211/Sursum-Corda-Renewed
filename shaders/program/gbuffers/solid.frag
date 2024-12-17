#include "/lib/defines.glsl"

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D normals;
uniform sampler2D specular;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform vec3 shadowLightPosition;
uniform ivec2 atlasSize;
uniform float alphaTestRef;
uniform int renderStage;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 scenePos;
flat in vec3 glNormal;
flat in vec4 tangent;
flat in vec4 textureBounds;
flat in uint mcEntity;

#ifdef Shadow_PerVertexDistortion
	in vec3 shadowPos;
#endif

layout (r8ui) uniform uimage3D voxelImage;
#if defined UseVoxelization && defined Parallax_DiscardEdge
	flat in ivec3 voxelPos;
	flat in ivec4 pomDiscardEdges;
#endif

#ifndef Shadow_PerVertexDistortion
/* RENDERTARGETS: 2,3,4,5,6,7 */
#else
/* RENDERTARGETS: 2,3,4,5,6,7,8 */
#endif

layout(location = 0) out vec4 albedoOut;
layout(location = 1) out vec2 normalOut;
layout(location = 2) out vec4 specularOut;
layout(location = 3) out vec2 lightmapOut;
layout(location = 4) out uint maskOut;
layout(location = 5) out vec2 pomOut;

#ifdef Shadow_PerVertexDistortion
	layout(location = 6) out vec3 shadowPosOut;
#endif

#define gbuffersTextured

#include "/lib/functions.glsl"
#include "/lib/material.glsl"
#include "/lib/spaceConvert.glsl"
#include "/lib/parallax.glsl"
#include "/lib/material.glsl"


void main() {
	vec3 normal = glNormal;
	if(!gl_FrontFacing)
		normal *= -1.0;
	mat3 tbn = tbnNormalTangent(normal, tangent);

	mat2 dFdXY = mat2(dFdx(texcoord), dFdy(texcoord));
	vec3 tangentPos = vec3(texcoord, 1.0);
	vec2 texcoordFinal = texcoord;

	vec3 lightDir = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);

	// bool isBlock = renderStage == MC_RENDER_STAGE_TERRAIN_SOLID ||
	// 	renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT_MIPPED ||
	// 	renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT ||
	// 	renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT;

	// bvec4 pomDiscardEdges = bvec4(false);
	
	// if (isBlock) {
	// 	if(clamp(voxelPos.xz, ivec2(0), ivec2(512)) == voxelPos.xz) {
	// 		if(imageLoad(voxelImage, voxelPos + ivec3(round(tbn[0]))).r == 0
	// 			&& imageLoad(voxelImage, voxelPos + ivec3(round(tbn[0])) + ivec3(round(tbn[2]))).r == 0)
	// 			pomDiscardEdges.x = true;
	// 		if(imageLoad(voxelImage, voxelPos - ivec3(round(tbn[0]))).r == 0
	// 			&& imageLoad(voxelImage, voxelPos - ivec3(round(tbn[0])) + ivec3(round(tbn[2]))).r == 0)
	// 			pomDiscardEdges.y = true;
	// 		if(imageLoad(voxelImage, voxelPos + ivec3(round(tbn[1]))).r == 0
	// 			&& imageLoad(voxelImage, voxelPos + ivec3(round(tbn[1])) + ivec3(round(tbn[2]))).r == 0)
	// 			pomDiscardEdges.z = true;
	// 		if(imageLoad(voxelImage, voxelPos - ivec3(round(tbn[1]))).r == 0
	// 			&& imageLoad(voxelImage, voxelPos - ivec3(round(tbn[1])) + ivec3(round(tbn[2]))).r == 0)
	// 			pomDiscardEdges.w = true;
	// 	}
	// }

	#ifdef Parallax
		pomOut = vec2(0.0, 0.0);
		vec3 pomNormal;
		pomOut.r = 1.0 - parallax(tangentPos, texcoordFinal, pomNormal, scenePos, lightDir, tbn, textureBounds, atlasSize, dFdXY);

		#if defined Parallax_DepthOffset && defined GBUFFERS_TERRAIN
			parallaxApplyDepthOffset(tangentPos, scenePos, texcoord, tbn, gbufferModelView, gbufferProjection);

			// if(dot(geomNormal, lightDir) >= 0.0)
				pomOut.g = parallaxShadowDist(tangentPos, lightDir, tbn);
		#endif
		
	#endif

	albedoOut = textureGrad(gtexture, texcoordFinal, dFdXY[0], dFdXY[1]) * glcolor;

	#ifdef GBUFFERS_BEACONBEAM
		if (albedoOut.a < 0.9) discard;
	#else
		if (albedoOut.a < alphaTestRef) discard;
	#endif

	specularOut = textureGrad(specular, texcoordFinal, dFdXY[0], dFdXY[1]);
	lightmapOut = lmcoord;

	vec3 rawTexNormal = textureGrad(normals, texcoordFinal, dFdXY[0], dFdXY[1]).xyz;
	vec3 texNormal = tbn * extractNormalZ(rawTexNormal.xy * 2.0 - 1.0);

	lightmapOut *= lightmapOut*lightmapOut;
	// lightmapOut = (exp2(6*lightmapOut) - 1.0) / 63.0;
	// lightmapOut = 0.28125 / pow(1.5 - lightmapOut, vec2(2.0)) - 0.125;

	#if defined DirectionalLightmap && defined GBUFFERS_TERRAIN

		vec3 blockLightDir = getDirectionalLightmapDir(scenePos, lmcoord.x);
		vec3 skyLightDir   = getDirectionalLightmapDir(scenePos, lmcoord.y);

		if(length(blockLightDir) > 0.0) {
			
			float NdotL  = dot(blockLightDir, texNormal);
			float NGdotL = dot(blockLightDir, tbn[2]);
			
			lightmapOut.r += DirectionalLightmap_Strength * (NdotL - NGdotL) * lightmapOut.r;
		}
		else {
			float NdotL = 0.9 - dot(tbn[2], texNormal);
			lightmapOut.r -= DirectionalLightmap_Strength * NdotL * lightmapOut.r;
		}


		if(length(skyLightDir) > 0.0) {
			
			float NdotL  = dot(skyLightDir, texNormal);
			float NGdotL = dot(skyLightDir, tbn[2]);
			
			lightmapOut.g += DirectionalLightmap_Strength * (NdotL - NGdotL) * lightmapOut.g;
		}
		else {
			float NdotL  = dot(vec3(0.0, 1.0, 0.0), texNormal);
			float NGdotL = dot(vec3(0.0, 1.0, 0.0), tbn[2]);
			
			lightmapOut.g += DirectionalLightmap_Strength * (NdotL - NGdotL) * lightmapOut.g;
		}

	#endif

	#if defined Parallax && defined Parallax_EdgeNormals
		if(pomNormal != vec3(0.0, 0.0, 1.0)) {
			texNormal = tbn * pomNormal;
		}
	#endif

	#ifdef Texture_AO
		lightmapOut *= (rawTexNormal.z * Texture_AO_Strength) + (1.0 - Texture_AO_Strength);
	#endif

	// lightmapOut = clamp(lightmapOut, 0.0, 1.0);
	// lightmapOut.g = 0.0;

	normalOut.rg = packNormalVec2(texNormal);
	// normalOut.ba = packNormalVec2(geomNormal);

	maskOut = mcEntityMask(mcEntity);

    #ifdef GBUFFERS_HAND
        maskOut |= Mask_Hand;
    #endif

	#ifdef Shadow_PerVertexDistortion
		shadowPosOut = shadowPos;
	#endif
	// shadowPosOut = vec3(shadowPos.x < 1.0);

	// testOut = vec4((tangentPos.xy - textureBounds.xy) / (textureBounds.zw - textureBounds.xy), 0.0, 1.0);
	// testOut = vec4(0.0, 0.0, tangentPos.z, 1.0);

	// testOut = vec4(mat3(gbufferModelView) * scenePos, 1.0);
}