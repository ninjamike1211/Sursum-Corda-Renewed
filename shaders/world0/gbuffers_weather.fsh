#version 430 compatibility

#include "/lib/defines.glsl"
#include "/lib/functions.glsl"
#include "/lib/material.glsl"
#include "/lib/spaceConvert.glsl"
#include "/lib/sky.glsl"

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D normals;
uniform sampler2D specular;
uniform mat4 gbufferModelViewInverse;
uniform vec3 lightDir;
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
layout(location = 2) out vec2 normalOut;
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
	// normalOut.ba = packNormalVec2(tbn[2]);

	maskOut = mcEntityMask(mcEntity);


	float NGdotL = dot(glNormal, lightDir);
	vec3 directLight = skyLight.skyDirect;

	colorOut.rgb = cookTorrancePBRLighting(albedo.rgb, normalize(-scenePos), texNormal, specularOut, directLight, lightDir);
	colorOut.rgb += albedo.rgb * calcLightmap(lmcoord, skyLight.skyAmbient);
	colorOut.a = albedo.a;
}