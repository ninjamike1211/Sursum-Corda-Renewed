#version 430 compatibility

#include "/lib/defines.glsl"
#include "/lib/functions.glsl"
#include "/lib/material.glsl"
#include "/lib/spaceConvert.glsl"
#include "/lib/sample.glsl"
#include "/lib/noise.glsl"
#include "/lib/raytrace.glsl"
#include "/lib/sky.glsl"
#include "/lib/DOF.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform usampler2D colortex6;
uniform sampler2D colortex10;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform vec3 sunPosition;
uniform float sunAngle;
uniform float viewWidth;
uniform float viewHeight;
uniform float centerDepthSmooth;
uniform float near;
uniform float far;
uniform int frameCounter;

in vec2 texcoord;
in vec3 viewVector;

layout(std430, binding = 0) buffer Histogram {
    uint HistogramGlobal[256];
    float averageLum;
};

vec3 getSkyReflection(vec3 reflectDir, vec2 texcoord) {
	float skyLightmap = texture(colortex5, texcoord).g;
	vec3 sceneReflectDir = mat3(gbufferModelViewInverse) * reflectDir;
	vec2 skySamplePos = projectSphere(sceneReflectDir);
	vec3 reflectColor = texture(colortex10, skySamplePos).rgb;
	reflectColor *= linstep(0.0, 0.5, skyLightmap);
	return reflectColor;
}

void binSearch(inout vec3 screenPos, vec3 rayStep, sampler2D depthtex, int stepCount) {
    for(int i = 0; i < stepCount; i++) {
        float depthDiff = texture(depthtex, screenPos.xy).r - screenPos.z;
        screenPos += sign(depthDiff) * rayStep;
        rayStep *= 0.5;
    }
}

bool ssr(vec3 screenPos, vec3 viewPos, vec3 viewRayDir, int stepCount, int binStepCount, float jitter, out vec3 hitPos, int frameCounter, vec2 screenSize, float near, float far, sampler2D depthtex, mat4 projectionMatrix) {
	if (viewRayDir.z > 0.0 && viewRayDir.z >= -viewPos.z)
        return false;
	
	vec3 screenRayDir = (projectAndDivide(projectionMatrix, viewPos + viewRayDir) * 0.5 + 0.5) - screenPos;
	// vec3 rayStep = 10.0 * screenRayDir / stepCount;
	vec3 rayStep = screenRayDir * min3((sign(screenRayDir) - screenPos) / screenRayDir) * 0.9999 / (stepCount);

	screenPos += rayStep * jitter;

	for(int i = 0; i < stepCount; i++) {
		screenPos += rayStep;
		float depth = texture(depthtex, screenPos.xy).r;

		if(clamp(screenPos, 0.0, 1.0) != screenPos) {
			return false;
		}
		else if(screenPos.z - depth > -0.00001) {
			hitPos = screenPos;
			binSearch(hitPos, rayStep, depthtex, binStepCount);
			return true;
		}
	}
	
	return false;
}


/* RENDERTARGETS: 0,12 */
layout(location = 0) out vec3 colorOut;
layout(location = 1) out float cocOut;

void main() {

	float depth = texture(depthtex0, texcoord).r;
	uint mask = texture(colortex6, texcoord).r;
	colorOut = texture(colortex0, texcoord).rgb;

	// Hand depth fix
	if((mask & Mask_Hand) != 0) {
		depth = convertHandDepth(depth);
	}

	#if Reflections > 0
	if(depth < 1.0) {
		vec3 albedo = texture(colortex2, texcoord).rgb;
		vec4 rawNormal = texture(colortex3, texcoord);
		vec4 specular = texture(colortex4, texcoord);

		vec3 viewPos = calcViewPos(viewVector, depth, gbufferProjection);
		vec3 viewDir = normalize(viewPos);
		vec3 normal = mat3(gbufferModelView) * unpackNormalVec2(rawNormal.xy);

		vec3 fresnel = calcFresnel(max(dot(normal, normalize(-viewPos)), 0.0), specular, albedo);

		float randomAngle = interleaved_gradient(ivec2(gl_FragCoord.xy), frameCounter);

		#ifdef Reflections_Rough
			float roughReflectionAmount = getRoughness(specular);
            
            if(roughReflectionAmount > 0.0) {
                vec2 offset = blue_noise_disk[int(randomAngle * 63.99)] * 0.1 * roughReflectionAmount;
                mat3 tbn    = tbnNormal(normal);
                normal      = normalize(normal + tbn * vec3(offset, 0.0));
            }
		#endif

		vec3 reflectDir = reflect(viewDir, normal);
		vec3 hitPos;
		vec3 reflectColor = vec3(0.0);

		#if Reflections == 2
			bool hit = ssr(vec3(texcoord, depth), viewPos, reflectDir, 32, 4, randomAngle, hitPos, frameCounter, vec2(viewWidth, viewHeight), near, far, depthtex0, gbufferProjection);
			if(hit) {
				reflectColor = texture(colortex0, hitPos.xy).rgb;
			}
			else 
		#endif
			reflectColor = getSkyReflection(reflectDir, texcoord);


		colorOut.rgb += fresnel * specular.r * reflectColor;
	}
	#endif

	#ifdef DOF
		float depthLinear = linearizeDepthFast(depth, near, far);
		float centerDepthLinear = linearizeDepthFast(centerDepthSmooth, near, far);

		cocOut = getCoCFromDepth(depthLinear, centerDepthLinear);
	#endif
}