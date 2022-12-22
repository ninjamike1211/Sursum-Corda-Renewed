#version 400 compatibility

uniform sampler2D colortex0;
uniform usampler2D colortex1;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D colortex9;
uniform sampler2D colortex10;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

uniform vec3 lightDir;
uniform vec3 sunDir;
uniform vec3 sunDirView;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform float frameTimeCounter;
uniform float eyeAltitude;
uniform int isEyeInWater;
uniform float rainStrength;
uniform mat4  shadowModelView;
uniform mat4  shadowProjection;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform int   frameCounter;
uniform int   worldTime;
uniform bool  cameraMoved;
uniform float sunHeight;
uniform float shadowHeight;
uniform int moonPhase;
uniform float fogDensityMult;
uniform float heldBlockLightValue;
uniform float heldBlockLightValue2;
uniform int   heldItemId;
uniform int   heldItemId2;
uniform vec3 fogColor;

#include "/lib/defines.glsl"
#include "/lib/material.glsl"
#include "/lib/kernels.glsl"
#include "/lib/noise.glsl"
#include "/lib/functions.glsl"
#include "/lib/TAA.glsl"
#include "/lib/spaceConvert.glsl"
#include "/lib/sample.glsl"
#include "/lib/sky2.glsl"
#include "/lib/shadows.glsl"
#include "/lib/lighting.glsl"
#include "/lib/clouds.glsl"
#include "/lib/raytrace.glsl"

// #define waterRefraction


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

/* RENDERTARGETS: 0,4,6 */
layout(location = 0) out vec4 colorOut;
layout(location = 1) out vec4 specMapOut;
layout(location = 2) out vec4 velocityOut;


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


void main() {

// --------------------- Read texture values --------------------
	vec4 transparentColor 	= texture(colortex0, texcoord);
	uvec2 normalRaw 		= texture(colortex1, texcoord).rg;
	vec4 specMap 			= texture(colortex4, texcoord);
	float waterDepth 		= texture(colortex5, texcoord).r;
	velocityOut 			= texture(colortex6, texcoord);
	vec4 opaqueColor 		= texture(colortex7, texcoord);
	float transparentDepth 	= texture(depthtex0, texcoord).r;
	float depth 			= texture(depthtex1, texcoord).r;

	vec3 transparentViewPos = calcViewPos(viewVector, transparentDepth);
	vec3 viewPos 			= calcViewPos(viewVector, depth);
	vec3 scenePos 			= (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	vec3 waterViewPos 		= calcViewPos(viewVector, waterDepth);
	vec3 waterScenePos 		= (gbufferModelViewInverse * vec4(waterViewPos, 1.0)).xyz;

	vec3 normalTex 	= NormalDecode(normalRaw.x);
	vec3 normalGeom = NormalDecode(normalRaw.y);

	specMapOut = specMap;


// ---------------------- Water Refraction ----------------------
	// Water Refraction NEEDS TO BE FIXED, ASSUMES VIEW SPACE NORMALS WHEN THERE AREN'T
	#ifdef waterRefraction
		if(waterDepth != 0.0) {
			vec3 hitPos = vec3(-1.0);
			vec3 refractDir = refract(normalize(viewPos), normalToView(normalTex - normalGeom), isEyeInWater == 1 ? 1.333 : 0.75);
			float jitter = 10.0;

			// if(calcSSRNew(waterViewPos, refractDir, 0.0, hitPos, gbufferProjection, depthtex1, colortex1) != 2) {
			if(raytrace(viewPos, refractDir, 64, jitter, hitPos)) {
				opaqueColor = texture(colortex7, hitPos.xy);
			}
			else {
			    opaqueColor = vec4(0.0);
			}
		}
	#endif


// ----------------------- Opaque Objects -----------------------
	if(depth < 1.0) {

	// ---------------- Water and Atmospheric Fog ---------------
		// fog when player is not underwater
		if(isEyeInWater == 0) {
			// if there is water in the current pixel, render both water and atmospheric fog
			if(waterDepth != 0.0) {
				#ifdef VolWater
					// waterVolumetricFog(opaqueColor, waterViewPos, viewPos, texcoord, skyDirect, lightDir);
					waterVolumetricFog(waterScenePos, scenePos, skyDirect, opaqueColor.rgb, texcoord);
				#else
					waterFog(opaqueColor, waterViewPos, viewPos, skyDirect);
				#endif

				#ifdef VolFog
					volumetricFog(opaqueColor, vec3(0.0), waterViewPos, texcoord, skyDirect);
				#else
					fog(opaqueColor, vec3(0.0), waterViewPos, skyDirect);
				#endif
			}
			// if there is no water, only render atmospheric fog
			else {
				#ifdef VolFog
					volumetricFog(opaqueColor, vec3(0.0), viewPos, texcoord, skyDirect);
				#else
					fog(opaqueColor, vec3(0.0), viewPos, skyDirect);
				#endif
			}
		}
		// fog when player is underwater
		else if(isEyeInWater == 1) {
			// if the current pixel contains the surface of water, render both water and atmospheric fog
			if(waterDepth != 0.0) {
				#ifdef VolFog
					volumetricFog(opaqueColor, waterViewPos, viewPos, texcoord, skyDirect);
				#else
					fog(opaqueColor, waterViewPos, viewPos, skyDirect);
				#endif

				#ifdef VolWater
					// waterVolumetricFog(opaqueColor, vec3(0.0), waterViewPos, texcoord, skyDirect, lightDir);
					waterVolumetricFog(vec3(0.0), waterScenePos, skyDirect, opaqueColor.rgb, texcoord);
				#else
					waterFog(opaqueColor, vec3(0.0), waterViewPos, skyDirect);
				#endif
			}
			// if the current pixel doesn't contain the surface of water, only render water fog
			else {
				#ifdef VolWater
					// waterVolumetricFog(opaqueColor, vec3(0.0), viewPos, texcoord, skyDirect, lightDir);
					waterVolumetricFog(vec3(0.0), scenePos, skyDirect, opaqueColor.rgb, texcoord);
				#else
					waterFog(opaqueColor, vec3(0.0), viewPos, skyDirect);
				#endif
			}
		}
	}


// ------------------------ Sky Rendering -----------------------
	else {
		// Read sky value from buffer
		vec3 eyeDir = mat3(gbufferModelViewInverse) * normalize(viewPos);
		vec3 sky = texture(colortex10, projectSphere(eyeDir) * AS_RENDER_SCALE).rgb;

		// Sun disk
		float sunDisk = smoothstep(-0.034, 0.05, eyeDir.y) * smoothstep(0.9995, 0.9998, dot(normalize(viewPos), sunDirView));
		sky *= mix(1.0, 400.0, sunDisk);
		specMapOut.a = sunDisk * 254.0/255.0;

		// Apply moon, hide moon when below horizon
		opaqueColor.rgb = sky + smoothstep(-0.030, 0.05, eyeDir.y) * opaqueColor.rgb * 10.0 /* * step(0.05, opaqueColor.r) */;

		// Apply clouds
		#ifdef cloudsEnable
			applyCloudColor(eyeDir, vec3(0.0, eyeAltitude, 0.0), opaqueColor.rgb, skyDirect);
		#endif

		// Output correct velocity for the sky
		#if defined TAA || defined MotionBlur
			if(transparentDepth == 1.0) {
				vec2 prevScreenPos = toPrevScreenPos(texcoord);
				velocityOut.xy = texcoord - prevScreenPos;
			}
		#endif

		// water and atmospheric fog applied to sky
		// fog when player is not underwater
		if(isEyeInWater == 0) {
			// if there is no water, only render atmospheric fog
			if(waterDepth == 0.0) {
				#ifdef VolFog
					volumetricFog(opaqueColor, vec3(0.0), normalize(viewPos) * 30.0, texcoord, skyDirect);
				#else
					fog(opaqueColor, vec3(0.0), normalize(viewPos) * 30.0, skyDirect);
				#endif
			}
			// if there is water in the current pixel, render both water and atmospheric fog
			else {
				#ifdef VolWater
					waterVolumetricFog(opaqueColor, waterViewPos, normalize(viewPos) * far, texcoord, skyDirect, lightDir);
				#else
					waterFog(opaqueColor, waterViewPos, normalize(viewPos) * far, skyDirect);
				#endif

				#ifdef VolFog
					volumetricFog(opaqueColor, vec3(0.0), waterViewPos, texcoord, skyDirect);
				#else
					fog(opaqueColor, vec3(0.0), waterViewPos, skyDirect);
				#endif
			}
		}
		// fog when player is underwater
		else if(isEyeInWater == 1) {
			if(waterDepth != 0.0) {
				// render atmospheric fog
				#ifdef VolFog
					volumetricFog(opaqueColor, waterViewPos, normalize(viewPos) * 30.0, texcoord, skyDirect);
				#else
					fog(opaqueColor, waterViewPos, normalize(viewPos) * 30.0, skyDirect);
				#endif

				// render water fog
				#ifdef VolWater
					// waterVolumetricFog(opaqueColor, vec3(0.0), waterViewPos, texcoord, skyDirect, lightDir);
					waterVolumetricFog(vec3(0.0), waterScenePos, skyDirect, opaqueColor.rgb, texcoord);
				#else
					waterFog(opaqueColor, vec3(0.0), waterViewPos, skyDirect);
				#endif
			}
			else {
				#ifdef VolWater
					waterVolumetricFog(opaqueColor, vec3(0.0), normalize(viewPos) * far, texcoord, skyDirect, lightDir);
				#else
					waterFog(opaqueColor, vec3(0.0), normalize(viewPos) * far, skyDirect);
				#endif
			}
		}
	}


// ----------- Transparent Objects and Alpha Blending -----------
	if(transparentColor.a > 0.0 && transparentDepth < 1.0) {
		
	// ---------------- Water and Atmospheric Fog ---------------
		// fog when player is not underwater
		if(isEyeInWater == 0) {
			// If there is water in front of the transparent object
			if(waterDepth != 0.0 && transparentDepth > waterDepth) {
				#ifdef VolFog
					volumetricFog(transparentColor, vec3(0.0), waterViewPos, texcoord, skyDirect);
				#else
					fog(transparentColor, vec3(0.0), waterViewPos, skyDirect);
				#endif

				#ifdef VolWater
					waterVolumetricFog(transparentColor, waterViewPos, transparentViewPos, texcoord, skyDirect, lightDir);
				#else
					waterFog(transparentColor, waterViewPos, transparentViewPos, skyDirect);
				#endif
			}
			// No water in front of transparent object
			else {
				#ifdef VolFog
					volumetricFog(transparentColor, vec3(0.0), transparentViewPos, texcoord, skyDirect);
				#else
					fog(transparentColor, vec3(0.0), transparentViewPos, skyDirect);
				#endif
			}
		}
		// fog when player is underwater
		else if(isEyeInWater == 1) {
			// transparent object is outside of water
			if(waterDepth != 0.0 && transparentDepth > waterDepth) {
				#ifdef VolWater
					// waterVolumetricFog(transparentColor, vec3(0.0), waterViewPos, texcoord, skyDirect, lightDir);
					waterVolumetricFog(vec3(0.0), waterScenePos, skyDirect, opaqueColor.rgb, texcoord);
				#else
					waterFog(transparentColor, vec3(0.0), waterViewPos, skyDirect);
				#endif

				#ifdef VolFog
					volumetricFog(transparentColor, waterViewPos, transparentViewPos, texcoord, skyDirect);
				#else
					fog(transparentColor, waterViewPos, transparentViewPos, skyDirect);
				#endif
			}
			// transparent object is underwater
			else {
				#ifdef VolWater
					waterVolumetricFog(transparentColor, vec3(0.0), transparentViewPos, texcoord, skyDirect, lightDir);
				#else
					waterFog(transparentColor, vec3(0.0), transparentViewPos, skyDirect);
				#endif
			}
		}


	// --------------------- Alpha Blending ---------------------
		colorOut = vec4(mix(opaqueColor.rgb, transparentColor.rgb / transparentColor.a, transparentColor.a), 1.0);
	}
	else {
		colorOut = opaqueColor;
	}
}