uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
// uniform vec3 lightDir;
// uniform vec3 lightDirView;
uniform vec3 cameraPosition;
uniform float alphaTestRef;
uniform float frameTimeCounter;
// uniform int renderStage;
uniform int isEyeInWater;
uniform ivec2 atlasSize;
uniform bool inEnd;
uniform bool inNether;
uniform int heldItemId;
uniform int heldBlockLightValue;
uniform int heldItemId2;
uniform int heldBlockLightValue2;
// uniform int frameCounter;
uniform vec4 entityColor;
uniform sampler2D colortex12;

uniform sampler2D texture;
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2D depthtex1;
uniform sampler2D noisetex;

flat in vec2 singleTexSize;

/* RENDERTARGETS: 0,1,2,3,4,5,6,8 */
layout(location = 0) out vec4 colorOut;
layout(location = 1) out uvec2 normalOut;
layout(location = 2) out vec4 albedoOut;
layout(location = 3) out vec4 lightmapOut;
layout(location = 4) out vec4 specMapOut;
layout(location = 5) out vec4 waterDepth;
layout(location = 6) out vec4 velocityOut;
layout(location = 7) out vec4 pomOut;

#define debugOut
#define baseFragment

flat in vec3 lightDir;
flat in vec3 lightDirView;

uniform mat4  gbufferProjection;
uniform mat4  gbufferProjectionInverse;
uniform float rainStrength;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform int   frameCounter;
uniform int   worldTime;
uniform bool  cameraMoved;
uniform float eyeAltitude;
uniform float fogDensityMult;

#include "/lib/defines.glsl"
#include "/lib/material.glsl"
#include "/lib/kernels.glsl"
#include "/lib/noise.glsl"
#include "/lib/functions.glsl"
#include "/lib/lighting.glsl"
#include "/lib/parallax.glsl"
#include "/lib/water.glsl"

in vec2 texcoord;
in vec4 glColor;
flat in vec3 glNormal;
in vec2 lmcoord;
in vec3 viewPos;
in vec3 scenePos;
in vec3 tbnPos;
flat in vec4 textureBounds;
flat in int entity;
flat in vec3 skyAmbient;
flat in vec3 skyDirect;
flat in mat3 tbn;

#if defined TAA || defined MotionBlur
	in vec4 oldClipPos;
	in vec4 newClipPos;
#endif

/* To fix stupid Optijank errors where it doesn't recognize POM,
   Thanks Builderb0y#1380 for figuring this one out
   
#ifdef POM
#endif
*/

// in float isWaterBackface;

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

// ---------------------- TAA Velocity ----------------------
	#if defined TAA || defined MotionBlur
		vec2 oldPos = oldClipPos.xy / oldClipPos.w;
		oldPos = oldPos * 0.5 + 0.5;

		vec2 newPos = newClipPos.xy / newClipPos.w;
		newPos = newPos * 0.5 + 0.5;

		velocityOut = vec4(newPos - oldPos, 0.0, 1.0);

		// #ifdef hand
		// 	velocityOut.xy *= MC_HAND_DEPTH;
		// #endif
	#endif

// ------------------------- Water ------------------------
	// if(entity == 10010) {
	// 	waterDepth = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);

	// 	return;
	// }

// ---------------------- End Portal ----------------------
	if(entity == 10020) {

		vec3 worldPos  = scenePos + cameraPosition;
		// vec2 samplePos = fract(worldPos.xz + worldPos.y);

		applyEndPortal(worldPos, albedoOut.rgb, specMapOut);

		normalOut.x = NormalEncode(glNormal);
		normalOut.y = normalOut.x;

		lightmapOut = vec4(lmcoord, 0.0, 1.0);

		pomOut = vec4(0.0, 0.0, 0.0, 1.0);

		// colorOut = albedoOut;

		return;
	}

	// Calculate lod beforehand
	float lod = textureQueryLod(texture, texcoord).x;

	vec2 texcoordFinal = texcoord;
	pomOut = vec4(0.0, 1.0, 0.0, 1.0);
	vec3 geomNormal = glNormal;

// ---------------------- Paralax Occlusion Mapping ----------------------
	#ifdef usePBRTextures
		vec2 slopeNormal = vec2(0.0);
		bool onEdge = false;
		vec3 normalVal = vec3(0.0);
		
		#if defined POM && defined usePOM
			// Exclude grass and flat plants (they often cause issues)
			if(entity < 10002 || (entity > 10004 && entity < 10010)) {

				// Calculate world space texture size
				vec2 texcoordDx = dFdx(texcoord) / (textureBounds.zw-textureBounds.xy);
				vec3 tbnDx = dFdx(tbnPos);
				// vec2 texWorldSizeX = tbnDx.xy / texcoordDx;
				vec3 sceneDx = dFdx(scenePos);

				vec2 texcoordDy = dFdy(texcoord) / (textureBounds.zw-textureBounds.xy);
				vec3 tbnDy = dFdy(tbnPos);
				// vec2 texWorldSizeY = tbnDy.xy / texcoordDy;
				vec3 sceneDy = dFdy(scenePos);

				// vec2 texWorldSize = min(max(texWorldSizeX, texWorldSizeY), vec2(1.0));
				// vec2 texWorldSize = vec2(viewDx.x, viewDy.y) / vec2(texcoordDx.x, texcoordDy.y);
				vec2 texWorldSize = vec2(length(sceneDx) / length(texcoordDx), length(sceneDy) / length(texcoordDy));


				float pomFade = clamp(length(viewPos) - POM_Distance, 0.0, POM_FadeWidth) / POM_FadeWidth;

				if(pomFade < 1.0) {
					// #ifdef POM_PDO
					// 	gl_FragDepth = mix(parallaxShadowDepthOffset(texcoordFinal, scenePos, pomOut.g, tbn, textureBounds, texWorldSize, lod, 1.0-pomFade, onEdge, slopeNormal), gl_FragCoord.z, pomFade);

					// #else
					// 	// Calculates POM and stores texture alligned depth from POM
					// 	vec3 shadowTexcoord = vec3(-1.0);
					// 	float zOffset = parallaxMapping(texcoordFinal, scenePos, tbn, textureBounds, vec2(1.0), lod, POM_Layers, 1.0-pomFade, shadowTexcoord, onEdge, slopeNormal);
						
					// 	// Calculate shadow
					// 	pomOut.g = parallaxShadows(shadowTexcoord, tbn, textureBounds, vec2(1.0), lod, POM_Shadow_Layers, 1.0-pomFade, slopeNormal);
					// #endif

					vec3 shadowTexcoord = vec3(-1.0);
					float pomOffset = parallaxMapping(texcoordFinal, scenePos, tbn, textureBounds, vec2(1.0), lod, POM_Layers, 1.0-pomFade, shadowTexcoord, onEdge, slopeNormal);
					
					#ifdef POM_Shadow
						pomOut.g = parallaxShadows(shadowTexcoord, tbn, textureBounds, vec2(1.0), lod, POM_Shadow_Layers, 1.0-pomFade, slopeNormal);
					#endif

					#ifdef POM_PDO
						vec3 texDir = normalize(scenePos) * tbn;
						vec3 sceneDiff = tbn * ((texDir / texDir.z) * pomOffset);
						vec3 scenePosFinal = scenePos - sceneDiff;
						vec3 viewPosFinal = (gbufferModelView * vec4(scenePosFinal, 1.0)).xyz;
						vec3 screenPos = projectAndDivide(gbufferProjection, viewPosFinal) * 0.5 + 0.5;

						gl_FragDepth = screenPos.z;
						// gl_FragDepth = gl_FragCoord.z;

						vec3 lightDirTbn = lightDir * tbn;
						vec3 lightDiff = lightDirTbn / lightDirTbn.z * pomOffset;
						pomOut.r = length(lightDiff);
					#endif
				}
				#ifdef POM_PDO
				else {
					gl_FragDepth = gl_FragCoord.z;
				}
				#endif

				#ifdef POM_SlopeNormals
					#if POM_Filter > 0
						// geomNormal = tbn * parallaxSmoothSlopeNormal(texcoordFinal, textureBounds, lod);
						normalVal = tbn * extractNormalZ(textureLod(normals, texcoordFinal, lod).rg * 2.0 - 1.0);
						// normalVal = geomNormal;

					#else
						if(onEdge) {
							normalVal = tbn * vec3(slopeNormal, 0.0);
							geomNormal = normalVal;
						}
						else
							normalVal = tbn * extractNormalZ(textureLod(normals, texcoordFinal, lod).rg * 2.0 - 1.0);
					#endif
				#else
					normalVal = tbn * extractNormalZ(textureLod(normals, texcoordFinal, lod).rg * 2.0 - 1.0);
				#endif
			}
			else {
				#ifdef POM_PDO
					gl_FragDepth = gl_FragCoord.z;
				#endif
				normalVal = tbn * extractNormalZ(textureLod(normals, texcoordFinal, lod).rg * 2.0 - 1.0);
			}
		#else
			normalVal = tbn * extractNormalZ(textureLod(normals, texcoordFinal, lod).rg * 2.0 - 1.0);
		#endif

		vec4 specMap = textureLod(specular, texcoordFinal, lod);
	#else
		vec3 normalVal = glNormal;
		vec4 specMap = vec4(0.0, 0.0, 0.0, 1.0);
	#endif


	// Read texture values
	vec4 albedo = textureLod(texture, texcoordFinal, lod) * vec4(glColor.rgb, 1.0);
	if (albedo.a < alphaTestRef) discard;

	#ifdef hand
		lightmapOut = vec4(lmcoord, 1.0, 1.0);
	#else
		lightmapOut = vec4(lmcoord, 0.0, 1.0);
	#endif

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

	// Water
	#ifdef water
	if(entity == 10010) {

		// if(isWaterBackface > 0.99999 /* && (textureBounds.z - textureBounds.x) < 1000.0 / atlasSize.y */) //0.0078125004656613 0.00390625023283065 0.001953125116415323
		// 	discard;

		albedo.a = isEyeInWater == 0 ? 0.5 : 0.5;
		albedo.rgb = vec3(0.0);

		#ifndef Water_Flat
			// vec3 scenePos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
			vec3 worldPos = scenePos + cameraPosition;

			// albedo.rgb = vec3(waterHeight(worldPos.xz));

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

			// if(abs(glNormal.y) > 0.1)
				normalVal = normalize(tbn * waterNormal(worldPos)) /* * (isEyeInWater == 1 ? -1.0 : 1.0) */;
		#else
			waterDepth = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);
		#endif
		specMap = vec4(1.0, 0.05, 0.0, 0.0);

	}
	#endif

	vec3 viewNormal = (gbufferModelView * vec4(normalVal, 0.0)).xyz;

	#ifdef DirectionalLightmap
		vec3 dFdSceneposX = dFdx(scenePos);
		vec3 dFdSceneposY = dFdy(scenePos);
		vec2 dFdTorch = vec2(dFdx(lmcoord.r), dFdy(lmcoord.r));

		vec3 torchLightDir = dFdSceneposX * dFdTorch.x + dFdSceneposY * dFdTorch.y;
		if(length(dFdTorch) > 1e-6) {
			lightmapOut.r *= clamp(dot(normalize(torchLightDir), normalVal) + 0.8, 0.0, 1.0) * 0.8 + 0.2;
		}
		else {
			lightmapOut.r *= clamp(dot(tbn * vec3(0.0, 0.0, 1.0), normalVal), 0.0, 1.0);
		}

		lightmapOut.rg = clamp(lightmapOut.rg, 1.0/32.0, 31.0/32.0);
	#endif

	albedoOut = vec4(albedo.rgb, 1.0);

	// Transparent rendering
	// if(		renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT
	// 		|| renderStage == MC_RENDER_STAGE_TRIPWIRE
	// 		|| renderStage == MC_RENDER_STAGE_PARTICLES
	// 		|| renderStage == MC_RENDER_STAGE_RAIN_SNOW
	// 		|| renderStage == MC_RENDER_STAGE_WORLD_BORDER
	// 		|| renderStage == MC_RENDER_STAGE_HAND_TRANSLUCENT)
	// {
	// if(albedo.a < 1.0) {
	#ifdef afterDeferred
		albedo.rgb = sRGBToLinear(albedo).rgb;

		// Prepare lighting and shadows
		float NGdotL = dot(geomNormal, lightDir);
		vec3 shadowResult = vec3(pomOut.g);

		// Perform lighting calcualtions
		vec3 viewDir = normalize(-viewPos);

		colorOut.rgb = cookTorrancePBRLighting(albedo.rgb, viewDir, viewNormal, specMap, skyDirect*shadowResult, lightDirView);
		colorOut.rgb += calcAmbient(albedo.rgb, lightmapOut.rg, skyAmbient, specMap);

	// -------------- Dynamic Hand Light --------------
        #ifdef HandLight
			DynamicHandLight(colorOut.rgb, viewPos, albedo.rgb, viewNormal, specMap, lightmapOut.b > 0.5);
			
            // if(heldBlockLightValue > 0) {
            //     vec3 lightPos = vec3(0.2, -0.1, 0.0);
            //     vec3 lightDir = -normalize(viewPos - lightPos);
            //     float dist = length(viewPos - lightPos);
                
            //     vec3 lightColor = vec3(2.0 * float(heldBlockLightValue) / (15.0 * dist * dist));

            //     #ifdef HandLight_Colors
            //         if(heldItemId == 10001)
            //             lightColor *= vec3(0.2, 3.0, 10.0);
            //         else if(heldItemId == 10002)
            //             lightColor *= vec3(10.0, 1.5, 0.0);
            //         else if(heldItemId == 10003)
            //             lightColor *= vec3(15.0, 4.0, 1.5);
            //         else if(heldItemId == 10004)
            //             lightColor *= vec3(3.0, 6.0, 15.0);
            //         else if(heldItemId == 10005)
            //             lightColor *= vec3(1.5, 1.0, 10.0);
            //         else if(heldItemId == 10006)
            //             lightColor *= vec3(4.0, 1.0, 10.0);
            //         else
            //     #endif
            //         lightColor *= vec3(15.0, 7.2, 2.9);

			// 	#ifdef HandLight_Shadows
			// 		float jitter = texture2D(noisetex, texcoord * 20.0 + frameTimeCounter).r;
			// 		lightColor *= ssShadows(viewPos, lightPos, jitter, depthtex1);
			// 	#endif

            //     // vec3 normalUse = isHand < 0.9 ? normal : playerDir;
            //     colorOut.rgb += cookTorrancePBRLighting(albedo.rgb, viewDir, viewNormal, specMap, lightColor, lightDir);
            // }
            // if(heldBlockLightValue2 > 0) {
            //     vec3 lightPos = vec3(-0.2, -0.1, 0.0);
            //     vec3 lightDir = -normalize(viewPos - lightPos);
            //     float dist = length(viewPos - lightPos);
                
            //     vec3 lightColor = vec3(2.0 * float(heldBlockLightValue2) / (15.0 * dist * dist));

            //     #ifdef HandLight_Colors
            //         if(heldItemId2 == 10001)
            //             lightColor *= vec3(0.2, 3.0, 10.0);
            //         else if(heldItemId2 == 10002)
            //             lightColor *= vec3(10.0, 1.5, 0.0);
            //         else if(heldItemId2 == 10003)
            //             lightColor *= vec3(15.0, 4.0, 1.5);
            //         else if(heldItemId2 == 10004)
            //             lightColor *= vec3(3.0, 6.0, 15.0);
            //         else if(heldItemId2 == 10005)
            //             lightColor *= vec3(1.5, 1.0, 10.0);
            //         else if(heldItemId2 == 10006)
            //             lightColor *= vec3(4.0, 1.0, 10.0);
            //         else
            //     #endif
            //         lightColor *= vec3(15.0, 7.2, 2.9);

			// 	#ifdef HandLight_Shadows
			// 		float jitter = texture2D(noisetex, texcoord * 20.0 + frameTimeCounter).r;
			// 		lightColor *= ssShadows(viewPos, lightPos, jitter, depthtex1);
			// 	#endif

            //     // vec3 normalUse = isHand < 0.9 ? normal : playerDir;
            //     colorOut.rgb += cookTorrancePBRLighting(albedo.rgb, viewDir, viewNormal, specMap, lightColor, lightDir);
            // }
        #endif

		colorOut.a = albedo.a;
	#endif

	// Output values to buffers
	normalOut = uvec2(NormalEncode(normalVal), NormalEncode(geomNormal));

	specMapOut = specMap;


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
	// albedoOut.rgb = abs(glColor.rgb);

	// albedoOut.rgb = textureBicubicFull(normals, texcoord, textureBounds).aaa;
	// albedoOut.rgb = textureBicubicWrap(normals, texcoord, textureBounds).aaa;
	// albedoOut.rgb = vec3(interpolateHeight(texcoord, textureBounds, 0.0));
	// pomOut.g = 0.0;
	// albedoOut.rgb = vec3(pomOut.b);
	// pomOut.b = 0.0;
}