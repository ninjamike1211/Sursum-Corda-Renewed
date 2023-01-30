#version 400 compatibility

uniform sampler2D  colortex0;
uniform usampler2D colortex2;
uniform sampler2D  colortex4;
uniform sampler2D  colortex6;
uniform sampler2D  colortex7;
uniform sampler2D  colortex10;
uniform sampler2D  depthtex0;
uniform sampler2D  depthtex1;

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

#define inNether

#include "/lib/defines.glsl"
#include "/lib/material.glsl"
#include "/lib/kernels.glsl"
#include "/lib/noise.glsl"
#include "/lib/functions.glsl"
#include "/lib/TAA.glsl"
#include "/lib/spaceConvert.glsl"
#include "/lib/sample.glsl"
#include "/lib/sky2.glsl"
#include "/lib/lighting.glsl"
#include "/lib/clouds.glsl"
#include "/lib/raytrace.glsl"

// #define waterRefraction


// ------------------------ File Contents -----------------------
    // Main Composite pass, combining opaque and transparent geometry
	// Read texture values and calculate various positions
	// Apply atmospheric fog to opaque objects
	// Apply sky, sun/moon, and atmospheric fog to sky
	// Apply atmospheric fog to transparent objects
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


void main() {

// --------------------- Read texture values --------------------
	vec4 transparentColor 	= texture(colortex0, texcoord);
	uvec3 material 			= texture(colortex2, texcoord).rgb;
	velocityOut 			= texture(colortex6, texcoord);
	vec4 opaqueColor 		= texture(colortex7, texcoord);
	float transparentDepth 	= texture(depthtex0, texcoord).r;
	float depth 			= texture(depthtex1, texcoord).r;

	vec3 transparentViewPos = calcViewPos(viewVector, transparentDepth);
	vec3 viewPos 			= calcViewPos(viewVector, depth);
	vec3 scenePos 			= (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	vec3 eyeDir             = mat3(gbufferModelViewInverse) * normalize(viewPos);

	vec4 specMap = SpecularDecode(material.z);
	
	materialOut = material;


// ----------------------- Opaque Objects -----------------------
	if(depth < 1.0) {

	// ---------------- Water and Atmospheric Fog ---------------
		// fog when player is not underwater
		if(isEyeInWater == 0) {
			vec3 fogCloudColor = fogColor;
			
			#ifdef Nether_CloudFog
				applyNetherCloudColor(eyeDir, vec3(50, 10, 50) * cameraPosition, fogCloudColor, fogColor);
			#endif
			
			netherFog(opaqueColor, vec3(0.0), viewPos, fogCloudColor);
		}
	}


// ------------------------ Sky Rendering -----------------------
	else {
		// Read sky value from buffer
		vec3 sky = texture2D(colortex10, projectSphere(eyeDir) * AS_RENDER_SCALE).rgb;

		// Apply moon, hide moon when below horizon
		opaqueColor.rgb = sky;

		// Apply clouds
		#ifdef cloudsEnable
			applyNetherCloudColor(eyeDir, vec3(50, 10, 50) * cameraPosition, opaqueColor.rgb, fogColor);
		#endif

		// Output correct velocity for the sky
		#if defined TAA || defined MotionBlur
			if(transparentDepth == 1.0) {
				vec2 prevScreenPos = toPrevScreenPos(texcoord);
				velocityOut.xy = texcoord - prevScreenPos;
			}
		#endif
	}


// ----------- Transparent Objects and Alpha Blending -----------
	if(transparentColor.a > 0.0 && transparentDepth < 1.0) {
		
	// ---------------- Water and Atmospheric Fog ---------------
		if(isEyeInWater == 0) {
			vec3 fogCloudColor = fogColor;

			#ifdef Nether_CloudFog
				applyNetherCloudColor(eyeDir, vec3(50, 10, 50) * cameraPosition, fogCloudColor, fogColor);
			#endif

			netherFog(transparentColor, vec3(0.0), transparentViewPos, fogCloudColor);
		}


	// --------------------- Alpha Blending ---------------------
		colorOut = vec4(mix(opaqueColor.rgb, transparentColor.rgb / transparentColor.a, transparentColor.a), 1.0);
	}
	else {
		colorOut = opaqueColor;
	}
}