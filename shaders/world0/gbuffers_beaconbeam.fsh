#version 430 compatibility

#define GBUFFERS_BEACONBEAM

#include "/program/gbuffers/solid.frag"

// #include "/lib/defines.glsl"
// #include "/lib/functions.glsl"
// #include "/lib/material.glsl"
// #include "/lib/spaceConvert.glsl"

// uniform sampler2D gtexture;
// uniform sampler2D lightmap;
// uniform sampler2D normals;
// uniform sampler2D specular;
// uniform float alphaTestRef;

// in vec2 lmcoord;
// in vec2 texcoord;
// in vec4 glcolor;
// flat in vec3 glNormal;
// flat in vec4 tangent;
// flat in uint mcEntity;

// /* RENDERTARGETS: 2,3,4,5,6 */
// layout(location = 0) out vec4 albedoOut;
// layout(location = 1) out vec2 normalOut;
// layout(location = 2) out vec4 specularOut;
// layout(location = 3) out vec2 lightmapOut;
// layout(location = 4) out uint maskOut;

// void main() {
// 	albedoOut = texture(gtexture, texcoord) * glcolor;
// 	if (albedoOut.a < 0.9) discard;

// 	// albedoOut.rgb = sRGBToLinear3(albedoOut.rgb);

// 	specularOut = texture(specular, texcoord);
// 	lightmapOut = lmcoord;


// 	vec3 normal = glNormal;
// 	if(!gl_FrontFacing)
// 		normal *= -1.0;
	
// 	mat3 tbn = tbnNormalTangent(normal, tangent);


// 	vec3 texNormal = tbn * extractNormalZ(texture(normals, texcoord).xy * 2.0 - 1.0);

// 	normalOut.rg = packNormalVec2(texNormal);
// 	// normalOut.ba = packNormalVec2(tbn[2]);

// 	maskOut = mcEntityMask(mcEntity);
// }