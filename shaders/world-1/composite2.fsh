#version 420 compatibility

uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform sampler2D colortex6;
uniform sampler2D colortex15;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

uniform mat4  gbufferModelView;
uniform mat4  gbufferModelViewInverse;
uniform mat4  gbufferProjection;
uniform mat4  gbufferProjectionInverse;
uniform vec3  cameraPosition;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform int   frameCounter;
uniform bool  cameraMoved;
// uniform bool  isRiding;

#define taaFragment

#include "/lib/defines.glsl"
#include "/lib/kernels.glsl"
#include "/lib/TAA.glsl"
#include "/lib/spaceConvert.glsl"


// ------------------------ File Contents -----------------------
    // Apply Temporal Anti-aliasing


in vec2 texcoord;
flat in float centerDepthLinear;

/* RENDERTARGETS: 0,9,15 */
layout(location = 0) out vec4 colorOut;
layout(location = 1) out float CoC;
layout(location = 2) out vec4 historyOut;

void main() {
	colorOut = texture(colortex0, texcoord);


// ----------------------------- TAA ----------------------------
	#ifdef TAA
		applyTAA(colorOut, historyOut, texcoord, colortex0, colortex15, colortex6);
	#endif


// ----------------------------- DOF ----------------------------
	#ifdef DOF
	// if(!isRiding) {
		// float currentDist = unpackCoC(texture(colortex14, texcoord).r);
		float isHand = texture(colortex3, texcoord).b;
		float depth = linearizeDepthFast(texture(depthtex1, texcoord).r);
		// float blockerDist = 0.0;
		// float count = 0.0;

		// for(int i = 0; i < DOF_Blocker_Samples; i++) {
		//     vec2 samplePos = texcoord + DOF_Factor * GetVogelDiskSample(i, DOF_Blocker_Samples, 0.0) * vec2(1.0, aspectRatio);
		//     float dist = (texture(colortex14, samplePos).r * 2.0 - 1.0) * DOF_Factor;

		//     if(currentDist - dist > -0.01) {
		//         blockerDist += abs(dist-currentDist);
		//         count++;
		//     }
		// }
		// float cof = blockerDist / count;
		// float CoC = currentDist;
		// float CoC = DOF_Factor / far * abs(depth - centerDepthLinear);
		float focalLength = 1.0 / (1.0 / centerDepthLinear + 1.0 / DOF_ImageDistance);
		// float CoC = abs(DOF_FocalLength / (centerDepthLinear - DOF_FocalLength) * (1.0 - (centerDepthLinear / depth)));
		CoC = -(focalLength * (centerDepthLinear - depth)) / (depth * (centerDepthLinear - focalLength));
		// CoC = min(abs(CoC), 0.05);
		// cof = 0.003;

		if(isHand > 0.9)
		#ifdef DOF_HandBlur
			CoC = min(0.0, CoC*0.5 + 0.032);
		#else
			CoC = 0.0;
		#endif

		#ifndef DOF_NearBlur
		else
			CoC = max(0.0, CoC);
		#endif

		CoC = clamp(CoC, -DOF_MaxRadius, DOF_MaxRadius);
		CoC = CoC / DOF_MaxRadius * 0.5 + 0.5;

	// }
	#endif
}