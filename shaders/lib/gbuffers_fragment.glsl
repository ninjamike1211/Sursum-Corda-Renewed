#extension GL_ARB_conservative_depth : enable

#include "/lib/defines.glsl"

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


#ifndef inNether
	uniform sampler2D shadowtex0;
	uniform sampler2D shadowtex1;
	uniform sampler2D shadowcolor0;
	uniform mat4  shadowModelView;
	uniform mat4  shadowProjection;

	uniform vec3 lightDir;
	uniform vec3 lightDirView;
#endif

#ifdef useGeomStage
in GeomData {

	flat vec3 lightmapBlockDir;
    flat vec3 lightmapSkyDir;

#else
in VertexData {
#endif

    vec2 texcoord;
    vec4 glColor;
    vec2 lmcoord;
    vec3 viewPos;
    vec3 scenePos;
    vec3 tbnPos;
    flat mat3 tbn;
    flat vec4 textureBounds;
    flat vec3 glNormal;
    flat vec3 skyAmbient;
    flat vec3 skyDirect;
    flat int  entity;

    #ifdef inNether
        flat vec3 lightDir;
        flat vec3 lightDirView;
    #endif

    // #ifdef POM_TexSizeFix
        vec2 localTexcoord;
    // #endif

    #if defined TAA || defined MotionBlur
        vec4 oldClipPos;
        vec4 newClipPos;
    #endif

};


/* RENDERTARGETS: 0,1,2,3,5,6,8,4 */
layout(location = 0) out vec4  colorOut;
layout(location = 1) out vec4  albedoOut;
layout(location = 2) out uvec3 materialOut;
layout(location = 3) out vec4  lightmapOut;
layout(location = 4) out vec4  waterDepth;
layout(location = 5) out vec4  velocityOut;
layout(location = 6) out vec4  pomOut;


#define debugOut
#ifdef debugOut
	layout(location = 7) out vec4 testOut;
#endif

layout (depth_greater) out float gl_FragDepth;

#define baseFragment

#include "/lib/material.glsl"
#include "/lib/kernels.glsl"
#include "/lib/noise.glsl"
#include "/lib/functions.glsl"
#include "/lib/sample.glsl"
#include "/lib/TAA.glsl"
#include "/lib/spaceConvert.glsl"

#ifndef inNether
	#include "/lib/shadows.glsl"
#endif

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
	// Water rendering, including normals and POM
	// Weather rain and puddle effects
	// Directional Lightmap
	// Transparent object rendering, including PCSS Shadows, lighting, Dynamic Handlight, and Sub-surface Scattering


/* To fix stupid Optijank errors where it doesn't recognize the POM macro,
   Thanks Builderb0y#1380 for figuring this one out

#ifdef POM
#endif

#ifdef POM_SlopeNormals
#endif

#ifdef DirectionalLightmap
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
				#ifdef POM_TexSizeFix
					vec2 texcoordDx = dFdx(localTexcoord);
					vec3 tbnDx = dFdx(tbnPos);

					vec2 texcoordDy = dFdy(localTexcoord);
					vec3 tbnDy = dFdy(tbnPos);

					vec2 texWorldSize;

					if(abs(texcoordDx.x) > EPS)
						texWorldSize.x = abs(tbnDx.x / texcoordDx.x);
					else if(abs(texcoordDy.x) > EPS)
						texWorldSize.x = abs(tbnDy.x / texcoordDy.x);
					else
						texWorldSize.x = 1.0;

					if(abs(texcoordDx.y) > EPS)
						texWorldSize.y = abs(tbnDx.y / texcoordDx.y);
					else if(abs(texcoordDy.y) > EPS)
						texWorldSize.y = abs(tbnDy.y / texcoordDy.y);
					else
						texWorldSize.y = 1.0;
				#else
					vec2 texWorldSize = vec2(1.0);
				#endif

			// --------------- POM Distance Fade ---------------
				float pomFade = clamp(length(viewPos) - POM_Distance, 0.0, POM_FadeWidth) / POM_FadeWidth;

			// --------- Parallax Mapping and shadows ----------
				if(pomFade < 1.0) {
					vec3 tangentPos = vec3(-1.0);

					float pomOffset = parallaxMapping(texcoordFinal, scenePos, tbn, textureBounds, texWorldSize, lod, POM_Layers, 1.0-pomFade, tangentPos, onEdge, slopeNormal);
					pomOut.b = pomOffset;

					#ifdef POM_Shadow
					if(dot(lightDir, glNormal) > 0.0)
						pomOut.g = parallaxShadows(tangentPos, tbn, textureBounds, texWorldSize, lod, POM_Shadow_Layers, 1.0-pomFade, slopeNormal);
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

	#ifndef inNether

// --------------------------- Water ----------------------------
	if(entity == 10010) {

		// if(isWaterBackface > 0.99999 /* && (textureBounds.z - textureBounds.x) < 1000.0 / atlasSize.y */) //0.0078125004656613 0.00390625023283065 0.001953125116415323
		// 	discard;

		albedo.a = isEyeInWater == 0 ? 0.5 : 0.5;
		// albedo.rgb = vec3(0.0);
		albedo.rgb = 0.3 * glColor.rgb;

		albedo.a = 0.4;

		#ifndef Water_Flat
			// vec3 scenePos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
			vec3 worldPos = scenePos + cameraPosition;

			// albedo.rgb = vec3(waterHeight(worldPos.xz));

			#ifdef Water_POM
			if(geomNormal.y > 0.99999) {
				// vec3 worldPosInitial = worldPos;
				waterParallaxMapping(worldPos, vec2(1.0));

				// testOut = vec4(worldPos - worldPosInitial, 1.0);
				
				// Calculate new screen screenspace position from original view space position and POM depth difference
				vec3 feetPlayerPos = worldPos - cameraPosition;
				vec3 viewPosPDO = (gbufferModelView * vec4(feetPlayerPos, 1.0)).xyz;
				vec3 screenPos = projectAndDivide(gbufferProjection, viewPosPDO) * 0.5 + 0.5;


				// waterDepth = vec4(screenPos.z, 0.0, 0.0, 1.0);
				waterDepth = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);

				#ifdef POM_PDO
					gl_FragDepth = screenPos.z;
				#endif
			}
			else {
				waterDepth = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);
			}
			#endif

			// if(abs(glNormal.y) > 0.1)
			normalVal = normalize(tbn * waterNormal(worldPos)) /* * (isEyeInWater == 1 ? -1.0 : 1.0) */;
		
			if(rainStrength > 0.0) {
				vec3 noiseVals = SimplexPerlin2D_Deriv(20.0 * worldPos.xz + 5.0 * frameCounter);
				vec3 puddleNormal = normalize(vec3(noiseVals.y, 1.0, noiseVals.z));

				normalVal = normalize(normalVal + 0.01 * mix(vec3(0.0), puddleNormal, rainStrength));
			}
		#else
			waterDepth = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);
		#endif
		specMap = vec4(1.0, 0.02, 0.0, 0.0);

	}
	#endif

	vec3 viewNormal = (gbufferModelView * vec4(normalVal, 0.0)).xyz;


// ------------------- Rain and Puddle Effects ------------------
	#if !defined inNether && !defined inEnd
	#if defined terrain || defined block || defined entities || defined hand
		float isWet = wetness * smoothstep(29.0/32.0, 31.0/32.0, lmcoord.g) * smoothstep(-0.75, -0.25, normalVal.y);
		
		if(glNormal.y > 0.99 && isWet > 0.0) {
			vec3 worldPos = scenePos + cameraPosition;

			specMap.r = max(specMap.r, mix(specMap.r, 0.7, isWet));

			// float belowBlock = round(worldPos.y) - worldPos.y;

			#ifdef terrain
			// if(length(textureBounds.zw - textureBounds.xy) > length(vec2(0.9)) && belowBlock < 0.25) {
			if(entity < 10000) {

				float puddleHeight = SimplexPerlin2D(0.25 * worldPos.xz) - ((0.7) * (1.0 - wetness)) + pomOut.b;

				if(puddleHeight > 0.3) {
					vec3 noiseVals = SimplexPerlin2D_Deriv(20.0 * worldPos.xz + 5.0 * frameCounter) * rainStrength;
					vec3 puddleNormal = normalize(vec3(noiseVals.y, 300.0, noiseVals.z));
					// vec3 puddleNormal = vec3(0.0, 1.0, 0.0);

					normalVal  = mix(normalVal,  puddleNormal, smoothstep(0.3, 0.6, puddleHeight));
					geomNormal = mix(geomNormal, puddleNormal, smoothstep(0.3, 0.6, puddleHeight));
					
					pomOut.g = mix(pomOut.g, 1.0, smoothstep(0.3, 0.6, puddleHeight));

					albedo.rgb *= mix(1.0, 0.8, isWet * smoothstep(0.3, 0.9, puddleHeight));
					// albedo.rgb = vec3(1.0);

					specMap.r = mix(specMap.r, 0.95, isWet / wetness * smoothstep(0.3, 0.6, puddleHeight));
				}
			}
			#endif
				
		}
		else
			specMap.r = max(specMap.r, mix(specMap.r, 0.7, isWet));

	#endif
	#endif



// -------------------- Directional Lightmap --------------------
	#if defined DirectionalLightmap && defined useGeomStage

		// vec3 dFdSceneposX = dFdx(scenePos);
		// vec3 dFdSceneposY = dFdy(scenePos);
		
		// vec2 dDepth = vec2(dFdx(gl_FragCoord.z), dFdy(gl_FragCoord.z));
		// vec2 dTbnPosDx = dFdx(tbnPos.xy);
		// vec2 dTbnPosDy = dFdy(tbnPos.xy);
		// vec2 dBlockLight = vec2(dFdx(lmcoord.r), dFdy(lmcoord.r));
		// vec2 dSkyLight = vec2(dFdx(lmcoord.g), dFdy(lmcoord.g));


		// if(length(dBlockLight) > 1e-6) {

		// 	// dBlockLight *= vec2(dFdx(gl_FragCoord.z), dFdy(gl_FragCoord.z));
		// 	vec3 torchLightDir = normalize(dFdSceneposX * dBlockLight.x + dFdSceneposY * dBlockLight.y);


		// 	// float sampleDirDepth = gl_FragCoord.z + dBlockLight.x * dDepth.x + dBlockLight.y * dDepth.y; // Sample Depth of the sample direction position
		// 	// vec3 sampleDirScreen = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight) + dBlockLight, sampleDirDepth);

		// 	// // vec3 sampleDirNdcPos = sampleDirScreen * 2.0 - 1.0;
		// 	// // vec3 sampleDirViewpos = projectAndDivide(gbufferProjectionInverse, sampleDirNdcPos);

		// 	// vec3 sampleDirViewpos = screenToView(sampleDirScreen.xy, sampleDirScreen.z);
		// 	// vec3 sampleDirPosScene = (gbufferModelViewInverse * vec4(sampleDirViewpos, 0.0)).xyz;

		// 	// vec3 torchLightDir = normalize(sampleDirPosScene - scenePos);


		// 	// vec2 scenePosDiffX = dTbnPosDx * dBlockLight.x;
		// 	// vec2 scenePosDiffY = dTbnPosDy * dBlockLight.y;

		// 	// vec3 torchLightDir = normalize(tbn * vec3(scenePosDiffX + scenePosDiffY, 0.0));

			
		// 	// vec3 torcViewDir = screenToView(texcoord + dBlockLight, gl_FragCoord.z) - viewPos;
		// 	// vec3 torchLightDir = mat3(gbufferModelViewInverse) * torcViewDir;
		// 	// testOut = vec4(torchLightDir, 1.0);
		// 	// testOut = vec4(sampleDirPosScene - scenePos, 1.0);
		// 	// testOut = vec4(1000 * abs(dDepth), 0.0, 1.0);

		// testOut = vec4(abs(lightmapBlockDir), 0.0);

		if(length(lightmapBlockDir) > 0.0) {
			
			float NdotL  = dot(lightmapBlockDir, normalVal);
			float NGdotL = dot(lightmapBlockDir, glNormal);
			
			lightmapOut.r += DirectionalLightmap_Strength * (NdotL - NGdotL) * lightmapOut.r;
		}
		else {
			float NdotL = 0.9 - dot(glNormal, normalVal);
			lightmapOut.r -= DirectionalLightmap_Strength * NdotL * lightmapOut.r;
		}


		// if(length(dSkyLight) > 1e-6) {
		if(length(lightmapSkyDir) > 0.0) {
			// vec3 skyLightDir = normalize(dFdSceneposX * dSkyLight.x + dFdSceneposY * dSkyLight.y);
			
			float NdotL  = dot(lightmapSkyDir, normalVal);
			float NGdotL = dot(lightmapSkyDir, glNormal);
			
			lightmapOut.g += DirectionalLightmap_Strength * (NdotL - NGdotL) * lightmapOut.g;
		}
		else {
			float NdotL  = dot(vec3(0.0, 1.0, 0.0), normalVal);
			float NGdotL = dot(vec3(0.0, 1.0, 0.0), glNormal);
			
			lightmapOut.g += DirectionalLightmap_Strength * (NdotL - NGdotL) * lightmapOut.g;
		}

		lightmapOut.rg = clamp(lightmapOut.rg, 1.0/32.0, 31.0/32.0);
		
	#endif

	// lightmapOut.rg *= textureLod(normals, texcoordFinal, lod).b;

	// albedoOut = vec4(albedo.rgb, 1.0);
	albedoOut = albedo;


// -------------------- Transparent Rendering -------------------
	#ifdef afterDeferred
		albedo.rgb = sRGBToLinear(albedo).rgb;

	// -------------------- Shadows --------------------
		float NGdotL = dot(geomNormal, lightDir);

		#ifndef inNether
			float blockerDist;
			vec3 offset = normalToView(lightDir) * pomOut.r;
			vec3 shadowResult = min(vec3(pomOut.g), pcssShadows(viewPos + offset, texcoord, NGdotL, blockerDist));
			
			float shadowMult = 1.0;
			#if defined Shadow_LeakFix && !defined inEnd
				// shadowResult *= smoothstep(9.0/32.0, 21.0/32.0, lmcoord.g);
				shadowResult *= texelFetch(colortex12, ivec2(0.0), 0).a;
			#endif
		#else
			float shadowResult = pomOut.g;
		#endif

	// -------------------- Lighting -------------------
		vec3 viewDir = normalize(-viewPos);

		colorOut.rgb = cookTorrancePBRLighting(albedo.rgb, viewDir, viewNormal, specMap, skyDirect*shadowResult, lightDirView);
		colorOut.rgb += calcAmbient(albedo.rgb, lightmapOut.rg, skyAmbient, specMap);


	// --------------- Dynamic Hand Light --------------
        #ifdef HandLight
			DynamicHandLight(colorOut.rgb, viewPos, albedo.rgb, viewNormal, specMap, lightmapOut.b > 0.5);
        #endif

		colorOut.a = albedo.a;

	// ---------------------- SSS ----------------------
		#if defined SSS && !defined inNether
			float subsurface = extractSubsurface(specMap);
			SubsurfaceScattering(colorOut.rgb, albedo.rgb, subsurface, blockerDist, skyDirect * shadowMult);
		#endif
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

	// vec2 texcoordDx = dFdx(texcoord) / (textureBounds.zw-textureBounds.xy);
	// vec3 tbnDx = dFdx(tbnPos);
	// vec3 sceneDx = dFdx(scenePos);

	// vec2 texcoordDy = dFdy(texcoord) / (textureBounds.zw-textureBounds.xy);
	// vec3 tbnDy = dFdy(tbnPos);
	// vec3 sceneDy = dFdy(scenePos);

	// albedoOut = vec4(vec2(length(sceneDx) / length(texcoordDx), length(sceneDy) / length(texcoordDy)), 0.0, 1.0);

	#ifdef text
		albedoOut = vec4(1.0, 0.0, 1.0, 1.0);
	#endif
}