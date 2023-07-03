#include "/lib/defines.glsl"

uniform sampler2D  colortex0;
uniform usampler2D colortex2;
uniform sampler2D  colortex5;
uniform sampler2D  colortex6;
uniform sampler2D  colortex7;
uniform sampler2D  colortex10;
uniform sampler2D  depthtex0;
uniform sampler2D  depthtex1;

uniform vec3  lightDir;
uniform mat4  gbufferModelViewInverse;
uniform mat4  gbufferProjection;
uniform vec3  cameraPosition;
uniform vec3 waterColorSmooth;
uniform float frameTimeCounter;
uniform float eyeAltitude;
uniform int   isEyeInWater;

#ifdef waterRefraction
	uniform mat4  gbufferModelView;
#endif

#if defined TAA || defined MotionBlur
	uniform mat4  gbufferProjectionInverse;
	uniform mat4  gbufferPreviousModelView;
	uniform mat4  gbufferPreviousProjection;
	uniform vec3  previousCameraPosition;
#endif

#ifndef inNether
	#ifdef Use_ShadowMap
		uniform sampler2D  shadowtex0;
		uniform sampler2D  shadowtex1;
		uniform sampler2D  shadowcolor0;
		uniform mat4  shadowModelView;
		uniform mat4  shadowProjection;
	#endif

	uniform float far;
	uniform float viewWidth;
	uniform float viewHeight;
	uniform int   frameCounter;
#else
	uniform vec3  fogColor;
#endif

#if !defined inEnd && !defined inNether
	uniform vec3  sunDir;
	uniform float rainStrength;
	uniform float fogDensityMult;
#endif

#ifdef inEnd
	#define UseEndSkyFog
#endif

#include "/lib/material.glsl"
#include "/lib/kernels.glsl"
#include "/lib/noise.glsl"
#include "/lib/functions.glsl"
#include "/lib/TAA.glsl"
#include "/lib/spaceConvert.glsl"
#include "/lib/sample.glsl"
#include "/lib/sky2.glsl"
#include "/lib/clouds.glsl"
#include "/lib/lighting.glsl"
#include "/lib/raytrace.glsl"

#if !defined inNether && defined Use_ShadowMap
	#include "/lib/shadows.glsl"
#endif

// ------------------------ File Contents -----------------------
    // Main Composite pass, combining opaque and transparent geometry
	// Read texture values and calculate various positions
	// Water Refraction (current broken)
	// Apply water and atmospheric fog to opaque objects
	// Apply sky, sun/moon, and atmospheric/water fog to sky
	// Apply water and atmospheric fog to transparent objects
	// Alpha blending


in vec2 texcoord;
in vec3 viewVector;
flat in vec3 skyAmbient;
flat in vec3 skyDirect;

const int noiseTextureResolution = 512;

/* RENDERTARGETS: 0,2,6 */
layout(location = 0) out vec4  colorOut;
layout(location = 1) out uvec3 materialOut;
layout(location = 2) out vec4  velocityOut;


#if defined TAA || defined MotionBlur
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

	vec2 toPrevScreenPos(vec2 currScreenPos){
		return toPrevScreenPos(currScreenPos, texture(depthtex0, currScreenPos.xy).x);
	}
#endif

#ifdef inNether
	void main() {

	// --------------------- Read texture values --------------------
		vec4 transparentColor 	 = texture(colortex0, texcoord);
		uvec3 material 			 = texture(colortex2, texcoord).rgb;
		velocityOut 			 = texture(colortex6, texcoord);
		vec4 opaqueColor 		 = texture(colortex7, texcoord);
		float transparentDepth 	 = texture(depthtex0, texcoord).r;
		float depth 			 = texture(depthtex1, texcoord).r;

		vec3 transparentViewPos  = calcViewPos(viewVector, transparentDepth, gbufferProjection);
		vec3 viewPos 			 = calcViewPos(viewVector, depth, gbufferProjection);
		vec3 eyeDir              = mat3(gbufferModelViewInverse) * normalize(viewPos);
		
		#ifdef VolFog_Nether
			vec3 transparentScenePos = (gbufferModelViewInverse * vec4(transparentViewPos, 1.0)).xyz;
			vec3 scenePos 			 = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
		#endif

		vec4 specMap = SpecularDecode(material.z);
		
		materialOut = material;

		// float fogLuminance = luminance(fogColor);
		// vec3 fogColorNether = 4.0 * fogColor * fogLuminance;
		vec3 fogColorNether = 0.7 * fogColor;


	// ----------------------- Opaque Objects -----------------------
		if(transparentDepth != depth) {

		// ---------------- Water and Atmospheric Fog ---------------
			// fog when player is not underwater
			if(isEyeInWater == 0) {
				#ifdef VolFog_Nether
					netherFogVolumetric(opaqueColor.rgb, transparentScenePos, scenePos, fogColorNether, cameraPosition, frameTimeCounter);
				#else
					netherFog(opaqueColor.rgb, transparentViewPos, viewPos, fogColorNether);
				#endif
			}
			else if(isEyeInWater == 2) {
				lavaFog(opaqueColor.rgb, viewPos - transparentViewPos);
			}
		}


	// --------------------- Alpha Blending ---------------------
		if(transparentColor.a > 0.0 && transparentDepth < 1.0) {
			colorOut = vec4(mix(opaqueColor.rgb, transparentColor.rgb / transparentColor.a, transparentColor.a), 1.0);
		
		}
		else {
			colorOut = opaqueColor;
		}
			

	// ---------------- Water and Atmospheric Fog ---------------
		if(isEyeInWater == 0) {
			#ifdef VolFog_Nether
				netherFogVolumetric(colorOut.rgb, vec3(0.0), scenePos, fogColorNether, cameraPosition, frameTimeCounter);
			#else
				netherFog(colorOut.rgb, length(viewPos), fogColorNether);
			#endif
		}
		else if(isEyeInWater == 2) {
			lavaFog(colorOut.rgb, viewPos);
		}


	}
#else
	void main() {

	// --------------------- Read texture values --------------------
		float waterDepth        = texture(colortex5, texcoord).r;
		float transparentDepth 	= texture(depthtex0, texcoord).r;
		uvec3 material          = texture(colortex2, texcoord).rgb;
		vec3  waterViewPos      = calcViewPos(viewVector, waterDepth, gbufferProjection);

		vec4  transparentColor 	= texture(colortex0, texcoord);
			velocityOut 		= texture(colortex6, texcoord);

	// ---------------------- Water Refraction ----------------------
		#ifdef waterRefraction
			float depth;
			vec4  opaqueColor;
			vec2  texcoordRefract = texcoord;
			vec3  viewDir = normalize(waterViewPos);
			vec3  refractDir = viewDir;

			if(waterDepth != 0.0) {
				vec3 hitPos = vec3(-1.0);

				vec3 normalTex 	= NormalDecode(material.x);
				vec3 normalGeom = NormalDecode(material.y);


				// if(isEyeInWater == 0)
					refractDir = refract(viewDir, normalToView(normalGeom - normalTex, gbufferModelView), 0.93);
					// refractDir = refract(viewDir, normalToView(normalTex, gbufferModelView), 1.05);
				// else if(isEyeInWater == 1)
					// refractDir = refract(viewDir, normalToView(normalTex), 1.);
				// vec3 refractDir = refract(normalize(viewPos), normalToView(normalGeom), 0.75);
				// refractDir = mat3(gbufferModelView) * refractDir;

				float jitter = 0.0;

				bool hit = raytrace(waterViewPos /* - 0.5 * viewDir */, refractDir, 64, jitter, frameCounter, vec2(viewWidth, viewHeight), hitPos, depthtex1, gbufferProjection);

				// if(calcSSRNew(waterViewPos, refractDir, 0.0, hitPos, gbufferProjection, depthtex1, colortex1) != 2) {
				if(isEyeInWater == 1 || hit) {
					texcoordRefract = hitPos.xy;
				}

				// texcoordRefract = hitPos.xy;
			}

			depth       = texture(depthtex1, texcoordRefract).r;
			opaqueColor = texture(colortex7, texcoordRefract);

		#else
			float depth       = texture(depthtex1, texcoord).r;
			vec4  opaqueColor = texture(colortex7, texcoord);
			vec3  viewDir = normalize(waterViewPos);
			vec3  refractDir = viewDir;
		#endif


	// --------------------- Calculate positions --------------------

		vec3 transparentViewPos  = calcViewPos(viewVector, transparentDepth, gbufferProjection);
		vec3 transparentScenePos = (gbufferModelViewInverse * vec4(transparentViewPos, 1.0)).xyz;
		vec3 waterScenePos 		 = (gbufferModelViewInverse * vec4(waterViewPos, 1.0)).xyz;
		
			materialOut = material;
		vec4 specMap     = SpecularDecode(material.z);

		vec3 viewPos  = calcViewPos(viewVector, depth, gbufferProjection);
		vec3 scenePos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;





	// ------------------------ Sky Rendering -----------------------
		if(depth == 1.0) {
			// Read sky value from buffer
			vec3 eyeDir;
			if(waterDepth != 0.0)
				eyeDir = mat3(gbufferModelViewInverse) * normalize(0.05 * viewPos + 100.0 * refractDir);
			else
				eyeDir = mat3(gbufferModelViewInverse) * normalize(viewPos);
			
			vec3 sky = texture(colortex10, projectSphere(eyeDir) * AS_RENDER_SCALE).rgb;

			// Sun disk
			#ifdef inEnd
				float sunDisk = smoothstep(0.985, 0.987, dot(eyeDir, lightDir));
				vec3 sunDiskColor = mix(vec3(50.0, 30.0, 200.0), vec3(-0.85), smoothstep(0.985, 0.9868, dot(eyeDir, lightDir)));
				// sky = mix(sky, sunDiskColor, sunDisk);

				#ifdef cloudsEnable
					applyEndCloudColor(eyeDir, cameraPosition * vec3(50.0, 1.0, 50.0), sky, -skyDirect, far, lightDir, frameTimeCounter);
				#endif

				sky = abs(sky * 2.0);

				sky = mix(sky, sunDiskColor, sunDisk);

				opaqueColor.rgb = sky;

			#else
				float sunDisk = smoothstep(-0.034, 0.05, eyeDir.y) * smoothstep(0.9995, 0.9998, dot(eyeDir, sunDir));
				sky *= mix(1.0, 600.0, sunDisk);

				// Apply moon, hide moon when below horizon
				opaqueColor.rgb = sky + smoothstep(-0.030, 0.05, eyeDir.y) * opaqueColor.rgb * 10.0 /* * step(0.05, opaqueColor.r) */;
			
				#ifdef cloudsEnable
					applyCloudColor(eyeDir, cameraPosition, opaqueColor.rgb, skyDirect, far, lightDir, frameTimeCounter, rainStrength);
				#endif

			#endif

			#ifdef Use_ShadowMap
				viewPos = normalize(viewPos) * 1.7 *shadowDistance;
				scenePos = normalize(scenePos) * 1.7 *shadowDistance;
			#else
				viewPos = normalize(viewPos) * 1.7 *far;
				scenePos = normalize(scenePos) * 1.7 *far;
			#endif

			if(transparentDepth == 1.0) {
				transparentViewPos = viewPos;
				transparentScenePos = scenePos;
			}

				

			specMap.a = sunDisk * 254.0/255.0;
			materialOut.b = SpecularEncode(specMap);

			// Output correct velocity for the sky
			#if defined TAA || defined MotionBlur
				if(transparentDepth == 1.0) {
					vec2 prevScreenPos = toPrevScreenPos(texcoord);
					velocityOut.xy = texcoord - prevScreenPos;
				}
			#endif
		}

			

	// ----------------- Opaque behind transparent ------------------
		if(depth != transparentDepth) {

			// fog when player is not underwater
			if(isEyeInWater == 0) {
				// if there is water in the current pixel, render both water and atmospheric fog
				if(waterDepth != 0.0) {
					#if defined VolWater && defined Use_ShadowMap
						waterVolumetricFog(waterScenePos, scenePos, skyDirect, skyAmbient, waterColorSmooth, opaqueColor.rgb, texcoord, vec2(viewWidth, viewHeight), frameCounter);
					#else
						waterFog(waterViewPos, viewPos, skyDirect, skyAmbient, opaqueColor.rgb, waterColorSmooth);
					#endif

					// If there is transparent, then water, then opaque include the atmospheric fog for the opaque
					if(transparentDepth - waterDepth < -EPS) {
						#ifdef inEnd
							endFog(opaqueColor.rgb, transparentScenePos, waterScenePos, colortex10);
						#else
							#if defined VolFog && defined Use_ShadowMap
								volumetricFog(opaqueColor.rgb, transparentScenePos, waterScenePos, texcoord, skyDirect, vec2(viewWidth, viewHeight), fogDensityMult, frameCounter, frameTimeCounter, cameraPosition);
							#else
								fog(opaqueColor, transparentScenePos, waterViewPos, skyDirect, fogDensityMult);
							#endif
						#endif
					}
				}
				// if there is no water, only render atmospheric fog
				else {
					#ifdef inEnd
						endFog(opaqueColor.rgb, transparentScenePos, scenePos, colortex10);
					#else
						#if defined VolFog && defined Use_ShadowMap
							volumetricFog(opaqueColor.rgb, transparentScenePos, scenePos, texcoord, skyDirect, vec2(viewWidth, viewHeight), fogDensityMult, frameCounter, frameTimeCounter, cameraPosition);
						#else
							fog(opaqueColor, transparentScenePos, viewPos, skyDirect, fogDensityMult);
						#endif
					#endif
				}
			}

			// fog when player is underwater
			else if(isEyeInWater == 1) {
				// if the current pixel contains the surface of water, render both water and atmospheric fog
				if(waterDepth != 0.0) {
					#ifdef inEnd
						endFog(opaqueColor.rgb, waterScenePos, scenePos, colortex10);
					#else
						#if defined VolFog && defined Use_ShadowMap
							volumetricFog(opaqueColor.rgb, waterScenePos, viewPos, texcoord, skyDirect, vec2(viewWidth, viewHeight), fogDensityMult, frameCounter, frameTimeCounter, cameraPosition);
						#else
							fog(opaqueColor, waterViewPos, viewPos, skyDirect, fogDensityMult);
						#endif
					#endif

					// If there is transparent, then water, then opaque include extra water fog for the opaque
					if(transparentDepth - waterDepth < -EPS) {
						#if defined VolWater && defined Use_ShadowMap
							waterVolumetricFog(transparentScenePos, waterScenePos, skyDirect, skyAmbient, waterColorSmooth, opaqueColor.rgb, texcoord, vec2(viewWidth, viewHeight), frameCounter);
						#else
							waterFog(transparentViewPos, waterViewPos, skyDirect, skyAmbient, opaqueColor.rgb, waterColorSmooth);
						#endif
					}
				}
				// if the current pixel doesn't contain the surface of water, only render water fog
				else {
					#if defined VolWater && defined Use_ShadowMap
						// waterVolumetricFog(opaqueColor, vec3(0.0), viewPos, texcoord, skyDirect, lightDir);
						waterVolumetricFog(transparentScenePos, scenePos, skyDirect, skyAmbient, waterColorSmooth, opaqueColor.rgb, texcoord, vec2(viewWidth, viewHeight), frameCounter);
					#else
						waterFog(transparentScenePos, viewPos, skyDirect, skyAmbient, opaqueColor.rgb, waterColorSmooth);
					#endif
				}
			}
			else if(isEyeInWater == 2) {
				lavaFog(opaqueColor.rgb, viewPos - transparentViewPos);
			}
			else if(isEyeInWater == 3) {
				snowFog(opaqueColor.rgb, viewPos - transparentViewPos);
			}
		}

	// ----------- Transparent Objects and Alpha Blending -----------
		if(transparentColor.a > 0.0 && transparentDepth < 1.0) {
			colorOut = vec4(mix(opaqueColor.rgb, transparentColor.rgb / transparentColor.a, transparentColor.a), 1.0);
		}
		else {
			colorOut = opaqueColor;
		}
			

	// ---------------- Water and Atmospheric Fog ---------------
		// fog when player is not underwater
		if(isEyeInWater == 0) {
			#ifdef inEnd
				endFog(colorOut.rgb, vec3(0.0), transparentScenePos, colortex10);
			#else
				#if defined VolFog && defined Use_ShadowMap
					volumetricFog(colorOut.rgb, vec3(0.0), transparentScenePos, texcoord, skyDirect, vec2(viewWidth, viewHeight), fogDensityMult, frameCounter, frameTimeCounter, cameraPosition);
				#else
					fog(colorOut, vec3(0.0), transparentViewPos, skyDirect, fogDensityMult);
				#endif
			#endif
		}
		// fog when player is underwater
		else if(isEyeInWater == 1) {
			#if defined VolWater && defined Use_ShadowMap
				waterVolumetricFog(vec3(0.0), transparentScenePos, skyDirect, skyAmbient, waterColorSmooth, colorOut.rgb, texcoord, vec2(viewWidth, viewHeight), frameCounter);
			#else
				waterFog(vec3(0.0), transparentViewPos, skyDirect, skyAmbient, colorOut.rgb, waterColorSmooth);
			#endif
		}
		else if(isEyeInWater == 2) {
			lavaFog(colorOut.rgb, viewPos);
		}
		else if(isEyeInWater == 3) {
			snowFog(colorOut.rgb, viewPos);
		}
	}
#endif