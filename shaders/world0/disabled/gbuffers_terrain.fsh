#version 400 compatibility

#include "/lib/material.glsl"

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D normals;
uniform sampler2D specular;
uniform float alphaTestRef;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
flat in mat3 tbn;
flat in uint mcEntity;

/* RENDERTARGETS: 2,3,4,5,6 */
layout(location = 0) out vec4 albedoOut;
layout(location = 1) out vec4 normalOut;
layout(location = 2) out vec4 specularOut;
layout(location = 3) out vec2 lightmapOut;
layout(location = 4) out uint maskOut;

void main() {
	albedoOut = texture(gtexture, texcoord) * glcolor;
	if (albedoOut.a < alphaTestRef) discard;

	specularOut = texture(specular, texcoord);
	lightmapOut = lmcoord;

	vec3 texNormal = extractNormalZ(texture(normals, texcoord).xy * 2.0 - 1.0);
	vec3 normal = tbn * texNormal;

	normalOut.rg = packNormalVec2(normal);
	normalOut.ba = packNormalVec2(tbn[2]);

	maskOut = mcEntityMask(mcEntity);
}