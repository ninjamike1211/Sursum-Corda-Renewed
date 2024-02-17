#version 430 compatibility
#extension GL_ARB_conservative_depth : enable

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D normals;
uniform sampler2D specular;
uniform float alphaTestRef;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform vec3 shadowLightPosition;
uniform ivec2 atlasSize;

#include "/lib/defines.glsl"
#include "/lib/functions.glsl"
#include "/lib/material.glsl"
#include "/lib/spaceConvert.glsl"
#include "/lib/parallax.glsl"

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 scenePos;
flat in vec3 glNormal;
flat in vec4 tangent;
flat in vec4 textureBounds;
flat in uint mcEntity;

/* RENDERTARGETS: 2,3,4,5,6,7 */
layout(location = 0) out vec4 albedoOut;
layout(location = 1) out vec4 normalOut;
layout(location = 2) out vec4 specularOut;
layout(location = 3) out vec2 lightmapOut;
layout(location = 4) out uint maskOut;
layout(location = 5) out vec4 pomOut;
// layout(location = 6) out vec4 testOut;

void main() {
	// vec3 normal = glNormal;
	// if(!gl_FrontFacing)
	// 	normal *= -1.0;
	// mat3 tbn = tbnNormalTangent(normal, tangent);

	// mat2 dFdXY = mat2(dFdx(texcoord), dFdy(texcoord));
	// vec3 tangentPos = vec3(texcoord, 1.0);

	// vec3 lightDir = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);

	// // parallax(tangentPos, scenePos, tbn, bvec4(false, false, false, false), textureBounds, dFdXY);
	// float shadow = parallaxWithShadows(tangentPos, scenePos, lightDir, tbn, bvec4(true), textureBounds, dFdXY);
	// pomOut = vec4(shadow, 0.0, 0.0, 1.0);

	// parallaxApplyDepthOffset(tangentPos, scenePos, texcoord, tbn, gbufferModelView, gl_ProjectionMatrix);
	// pomOut.g = parallaxShadowDist(tangentPos, lightDir, tbn);

	// albedoOut = textureGrad(gtexture, tangentPos.xy, dFdXY[0], dFdXY[1]) * glcolor;
	// if (albedoOut.a < alphaTestRef) discard;

	// specularOut = textureGrad(specular, tangentPos.xy, dFdXY[0], dFdXY[1]);
	// lightmapOut = lmcoord;

	
	// vec3 rawTexNormal = textureGrad(normals, tangentPos.xy, dFdXY[0], dFdXY[1]).xyz;
	// vec3 texNormal = tbn * extractNormalZ(rawTexNormal.xy * 2.0 - 1.0);

	// #ifdef Texture_AO
	// 	lightmapOut *= (rawTexNormal.z * Texture_AO_Strength) + (1.0 - Texture_AO_Strength);
	// #endif

	// normalOut.rg = packNormalVec2(texNormal);
	// normalOut.ba = packNormalVec2(tbn[2]);

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

	pomOut = vec4(1.0, 0.0, 0.0, 1.0);
	vec3 geomNormal = tbn[2];

	#ifdef Parallax
		vec3 pomNormal;
		pomOut.r = parallax(tangentPos, texcoordFinal, pomNormal, scenePos, lightDir, tbn, textureBounds, atlasSize, dFdXY);

		// #ifdef Parallax_DepthOffset
		// 	parallaxApplyDepthOffset(tangentPos, scenePos, texcoord, tbn, gbufferModelView, gbufferProjection);

		// 	if(dot(geomNormal, lightDir) >= 0.0)
		// 		pomOut.g = parallaxShadowDist(tangentPos, lightDir, tbn);
		// #endif
		
	#endif

	albedoOut = textureGrad(gtexture, texcoordFinal, dFdXY[0], dFdXY[1]) * glcolor;
	if (albedoOut.a < alphaTestRef) discard;

	specularOut = textureGrad(specular, texcoordFinal, dFdXY[0], dFdXY[1]);
	lightmapOut = lmcoord;

	vec3 rawTexNormal = textureGrad(normals, texcoordFinal, dFdXY[0], dFdXY[1]).xyz;
	vec3 texNormal = tbn * extractNormalZ(rawTexNormal.xy * 2.0 - 1.0);

	#if defined Parallax && defined Parallax_EdgeNormals
		geomNormal = tbn * pomNormal;
		if(pomNormal != vec3(0.0, 0.0, 1.0)) {
			texNormal = geomNormal;
		}
	#endif

	#ifdef Texture_AO
		lightmapOut *= (rawTexNormal.z * Texture_AO_Strength) + (1.0 - Texture_AO_Strength);
	#endif

	normalOut.rg = packNormalVec2(texNormal);
	normalOut.ba = packNormalVec2(geomNormal);

	maskOut = mcEntityMask(mcEntity) | Mask_Hand;
}