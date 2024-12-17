#define WaterVolumetrics

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler3D worleyNoise;
uniform sampler3D perlinNoise;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

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
uniform sampler2D  depthtex0;
uniform sampler2D  depthtex1;
// uniform sampler2D shadowtex0;

uniform int isEyeInWater;
uniform int frameCounter;
uniform float eyeAltitude;
uniform float viewWidth;
uniform float viewHeight;
uniform vec3 sunDir;
uniform vec3 cameraPosition;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;


#define VolumetricClouds
#define VolumetricClouds_LowHeight 150
#define VolumetricClouds_HighHeight 450
#define VolumetricClouds_Samples 64

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
	float diffLength = length(diff);

	vec3 currentPos = samplePosHi;
	// float cloudValue = 0.0;
	vec3 transmittance = vec3(1.0);
    vec3 inScattering = vec3(0.0);
	
	for(int i = 0; i < VolumetricClouds_Samples; i++) {
		currentPos += diff;
		vec3 perlinCoords = vec3(fract(0.01*currentPos.xy), currentPos.z);
		float perlinVal = texture(perlinNoise, perlinCoords).r;

		vec3 worleyCoords = vec3(fract(0.001*currentPos.xy), currentPos.z);
		float worleyVal = texture(worleyNoise, worleyCoords).r;

		float noiseVal = 0.75*worleyVal + 0.25*perlinVal;

		float heightFactor = 1.5* (1.0 - pow(i - VolumetricClouds_Samples/2.0, 2.0) / (VolumetricClouds_Samples/2.0 * VolumetricClouds_Samples/2.0));
		float density = pow(noiseVal, 5.0) * 4.5;
		// cloudValue += 

		transmittance *= exp(-0.01 * density * diffLength);
		inScattering += 0.0002 * skyLight.skyDirect * diffLength * density;
	}

	vec3 cloudSceneColor = sceneColor * transmittance + inScattering;
	float cloudFactor = exp(-0.002*length(samplePosLo.xy - cameraPosition.xz));

	sceneColor = mix(sceneColor, cloudSceneColor, cloudFactor);

	// float cloudFactor = clamp(2*cloudValue / VolumetricClouds_Samples*(samplePosHi.z - samplePosLo.z), 0.0, 1.0);
	// cloudFactor *= exp(-0.0003*length(samplePosLo.xy - cameraPosition.xz));

	// sceneColor = mix(sceneColor, vec3(3), cloudFactor);
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

	if(solidDepth == 1.0) {

		volumetricClouds(colorOut, scenePosSolid);

		// // if(sign(150-cameraPosition.y) == sign(scenePosWater.y)) {
		// // 	// float noiseValHi = snoise(0.1*samplePosHi) * 0.5 + 0.5;
		// // 	float noiseValHi = texture(worleyNoise, fract(vec3(0.01*samplePosHi, 1.0))).r;
		// // 	colorOut = mix(colorOut, vec3(10.0), noiseValHi);	
		// // }

		// // if(sign(120-cameraPosition.y) == sign(scenePosWater.y)) {
		// // 	// float noiseValLo = snoise(0.1*samplePosLo) * 0.5 + 0.5;
		// // 	float noiseValLo = texture(worleyNoise, fract(vec3(0.01*samplePosLo, 0.0))).r;
		// // 	colorOut = mix(colorOut, vec3(10.0), noiseValLo);	
		// // }

	}

	if(isEyeInWater == 0) {
		if(mask == Mask_Water) {
			#ifdef Water_VolumetricFog
				volumetricWaterFog(colorOut, scenePosWater, scenePosSolid, eyeAltitude, sunDot, skyLight.skyDirect, skyLight.skyAmbient, randomAngle, shadowtex1);
			#else
				float fogDist = length(viewPosWater - viewPosSolid);
				simpleWaterFog(colorOut, fogDist, skyLight.skyAmbient);
			#endif
		}
	}
	else if(isEyeInWater == 1) {
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