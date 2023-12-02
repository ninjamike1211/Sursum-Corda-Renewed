#version 430 compatibility

layout (r8ui) uniform uimage3D voxelImage;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform int renderStage;

#include "/lib/defines.glsl"
#include "/lib/voxel.glsl"

in vec4 at_tangent;
in vec3 at_midBlock;
in vec2 mc_midTexCoord;
in float mc_Entity;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 scenePos;
flat out vec3 glNormal;
flat out vec4 tangent;
flat out vec4 textureBounds;
flat out uint mcEntity;

#if defined UseVoxelization && defined Parallax_DiscardEdge
	flat out ivec3 voxelPos;
	flat out ivec4 pomDiscardEdges;
#endif

void main() {
	gl_Position = ftransform();
	scenePos = (mat3(gbufferModelViewInverse) * (gl_ModelViewMatrix * gl_Vertex).xyz).xyz;

	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = gl_MultiTexCoord1.xy / 240.0;
	glcolor  = gl_Color;

	vec2 halfSize = abs(texcoord - mc_midTexCoord);
	textureBounds = vec4(mc_midTexCoord - halfSize, mc_midTexCoord + halfSize);

	glNormal = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));
	tangent  = vec4(normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * at_tangent.xyz)), at_tangent.w);

	mcEntity = uint(mc_Entity + 0.5);


	#if defined UseVoxelization && defined Parallax_DiscardEdge
		bool isBlock = renderStage == MC_RENDER_STAGE_TERRAIN_SOLID ||
			renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT_MIPPED ||
			renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT ||
			renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT;

		pomDiscardEdges = ivec4(0);
		
		if (isBlock) {
			vec3 centerPos = gl_Vertex.xyz + at_midBlock / 64.0;
			voxelPos = sceneToVoxel(centerPos, cameraPosition);

			if(clamp(voxelPos.xz, ivec2(0), ivec2(512)) == voxelPos.xz) {
				vec3 bitangent = cross(glNormal, tangent.xyz) * sign(tangent.w);

				if(imageLoad(voxelImage, voxelPos + ivec3(round(tangent.xyz))).r == 0
					&& imageLoad(voxelImage, voxelPos + ivec3(round(tangent.xyz)) + ivec3(round(glNormal))).r == 0)
					pomDiscardEdges.x = 1;
				if(imageLoad(voxelImage, voxelPos - ivec3(round(tangent.xyz))).r == 0
					&& imageLoad(voxelImage, voxelPos - ivec3(round(tangent.xyz)) + ivec3(round(glNormal))).r == 0)
					pomDiscardEdges.y = 1;
				if(imageLoad(voxelImage, voxelPos + ivec3(round(bitangent))).r == 0
					&& imageLoad(voxelImage, voxelPos + ivec3(round(bitangent)) + ivec3(round(glNormal))).r == 0)
					pomDiscardEdges.z = 1;
				if(imageLoad(voxelImage, voxelPos - ivec3(round(bitangent))).r == 0
					&& imageLoad(voxelImage, voxelPos - ivec3(round(bitangent)) + ivec3(round(glNormal))).r == 0)
					pomDiscardEdges.w = 1;
			}
		}
	#endif
}