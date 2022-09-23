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
uniform sampler2D noisetex;
uniform vec3 lightDir;
uniform vec3 sunDir;
uniform vec3 fogColor;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform float frameTimeCounter;
uniform float eyeAltitude;
uniform int isEyeInWater;
uniform float rainStrength;
uniform bool inEnd;
uniform bool inNether;

uniform mat4  gbufferProjection;
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

#include "/defines.glsl"
#include "/kernels.glsl"
#include "/noise.glsl"
#include "/functions.glsl"
#include "/sky2.glsl"
#include "/lighting.glsl"
#include "/clouds.glsl"
#include "/raytrace.glsl"

in vec2 texcoord;
in vec3 viewVector;
flat in vec3 skyAmbient;
flat in vec3 skyDirect;

const int noiseTextureResolution = 512;

/* RENDERTARGETS: 0,6 */
layout(location = 0) out vec4 colorOut;
layout(location = 1) out vec4 velocityOut;
// layout(location = 1) out vec4 SSAOOut;


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
    return toPrevScreenPos(currScreenPos, texture2D(depthtex0, currScreenPos.xy).x);
}


void main() {
	// Read buffers and basic position/normal calculations
	vec4 transparentColor 	= texture2D(colortex0, texcoord);
	uvec2 normalRaw 		= texture2D(colortex1, texcoord).rg;
	vec4 specMap 			= texture2D(colortex4, texcoord);
	velocityOut 			= texture2D(colortex6, texcoord);
	vec4 opaqueColor 		= texture2D(colortex7, texcoord);
	float transparentDepth 	= texture2D(depthtex0, texcoord).r;
	float depth 			= texture2D(depthtex1, texcoord).r;

	vec3 transparentViewPos = calcViewPos(viewVector, transparentDepth);
	vec3 viewPos 			= calcViewPos(viewVector, depth);

	vec3 normalTex 	= NormalDecode(normalRaw.x);
	vec3 normalGeom = NormalDecode(normalRaw.y);

	// Opaque objects
	if(depth < 1.0) {

		// Apply SSAO
		#ifdef SSAO
			vec3 occlusion = texture2D(colortex9, texcoord).rgb;
			opaqueColor.rgb *= occlusion;
		#endif

		// opaque water and atmospheric fog
		// fog when player is not underwater
		if(isEyeInWater == 0) {
			// if there is water in the current pixel, render both water and atmospheric fog
			netherFog(opaqueColor, vec3(0.0), viewPos, fogColor);
			// fog(opaqueColor, vec3(0.0), viewPos, skyDirect);
		}
	}

	// Sky rendering
	else {
		// Read sky value from buffer
		vec3 eyeDir = mat3(gbufferModelViewInverse) * normalize(viewPos);
		vec3 sky = texture2D(colortex10, projectSphere(eyeDir) * AS_RENDER_SCALE).rgb;

		// Apply moon, hide moon when below horizon
		opaqueColor.rgb = sky;

		// Apply clouds
		#ifdef cloudsEnable
			applyNetherCloudColor(eyeDir, vec3(0.0, eyeAltitude, 0.0), opaqueColor.rgb, fogColor);
		#endif

		// Output correct velocity for the sky
		#if defined TAA || defined MotionBlur
			if(transparentDepth == 1.0) {
				vec2 prevScreenPos = toPrevScreenPos(texcoord);
				velocityOut.xy = texcoord - prevScreenPos;
			}
		#endif
	}

	// Transparent objects and blending
	if(transparentColor.a > 0.0 && transparentDepth < 1.0) {
		// transparent water and atmospheric fog
		// fog when player is not underwater
		if(isEyeInWater == 0) {
			netherFog(transparentColor, vec3(0.0), transparentViewPos, fogColor);
			// fog(transparentColor, vec3(0.0), transparentViewPos, skyDirect);
		}

		// Blending transparent and opaque into single output
		colorOut = vec4(mix(opaqueColor.rgb, transparentColor.rgb / transparentColor.a, transparentColor.a), 1.0);
	}
	else {
		colorOut = opaqueColor;
	}
}