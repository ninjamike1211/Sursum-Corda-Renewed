#version 400 compatibility

uniform sampler2D colortex0;
uniform usampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex5;
uniform sampler2D colortex7;
uniform sampler2D colortex9;
uniform sampler2D colortex10;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D noisetex;
uniform vec3 lightDir;
uniform vec3 sunDir;
uniform vec3 sunDirView;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform float eyeAltitude;
uniform int isEyeInWater;
uniform float wetness;
uniform float rainStrength;
uniform bool inEnd;
uniform bool inNether;

#include "/functions.glsl"
// #include "sky.glsl"
#include "/sky2.glsl"
#include "/lighting.glsl"
#include "/noise.glsl"
#include "/clouds.glsl"
#include "/raytrace.glsl"

uniform vec3 fogColor;

// #define waterRefraction

in vec2 texcoord;
in vec3 viewVector;
flat in vec3 SunMoonColor;

const int noiseTextureResolution = 512;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 colorOut;
// layout(location = 1) out vec4 SSAOOut;

void main() {
	// Calculate depths and positions
	vec4 transparentColor = texture2D(colortex0, texcoord);
	// Read opaque color from textre
	// albedo = texture2D(colortex2, texcoord);
	vec4 opaqueColor = texture2D(colortex7, texcoord);

	float depth = texture2D(depthtex1, texcoord).r;
	uvec2 normalRaw = texture2D(colortex1, texcoord).rg;
	float transparentDepth = texture2D(depthtex0, texcoord).r;
	vec3 transparentViewPos = calcViewPos(viewVector, transparentDepth);
	float waterDepth = texture2D(colortex5, texcoord).r;

	vec3 viewPos = calcViewPos(viewVector, depth);
	vec3 waterViewPos = calcViewPos(viewVector, waterDepth);

	vec3 normalTex 	= NormalDecode(normalRaw.x);
	vec3 normalGeom = NormalDecode(normalRaw.y);

	// Water Refraction NEEDS TO BE FIXED, ASSUMES VIEW SPACE NORMALS WHEN THERE AREN'T
	#ifdef waterRefraction
		if(waterDepth != 0.0) {
			vec3 hitPos = vec3(-1.0);
			vec3 refractDir = refract(normalize(viewPos), normalToView(normalTex), isEyeInWater == 1 ? 1.333 : 0.75);
			float jitter = 10.0;

			// if(calcSSRNew(waterViewPos, refractDir, 0.0, hitPos, gbufferProjection, depthtex1, colortex1) != 2) {
			if(raytrace(viewPos, refractDir, 64, jitter, hitPos)) {
				opaqueColor = texture2D(colortex7, hitPos.xy);
			}
			else {
			    opaqueColor = vec4(0.0);
			}
		}
	#endif

	// Fog/sky color
	vec3 eyeDir = mat3(gbufferModelViewInverse) * normalize(viewPos);
	vec3 skyColor = texture2D(colortex10, projectSphere(eyeDir) * AS_RENDER_SCALE).rgb;

	// #ifdef cloudsEnable
	// 	applyNetherCloudColor(eyeDir, vec3(0.0, eyeAltitude, 0.0), skyColor, fogColor);
	// #endif

	// Opaque objects
	if(depth < 1.0) {

		// SSAO
        #ifdef SSAO
			vec3 occlusion = texture2D(colortex9, texcoord).rgb;
			opaqueColor.rgb *= occlusion;
		#endif

		// opaque water and atmospheric fog
		// fog when player is not underwater
		if(isEyeInWater == 0) {
			// if there is water in the current pixel, render both water and atmospheric fog
			if(waterDepth != 0.0) {
				// #ifdef VolWater
				// 	waterVolumetricFog(opaqueColor, waterViewPos, viewPos, texcoord, frameTimeCounter, eyeAltitude, SunMoonColor, lightDir, shadowtex0, shadowtex1, shadowcolor0, noisetex, gbufferModelViewInverse);
				// #else
					waterFog(opaqueColor, waterViewPos, viewPos, SunMoonColor);
				// #endif

				// #ifdef VolFog
				// 	volumetricFog(opaqueColor, vec3(0.0), waterViewPos, texcoord, frameTimeCounter, SunMoonColor, shadowtex0, shadowtex1, shadowcolor0, noisetex, gbufferModelViewInverse);
				// #else
					netherFog(opaqueColor, vec3(0.0), waterViewPos, skyColor);
				// #endif
			}
			// if there is no water, only render atmospheric fog
			else {
				// #ifdef VolFog
				// 	volumetricFog(opaqueColor, vec3(0.0), viewPos, texcoord, frameTimeCounter, SunMoonColor, shadowtex0, shadowtex1, shadowcolor0, noisetex, gbufferModelViewInverse);
				// #else
					netherFog(opaqueColor, vec3(0.0), viewPos, skyColor);
				// #endif
			}
		}
		// fog when player is underwater
		else if(isEyeInWater == 1) {
			// if the current pixel contains the surface of water, render both water and atmospheric fog
			if(waterDepth != 0.0) {
				// #ifdef VolFog
				// 	volumetricFog(opaqueColor, waterViewPos, viewPos, texcoord, frameTimeCounter, SunMoonColor, shadowtex0, shadowtex1, shadowcolor0, noisetex, gbufferModelViewInverse);
				// #else
					netherFog(opaqueColor, waterViewPos, viewPos, skyColor);
				// #endif

				// #ifdef VolWater
				// 	waterVolumetricFog(opaqueColor, vec3(0.0), waterViewPos, texcoord, frameTimeCounter, eyeAltitude, SunMoonColor, lightDir, shadowtex0, shadowtex1, shadowcolor0, noisetex, gbufferModelViewInverse);
				// #else
					waterFog(opaqueColor, vec3(0.0), waterViewPos, SunMoonColor);
				// #endif
			}
			// if the current pixel doesn't contain the surface of water, only render water fog
			else {
				// #ifdef VolWater
				// 	waterVolumetricFog(opaqueColor, vec3(0.0), viewPos, texcoord, frameTimeCounter, eyeAltitude, SunMoonColor, lightDir, shadowtex0, shadowtex1, shadowcolor0, noisetex, gbufferModelViewInverse);
				// #else
					waterFog(opaqueColor, vec3(0.0), viewPos, SunMoonColor);
				// #endif
			}
		}
	}

	// Sky rendering
	else {
		// // Read sky values from brightness
		// vec3 eyeDir = mat3(gbufferModelViewInverse) * normalize(viewPos);
		// vec3 sky = texture2D(colortex10, projectSphere(eyeDir) * AS_RENDER_SCALE).rgb;

		// // Sun disk
		// sky *= mix(1.0, 25.0, smoothstep(-0.030, -0.022, eyeDir.y) * smoothstep(0.9985, 0.9995, dot(normalize(viewPos), sunDirView)));
		// // Hide moon when below horizon
		// opaqueColor.rgb = sky + smoothstep(-0.030, -0.022, eyeDir.y) * opaqueColor.rgb;

		opaqueColor.rgb = skyColor;

		#ifdef cloudsEnable
			applyNetherCloudColor(eyeDir, vec3(0.0, eyeAltitude, 0.0), opaqueColor.rgb, fogColor);
		#endif

		// water and atmospheric fog applied to sky
		// fog when player is not underwater
		if(isEyeInWater == 0) {
			// if there is no water, only render atmospheric fog
			if(waterDepth == 0.0) {
				// #ifdef VolFog
				// 	volumetricFog(opaqueColor, vec3(0.0), normalize(viewPos) * 30.0, texcoord, frameTimeCounter, SunMoonColor, shadowtex0, shadowtex1, shadowcolor0, noisetex, gbufferModelViewInverse);
				// #else
					netherFog(opaqueColor, vec3(0.0), normalize(viewPos) * 30.0, skyColor);
				// #endif
			}
			// if there is water in the current pixel, render both water and atmospheric fog
			else {
				// #ifdef VolWater
				// 	waterVolumetricFog(opaqueColor, waterViewPos, normalize(viewPos) * far, texcoord, frameTimeCounter, eyeAltitude, SunMoonColor, lightDir, shadowtex0, shadowtex1, shadowcolor0, noisetex, gbufferModelViewInverse);
				// #else
					waterFog(opaqueColor, waterViewPos, normalize(viewPos) * far, SunMoonColor);
				// #endif

				// #ifdef VolFog
				// 	volumetricFog(opaqueColor, vec3(0.0), waterViewPos, texcoord, frameTimeCounter, SunMoonColor, shadowtex0, shadowtex1, shadowcolor0, noisetex, gbufferModelViewInverse);
				// #else
					netherFog(opaqueColor, vec3(0.0), waterViewPos, skyColor);
				// #endif
			}
		}
		// fog when player is underwater
		else if(isEyeInWater == 1) {
			if(waterDepth != 0.0) {
				// render atmospheric fog
				// #ifdef VolFog
				// 	volumetricFog(opaqueColor, waterViewPos, normalize(viewPos) * 30.0, texcoord, frameTimeCounter, SunMoonColor, shadowtex0, shadowtex1, shadowcolor0, noisetex, gbufferModelViewInverse);
				// #else
					netherFog(opaqueColor, waterViewPos, normalize(viewPos) * 30.0, skyColor);
				// #endif

				// render water fog
				// #ifdef VolWater
				// 	waterVolumetricFog(opaqueColor, vec3(0.0), waterViewPos, texcoord, frameTimeCounter, eyeAltitude, SunMoonColor, lightDir, shadowtex0, shadowtex1, shadowcolor0, noisetex, gbufferModelViewInverse);
				// #else
					waterFog(opaqueColor, vec3(0.0), waterViewPos, SunMoonColor);
				// #endif
			}
			else {
				// #ifdef VolWater
				// 	waterVolumetricFog(opaqueColor, vec3(0.0), normalize(viewPos) * far, texcoord, frameTimeCounter, eyeAltitude, SunMoonColor, lightDir, shadowtex0, shadowtex1, shadowcolor0, noisetex, gbufferModelViewInverse);
				// #else
					waterFog(opaqueColor, vec3(0.0), normalize(viewPos) * far, SunMoonColor);
				// #endif
			}
		}
	}

	if(transparentColor.a > 0.0 && transparentDepth < 1.0) {
		// if(specMap.a != 0.0) {
		//     if(transparentColor.r < -0.1) {
		//         transparentColor.rgb = vec3(0.0);
		//     }
		//     else {
		//         transparentColor.rgb = texture2D(colortex13, transparentColor.rg).rgb;
		//     }
		// }
		if(isEyeInWater == 0) {
			if(waterDepth != 0.0 && transparentDepth >= waterDepth) {
				// #ifdef VolFog
				// 	volumetricFog(transparentColor, vec3(0.0), waterViewPos, texcoord, frameTimeCounter, SunMoonColor, shadowtex0, shadowtex1, shadowcolor0, noisetex, gbufferModelViewInverse);
				// #else
					netherFog(transparentColor, vec3(0.0), waterViewPos, skyColor);
				// #endif

				// #ifdef VolWater
				// 	waterVolumetricFog(transparentColor, waterViewPos, transparentViewPos, texcoord, frameTimeCounter, eyeAltitude, SunMoonColor, lightDir, shadowtex0, shadowtex1, shadowcolor0, noisetex, gbufferModelViewInverse);
				// #else
					waterFog(transparentColor, waterViewPos, transparentViewPos, SunMoonColor);
				// #endif
			}
			else {
				// #ifdef VolFog
				// 	volumetricFog(transparentColor, vec3(0.0), transparentViewPos, texcoord, frameTimeCounter, SunMoonColor, shadowtex0, shadowtex1, shadowcolor0, noisetex, gbufferModelViewInverse);
				// #else
					netherFog(transparentColor, vec3(0.0), transparentViewPos, skyColor);
				// #endif
			}
		}
		else if(isEyeInWater == 1) {
			if(waterDepth != 0.0 && transparentDepth > waterDepth) {
				// #ifdef VolWater
				// 	waterVolumetricFog(transparentColor, vec3(0.0), waterViewPos, texcoord, frameTimeCounter, eyeAltitude, SunMoonColor, lightDir, shadowtex0, shadowtex1, shadowcolor0, noisetex, gbufferModelViewInverse);
				// #else
					waterFog(transparentColor, vec3(0.0), waterViewPos, SunMoonColor);
				// #endif

				// #ifdef VolFog
				// 	volumetricFog(transparentColor, waterViewPos, transparentViewPos, texcoord, frameTimeCounter, SunMoonColor, shadowtex0, shadowtex1, shadowcolor0, noisetex, gbufferModelViewInverse);
				// #else
					netherFog(transparentColor, waterViewPos, transparentViewPos, skyColor);
				// #endif
			}
			else {
				// #ifdef VolWater
				// 	waterVolumetricFog(transparentColor, vec3(0.0), transparentViewPos, texcoord, frameTimeCounter, eyeAltitude, SunMoonColor, lightDir, shadowtex0, shadowtex1, shadowcolor0, noisetex, gbufferModelViewInverse);
				// #else
					waterFog(transparentColor, vec3(0.0), transparentViewPos, SunMoonColor);
				// #endif
			}
		}

		// albedo.rgb = mix(albedo.rgb, transparentColor.rgb, transparentColor.a);
		colorOut = vec4(mix(opaqueColor.rgb, transparentColor.rgb / transparentColor.a, transparentColor.a), 1.0);
	}
	else {
		colorOut = opaqueColor;
	}
}