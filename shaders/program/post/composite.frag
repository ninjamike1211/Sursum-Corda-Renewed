#define WaterVolumetrics

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler3D worleyNoise;
uniform sampler3D perlinNoise;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform float rainStrength;

#include "/lib/defines.glsl"
#include "/lib/functions.glsl"
#include "/lib/sample.glsl"
#include "/lib/noise.glsl"
#include "/lib/spaceConvert.glsl"
#include "/lib/shadows.glsl"
#include "/lib/water.glsl"
#include "/lib/sky.glsl"

uniform sampler2D  colortex0;
uniform sampler2D  colortex1;
uniform usampler2D colortex6;
uniform sampler2D  colortex10;
uniform sampler2D  depthtex0;
uniform sampler2D  depthtex1;
// uniform sampler2D shadowtex0;

uniform int isEyeInWater;
uniform int frameCounter;
uniform float eyeAltitude;
uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;
uniform vec3 sunDir;
uniform vec3 cameraPosition;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;


void applyFog(inout vec3 sceneColor, vec3 startPos, vec3 endPos) {
	float fogFactor = exp(-0.001*length(endPos - startPos));

	vec3 skySampleDir = normalize(vec3(endPos));
	vec2 skySamplePos = projectSphere(skySampleDir);
	skySamplePos.y = 0.4;
	vec3 fogSkyColor = texture(colortex10, skySamplePos).rgb;

	sceneColor = mix(fogSkyColor, sceneColor, fogFactor);
}

void volumetricClouds(inout vec3 sceneColor, vec3 scenePos) {
	vec3 samplePosHi = vec3(abs(VolumetricClouds_HighHeight-cameraPosition.y) * scenePos.xz / abs(scenePos.y) + cameraPosition.xz, 1.0);
	vec3 samplePosLo = vec3(abs(VolumetricClouds_LowHeight-cameraPosition.y) * scenePos.xz / abs(scenePos.y) + cameraPosition.xz, 0.0);

	float viewYSign = sign(scenePos.y);
	float hiSign    = sign(VolumetricClouds_HighHeight-cameraPosition.y);
	float loSign    = sign(VolumetricClouds_LowHeight-cameraPosition.y);

	if(hiSign == loSign) {
		if(hiSign != viewYSign)
			return;
	}
	else {
		float cameraCloudHeight = (cameraPosition.y - VolumetricClouds_LowHeight) / (VolumetricClouds_HighHeight - VolumetricClouds_LowHeight);
		if (viewYSign == 1.0)
			samplePosLo = vec3(cameraPosition.xz, cameraCloudHeight);
		else
			samplePosHi = vec3(cameraPosition.xz, cameraCloudHeight);
	}

	vec3 diff = -(samplePosHi - samplePosLo) / VolumetricClouds_Samples;
	float diffLength = min(length(diff), 1000.0);

	vec3 currentPos = samplePosHi;
	// float cloudValue = 0.0;
	vec3 transmittance = vec3(1.0);
    vec3 inScattering = vec3(0.0);
	
	for(int i = 0; i < VolumetricClouds_Samples; i++) {
		currentPos += diff;
		vec3 perlinCoords = vec3(fract(0.003*currentPos.xy - 0.07*frameTimeCounter), currentPos.z);
		float perlinVal = texture(perlinNoise, perlinCoords).r;

		vec3 worleyCoords = vec3(fract(0.001*currentPos.xy + 0.03*frameTimeCounter), currentPos.z);
		float worleyVal = texture(worleyNoise, worleyCoords).r;

		float noiseVal = 0.8*worleyVal + 0.2*perlinVal;

		float heightFactor = 1.5* (1.0 - pow(i - VolumetricClouds_Samples/2.0, 2.0) / (VolumetricClouds_Samples/2.0 * VolumetricClouds_Samples/2.0));
		float density = pow(noiseVal, mix(8.0, 3.0, rainStrength)) * mix(40.5, 40.5, rainStrength);
		// cloudValue += 

		transmittance *= exp(-0.01 * density * diffLength);
		inScattering += 0.0002 * skyLight.skyDirect * diffLength * density;
	}

	// applyFog(inScattering, vec3(0.0), scenePos);

	vec3 cloudSceneColor = sceneColor * transmittance + inScattering;
	float cloudFactor = exp(-0.0003*length(samplePosHi.xy - cameraPosition.xz));
	// float cloudFactor = 1.0;

	sceneColor = mix(sceneColor, cloudSceneColor, cloudFactor);

	// float cloudFactor = clamp(2*cloudValue / VolumetricClouds_Samples*(samplePosHi.z - samplePosLo.z), 0.0, 1.0);
	// cloudFactor *= exp(-0.0003*length(samplePosLo.xy - cameraPosition.xz));

	// sceneColor = mix(sceneColor, vec3(3), cloudFactor);
}

void volumetricFog(inout vec3 sceneColor, vec3 startPos, vec3 endPos, float bias) {
	int sampleCount = 32;
    
    vec3  diff = -(endPos - startPos) / sampleCount;
    vec3  rayPos = endPos + bias*diff;

	vec3 shadowAccum = vec3(0.0);

	for(int i = 0; i < sampleCount; i++) {
        rayPos += diff;

		vec3 shadowPos = calcShadowPosScene(rayPos);
        distortShadowPos(shadowPos);
        // float shadowVal = step(shadowPos.z, texture(shadowSampler, shadowPos.xy).x);
        vec3 shadowVal = shadowVisibility(shadowPos);
		shadowAccum += shadowVal;
	}

	shadowAccum /= sampleCount;

	applyFog(sceneColor, startPos, endPos);
	sceneColor += shadowAccum * skyLight.skyDirect * 0.03;
}

varying vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec3 colorOut;


void main() {
	uint mask = texture(colortex6, texcoord).r;

	colorOut = texture2D(colortex0, texcoord).rgb;
	vec4 transparentColor = texture2D(colortex1, texcoord);

	float waterDepth = texture(depthtex0, texcoord).r;
	float solidDepth = texture(depthtex1, texcoord).r;

	vec3 viewPosWater = screenToView(texcoord, waterDepth, frameCounter, vec2(viewWidth, viewHeight), gbufferProjectionInverse);
	vec3 viewPosSolid = screenToView(texcoord, solidDepth, frameCounter, vec2(viewWidth, viewHeight), gbufferProjectionInverse);

	vec3 scenePosWater = (gbufferModelViewInverse * vec4(viewPosWater, 1.0)).xyz;
	vec3 scenePosSolid = (gbufferModelViewInverse * vec4(viewPosSolid, 1.0)).xyz;

	float randomAngle = interleaved_gradient(ivec2(gl_FragCoord.xy), frameCounter) * TAU;
	// randomAngle = 0.0;

	float sunDot = dot(sunDir, vec3(0.0, 1.0, 0.0));

	#ifdef VolumetricClouds
		if(solidDepth == 1.0) {
			volumetricClouds(colorOut, scenePosSolid);
		}
	#endif

	if(isEyeInWater == 0) {
		if(mask == Mask_Water) {
			#ifdef Water_VolumetricFog
				volumetricWaterFog(colorOut, scenePosWater, scenePosSolid, eyeAltitude, sunDot, skyLight.skyDirect, skyLight.skyAmbient, randomAngle, shadowtex1);
			#else
				float fogDist = length(viewPosWater - viewPosSolid);
				simpleWaterFog(colorOut, fogDist, skyLight.skyAmbient);
			#endif
		}

		if(solidDepth != 1.0) {
			#ifdef VolumetricFog
				volumetricFog(colorOut, vec3(0.0), scenePosSolid, 0.0);
			#else
				applyFog(colorOut, vec3(0.0), scenePosSolid);
			#endif
		}
	}
	else if(isEyeInWater == 1) {
		if(solidDepth != 1.0) {
			#ifdef VolumetricFog
				volumetricFog(colorOut, scenePosWater, scenePosSolid, 0.0);
			#else
				applyFog(colorOut, scenePosWater, scenePosSolid);
			#endif
		}

		vec3 farPos = scenePosSolid;

		if(waterDepth < 1.0 && mask == Mask_Water)
			farPos = scenePosWater;

		#ifdef Water_VolumetricFog
			volumetricWaterFog(colorOut, vec3(0.0), farPos, eyeAltitude, sunDot, skyLight.skyDirect, skyLight.skyAmbient, randomAngle, shadowtex1);
		#else
			float fogDist = length(farPos);
			simpleWaterFog(colorOut, fogDist, skyLight.skyAmbient);
		#endif


		// volumetricWaterFog(transparentColor.rgb, vec3(0.0), viewPosWater, skyLight.skyDirect, skyLight.skyAmbient, shadowtex1);
	}

	if(transparentColor.a > EPS) {
		colorOut = mix(colorOut, transparentColor.rgb / transparentColor.a, transparentColor.a), 1.0;
	}
}