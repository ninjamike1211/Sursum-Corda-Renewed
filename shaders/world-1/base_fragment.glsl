#extension GL_ARB_conservative_depth : enable

uniform sampler2D tex;
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2D colortex12;
uniform sampler2D depthtex1;

uniform mat4  gbufferModelView;
uniform mat4  gbufferModelViewInverse;
uniform mat4  gbufferProjection;
uniform mat4  gbufferProjectionInverse;
uniform vec4  entityColor;
uniform vec3  cameraPosition;
uniform vec3  fogColor;
uniform ivec2 atlasSize;
uniform float eyeAltitude;
uniform float alphaTestRef;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float wetness;
uniform float frameTimeCounter;
uniform float fogDensityMult;
uniform int   frameCounter;
uniform int   isEyeInWater;
uniform int   worldTime;
uniform int   heldItemId;
uniform int   heldBlockLightValue;
uniform int   heldItemId2;
uniform int   heldBlockLightValue2;
uniform bool  cameraMoved;

flat in vec3 lightDir;
flat in vec3 lightDirView;

/* RENDERTARGETS: 0,1,2,3,5,6,8 */
layout(location = 0) out vec4  colorOut;
layout(location = 1) out vec4  albedoOut;
layout(location = 2) out uvec3 materialOut;
layout(location = 3) out vec4  lightmapOut;
layout(location = 4) out vec4  waterDepth;
layout(location = 5) out vec4  velocityOut;
layout(location = 6) out vec4  pomOut;


// #define debugOut
// #ifdef debugOut
// 	layout(location = 7) out vec4 testOut;
// #endif

layout (depth_greater) out float gl_FragDepth;

#define baseFragment

#include "/lib/defines.glsl"
#include "/lib/material.glsl"
#include "/lib/kernels.glsl"
#include "/lib/noise.glsl"
#include "/lib/functions.glsl"
#include "/lib/sample.glsl"
#include "/lib/TAA.glsl"
#include "/lib/spaceConvert.glsl"
#include "/lib/lighting.glsl"
#include "/lib/parallax.glsl"
#include "/lib/water.glsl"


// ------------------------ File Contents -----------------------
    // Gbuffers primary fragment shader
    // Motion vector calculations for TAA or Motion Blur
	// End portal visuals and overrides
	// Reading and processing textures and materials
	// Parallax Mapping, including Parallax Shadows, Pixel-Depth-Offset, and Slope Normals
	// Fixes and overries for specific geometry
	// Directional Lightmap
	// Transparent object rendering, lighting, and Dynamic Handlight


in vec4 glColor;
in vec3 viewPos;
in vec3 scenePos;
in vec3 tbnPos;
in vec2 texcoord;
in vec2 lmcoord;
flat in mat3 tbn;
flat in vec4 textureBounds;
flat in vec3 glNormal;
flat in vec3 skyAmbient;
flat in vec3 skyDirect;
flat in int  entity;

#if defined TAA || defined MotionBlur
	in vec4 oldClipPos;
	in vec4 newClipPos;
#endif

/* To fix stupid Optijank errors where it doesn't recognize the POM macro,
   Thanks Builderb0y#1380 for figuring this one out

#ifdef POM
#endif

#ifdef POM_SlopeNormals
#endif
*/


#ifdef entities
	uniform mat4 gbufferPreviousModelView;
	uniform mat4 gbufferPreviousProjection;
	uniform vec3 previousCameraPosition;


	// Fast screen reprojection by Eldeston#3590 with reference from Chocapic13 and Jessie#7257
	// Source: https://discord.com/channels/237199950235041794/525510804494221312/955506913834070016
	vec2 toPrevScreenPos(vec2 currScreenPos, float depth){
		vec3 currViewPos = vec3(vec2(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y) * (currScreenPos.xy * 2.0 - 1.0) + gbufferProjectionInverse[3].xy, gbufferProjectionInverse[3].z);
		currViewPos /= (gbufferProjectionInverse[2].w * (depth * 2.0 - 1.0) + gbufferProjectionInverse[3].w);
		vec3 currFeetPlayerPos = mat3(gbufferModelViewInverse) * currViewPos + gbufferModelViewInverse[3].xyz;

		vec3 prevFeetPlayerPos = depth > 0.56 ? currFeetPlayerPos + cameraPosition - previousCameraPosition : currFeetPlayerPos;
		vec3 prevViewPos = mat3(gbufferPreviousModelView) * prevFeetPlayerPos + gbufferPreviousModelView[3].xyz;
		vec2 finalPos = vec2(gbufferPreviousProjection[0].x, gbufferPreviousProjection[1].y) * prevViewPos.xy + gbufferPreviousProjection[3].xy;
		return (finalPos / -prevViewPos.z) * 0.5 + 0.5;
	}
#endif


void main() {

// ----------------------- Motion Vectors -----------------------
	#if defined TAA || defined MotionBlur
		vec2 oldPos = oldClipPos.xy / oldClipPos.w;
		oldPos = oldPos * 0.5 + 0.5;

		vec2 newPos = newClipPos.xy / newClipPos.w;
		newPos = newPos * 0.5 + 0.5;

		velocityOut = vec4(newPos - oldPos, 0.0, 1.0);

	#endif


// ------------------------- End Portal -------------------------
	if(entity == 10020) {

		vec3 worldPos  = scenePos + cameraPosition;
		vec4 specMap;

		applyEndPortal(worldPos, albedoOut.rgb, specMap);

		materialOut.r = NormalEncode(glNormal);
		materialOut.g = materialOut.x;
		materialOut.b = SpecularEncode(specMap);

		lightmapOut = vec4(lmcoord, 0.0, 1.0);

		pomOut = vec4(0.0, 1.0, 0.0, 1.0);

		return;
	}

// ---------------- Texture and Material Handling ---------------
	// Calculate lod beforehand
	float lod = textureQueryLod(tex, texcoord).x;

	vec2 texcoordFinal = texcoord;
	pomOut = vec4(0.0, 1.0, 0.0, 1.0);
	vec3 geomNormal = glNormal;

	#ifdef POM_PDO
		gl_FragDepth = gl_FragCoord.z;
	#endif

	#ifdef usePBRTextures
		
	// ------------------ Paralax Occlusion Mapping -----------------
		#if defined POM && defined usePOM
			
			vec3 normalVal = vec3(0.0);


			// Exclude grass and flat plants (they often cause issues)
			if(entity < 10002 || (entity > 10004 && entity < 10010)) {

				vec2 slopeNormal = vec2(0.0);
				bool onEdge = false;

			// ---------- Texture Size in World Space ----------
				vec2 texcoordDx = dFdx(texcoord) / (textureBounds.zw-textureBounds.xy);
				vec3 tbnDx = dFdx(tbnPos);
				vec3 sceneDx = dFdx(scenePos);

				vec2 texcoordDy = dFdy(texcoord) / (textureBounds.zw-textureBounds.xy);
				vec3 tbnDy = dFdy(tbnPos);
				vec3 sceneDy = dFdy(scenePos);

				vec2 texWorldSize = abs(vec2(length(sceneDx) / length(texcoordDx), length(sceneDy) / length(texcoordDy)));

			// --------------- POM Distance Fade ---------------
				float pomFade = clamp(length(viewPos) - POM_Distance, 0.0, POM_FadeWidth) / POM_FadeWidth;

			// --------- Parallax Mapping and shadows ----------
				if(pomFade < 1.0) {
					vec3 shadowTexcoord = vec3(-1.0);

					float pomOffset = parallaxMapping(texcoordFinal, scenePos, tbn, textureBounds, vec2(1.0), lod, POM_Layers, 1.0-pomFade, shadowTexcoord, onEdge, slopeNormal);
					pomOut.b = pomOffset;

					#ifdef POM_Shadow
						pomOut.g = parallaxShadows(shadowTexcoord, tbn, textureBounds, vec2(1.0), lod, POM_Shadow_Layers, 1.0-pomFade, slopeNormal);
					#endif

				// ---------- Parallax Pixel Depth Offset ----------
					#ifdef POM_PDO
						vec3 texDir = normalize(scenePos) * tbn;
						vec3 sceneDiff = tbn * ((texDir / texDir.z) * pomOffset);
						vec3 scenePosFinal = scenePos - sceneDiff;
						vec3 viewPosFinal = (gbufferModelView * vec4(scenePosFinal, 1.0)).xyz;
						vec3 screenPos = projectAndDivide(gbufferProjection, viewPosFinal) * 0.5 + 0.5;

						gl_FragDepth = screenPos.z;

						vec3 lightDirTbn = lightDir * tbn;
						vec3 lightDiff = lightDirTbn / lightDirTbn.z * pomOffset;
						pomOut.r = length(lightDiff);
					#endif
				}
				// #ifdef POM_PDO
				// else {
				// 	gl_FragDepth = gl_FragCoord.z;
				// }
				// #endif

			// ------------- Parallax Slope Normals ------------
				#if defined POM_SlopeNormals && POM_Filter == 0
					if(onEdge) {
						normalVal = tbn * vec3(slopeNormal, 0.0);
						geomNormal = normalVal;
					}
					else
						normalVal = tbn * extractNormalZ(textureLod(normals, texcoordFinal, lod).rg * 2.0 - 1.0);
				#else
					normalVal = tbn * extractNormalZ(textureLod(normals, texcoordFinal, lod).rg * 2.0 - 1.0);
				#endif
			}
			else {
				// #ifdef POM_PDO
				// 	gl_FragDepth = gl_FragCoord.z;
				// #endif
				normalVal = tbn * extractNormalZ(textureLod(normals, texcoordFinal, lod).rg * 2.0 - 1.0);
			}
		#else
			vec3 normalVal = tbn * extractNormalZ(textureLod(normals, texcoordFinal, lod).rg * 2.0 - 1.0);
		#endif

		vec4 specMap = textureLod(specular, texcoordFinal, lod);
	#else
		vec3 normalVal = glNormal;
		vec4 specMap = vec4(0.0, 0.0, 0.0, 1.0);
	#endif

	// Read texture values
	vec4 albedo = textureLod(tex, texcoordFinal, lod) * glColor;
	if (albedo.a < alphaTestRef) discard;

	#ifdef hand
		lightmapOut = vec4(lmcoord, 1.0, 1.0);
	#else
		lightmapOut = vec4(lmcoord, 0.0, 1.0);
	#endif


// ---------------------- Fixes/Overrides -----------------------

	// Apply SSS to grass and similar blocks
	if(entity > 10000) {
		if(entity < 10010) {
			if(specMap.b == 0.0) {
				specMap.b = 1.0;
			}
		}
		else if(entity == 10011) {
			if(specMap.a == 0.0 || specMap.a == 1.0)
				specMap.a = 254.0/255.0;
		}
	}

	// Name tag fix
	#ifdef entities
		albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);

		if(all(lessThanEqual(textureLod(normals, texcoordFinal, lod).rg, vec2(EPS)))) {
			specMap.a = 0.4;
			// albedo.rgb *= 5.0;
			normalVal = lightDir;
			geomNormal = lightDir;

			#if defined TAA || defined MotionBlur
				vec2 oldPos = toPrevScreenPos(newPos, gl_FragCoord.z);
				velocityOut = vec4(newPos - oldPos, 0.0, 1.0);
			#endif
		}
	#endif

	#ifdef BeaconBeam
		specMap.a = 254.0/255.0;
	#endif


// -------------------- Directional Lightmap --------------------
	#ifdef DirectionalLightmap
	// if(gl_FragCoord.x > 0.5*viewWidth) {
		vec3 dFdSceneposX = dFdx(scenePos);
		vec3 dFdSceneposY = dFdy(scenePos);
		vec2 dFdTorch = vec2(dFdx(lmcoord.r), dFdy(lmcoord.r));
		vec2 dFdSky = vec2(dFdx(lmcoord.g), dFdy(lmcoord.g));


		if(length(dFdTorch) > 1e-6) {
			vec3 torchLightDir = normalize(dFdSceneposX * dFdTorch.x + dFdSceneposY * dFdTorch.y);
			
			float NdotL  = dot(torchLightDir, normalVal);
			float NGdotL = dot(torchLightDir, glNormal);
			
			lightmapOut.r += DirectionalLightmap_Strength * (NdotL - NGdotL) * lightmapOut.r;
		}
		else {
			float NdotL = 0.9 - dot(glNormal, normalVal);
			lightmapOut.r -= DirectionalLightmap_Strength * NdotL * lightmapOut.r;
		}


		// lightmapOut.g = 0.0;
		if(length(dFdSky) > 1e-6) {
			vec3 skyLightDir = normalize(dFdSceneposX * dFdSky.x + dFdSceneposY * dFdSky.y);
			
			float NdotL  = dot(skyLightDir, normalVal);
			float NGdotL = dot(skyLightDir, glNormal);
			
			lightmapOut.g += DirectionalLightmap_Strength * (NdotL - NGdotL) * lightmapOut.g;
		}
		else {
			float NdotL  = dot(vec3(0.0, 1.0, 0.0), normalVal);
			float NGdotL = dot(vec3(0.0, 1.0, 0.0), glNormal);
			
			lightmapOut.g += DirectionalLightmap_Strength * (NdotL - NGdotL) * lightmapOut.g;
		}

		lightmapOut.rg = clamp(lightmapOut.rg, 1.0/32.0, 31.0/32.0);
	// }
	#endif

	// lightmapOut.rg *= textureLod(normals, texcoordFinal, lod).b;

	// albedoOut = vec4(albedo.rgb, 1.0);
	albedoOut = albedo;


// -------------------- Transparent Rendering -------------------
	#ifdef afterDeferred
		albedo.rgb = sRGBToLinear(albedo).rgb;


	// -------------------- Lighting -------------------
		vec3 viewDir = normalize(-viewPos);
		vec3 viewNormal = (gbufferModelView * vec4(normalVal, 0.0)).xyz;
		float NGdotL = dot(geomNormal, lightDir);

		colorOut.rgb = cookTorrancePBRLighting(albedo.rgb, viewDir, viewNormal, specMap, skyDirect * pomOut.g, lightDirView);
		colorOut.rgb += calcAmbient(albedo.rgb, lightmapOut.rg, skyAmbient, specMap);


	// --------------- Dynamic Hand Light --------------
        #ifdef HandLight
			DynamicHandLight(colorOut.rgb, viewPos, albedo.rgb, viewNormal, specMap, lightmapOut.b > 0.5);
        #endif

		colorOut.a = albedo.a;

	#endif


// -------------------- Final Texture Writes --------------------
	materialOut.r = NormalEncode(normalVal);
	materialOut.g = NormalEncode(geomNormal);
	materialOut.b = SpecularEncode(specMap);
	// materialOut.a = 4294967295;
	// specMapOut = vec4(specMap.rgb, 1.0);
	// specMapOut = specMap;


// ------------ Debug Stuff (disable when not using) ------------
	// albedoOut = vec4(texture2D(texture, texcoord).rgb * glColor.rgb, 1.0);
	// albedoOut = vec4(glColor.rgb, 1.0);
	// albedoOut = vec4(texcoord, 0.0, 1.0);
	// albedoOut = vec4(length(textureBounds.zw - textureBounds.xy) * 100.0, 0.0, 0.0, 1.0);

	// #ifdef block
	// 	// albedoOut = textureLod(normals, texcoord, lod);
	// 	albedoOut = vec4(test, 0.0, 0.0, 1.0);
	// #endif

	// albedoOut.rgb = vec3(length(glColor.rgb) > EPS);
	// albedoOut.rgb = glColor.rgb;

	// albedoOut.rgb = textureBicubicFull(normals, texcoord, textureBounds).aaa;
	// albedoOut.rgb = textureBicubicWrap(normals, texcoord, textureBounds).aaa;
	// albedoOut.rgb = vec3(interpolateHeight(texcoord, textureBounds, 0.0));
	// pomOut.g = 0.0;
	// albedoOut.rgb = vec3(pomOut.b);
	// pomOut.b = 0.0;
}