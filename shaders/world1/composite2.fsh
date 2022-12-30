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

	#ifdef DOF
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
	#endif
}



// #version 420 compatibility

// uniform sampler2D colortex0;
// uniform sampler2D colortex6;
// uniform sampler2D colortex15;

// #include "/lib/defines.glsl"

// /*
//     AABB Clipping from "Temporal Reprojection Anti-Aliasing in INSIDE"
//     http://s3.amazonaws.com/arena-attachments/655504/c5c71c5507f0f8bf344252958254fb7d.pdf?1468341463
// */

// vec3 YCoCg2RGB(vec3 YCoCg) {
// 	YCoCg.gb -= 0.5;
// 	return mat3(1.0, 1.0, -1.0, 1.0, 0.0, 1.0, 1.0, -1.0, -1.0) * YCoCg;
// }

// vec3 RGB2YCoCg(vec3 rgb) {
// 	return mat3(0.25, 0.5, 0.25, 0.5, 0.0, -0.5, -0.25, 0.5, -0.25) * rgb + vec3(0.0, 0.5, 0.5);
// }

// vec3 clipAABB(vec3 prevColor, vec3 minColor, vec3 maxColor) {
//     vec3 pClip = 0.5 * (maxColor + minColor); // Center
//     vec3 eClip = 0.5 * (maxColor - minColor); // Size

//     vec3 vClip  = prevColor - pClip;
//     vec3 aUnit  = abs(vClip / eClip);
//     float denom = max(aUnit.x, max(aUnit.y, aUnit.z));

//     return denom > 1.0 ? pClip + vClip / denom : prevColor;
// }

// vec3 neighbourhoodClipping(sampler2D currTex, vec3 prevColor) {
//     vec3 minColor = vec3(1e5), maxColor = vec3(-1e5);

//     for(int x = -TAA_NEIGHBORHOOD_SIZE; x <= TAA_NEIGHBORHOOD_SIZE; x++) {
//         for(int y = -TAA_NEIGHBORHOOD_SIZE; y <= TAA_NEIGHBORHOOD_SIZE; y++) {
//             vec3 color = texelFetch(currTex, ivec2(gl_FragCoord.xy) + ivec2(x, y), 0).rgb;
//             minColor = min(minColor, color); maxColor = max(maxColor, color); 
//         }
//     }
//     return clipAABB(prevColor, minColor, maxColor);
// }

// in vec2 texcoord;

// /* RENDERTARGETS: 0,15 */
// layout(location = 0) out vec4 albedo;
// layout(location = 1) out vec4 historyOut;

// void main() {
// 	albedo = texture2D(colortex0, texcoord);

// 	#ifdef TAA
// 		vec2 velocity = texture2D(colortex6, texcoord).xy;
// 		vec4 history = texture2D(colortex15, texcoord - velocity);

// 		// vec2 pixel = 1.0 / vec2(viewWidth, viewHeight);
// 		// vec3 nearColor0 = texture2D(colortex0, texcoord + vec2(pixel.x, 0.0)).rgb;
// 		// vec3 nearColor1 = texture2D(colortex0, texcoord + vec2(0.0, pixel.y)).rgb;
// 		// vec3 nearColor2 = texture2D(colortex0, texcoord - vec2(pixel.x, 0.0)).rgb;
// 		// vec3 nearColor3 = texture2D(colortex0, texcoord - vec2(0.0, pixel.y)).rgb;

// 		// vec3 boxMin = min(albedo.rgb, min(nearColor0, min(nearColor1, min(nearColor2, nearColor3))));
// 		// vec3 boxMax = max(albedo.rgb, max(nearColor0, max(nearColor1, max(nearColor2, nearColor3))));

// 		// history.rgb = clamp(history.rgb, boxMin.rgb, boxMax);

// 		history.rgb = neighbourhoodClipping(colortex0, history.rgb);

// 		if(clamp(texcoord - velocity, 0.0, 1.0) == texcoord - velocity) {
// 			// albedo.rgb = mix(albedo.rgb, history, 0.9);
// 			// albedo.rgb = mix(albedo.rgb, history, frameCount / (frameCount + 1));

// 			float currentFrame = (history.a == 0) ? 1.0 : (1.0 / (1.0/history.a - 1.0) + 1.0);
// 			float currentBlend = currentFrame / (currentFrame+1.0);

// 			albedo.rgb = mix(albedo.rgb, history.rgb, currentBlend);
// 			historyOut.a = currentBlend;
// 		}
// 		else {
// 			historyOut.a = 0.0;
// 		}
// 		// if(clamp(history.rgb, boxMin.rgb, boxMax) != history.rgb) {
// 		// 	historyOut.a = 0.0;
// 		// }


// 		// albedo.rgb = neighbourhoodClipping(colortex0, history);

// 		// albedo.rgb = vec3(frameCount != 0);

// 		// frameCountOut = frameCount + 1;
// 		historyOut.rgb = albedo.rgb;
// 	#endif
// }