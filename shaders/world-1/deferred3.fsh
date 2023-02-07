#version 420 compatibility

#define inNether

#include "/lib/deferred_fragment.glsl"

// uniform sampler2D  colortex1;
// uniform usampler2D colortex2;
// uniform sampler2D  colortex3;
// uniform sampler2D  colortex4;
// uniform sampler2D  colortex8;
// uniform sampler2D  colortex9;
// uniform sampler2D  colortex12;
// uniform sampler2D  depthtex0;
// uniform sampler2D  depthtex1;
// uniform sampler2D  noisetex;

// uniform mat4 gbufferModelView;
// uniform mat4 gbufferProjectionInverse;
// uniform mat4 gbufferModelViewInverse;
// uniform float frameTimeCounter;
// uniform bool inEnd;
// uniform bool inNether;
// uniform int heldItemId;
// uniform int heldBlockLightValue;
// uniform int heldItemId2;
// uniform int heldBlockLightValue2;
// uniform mat4  gbufferProjection;
// uniform vec3  cameraPosition;
// uniform float rainStrength;
// uniform float near;
// uniform float far;
// uniform float viewWidth;
// uniform float viewHeight;
// uniform int   frameCounter;
// uniform int   worldTime;
// uniform bool  cameraMoved;
// uniform float eyeAltitude;
// uniform float fogDensityMult;

// const int noiseTextureResolution = 512;

// flat in vec3 lightDir;

// #include "/lib/defines.glsl"
// #include "/lib/material.glsl"
// #include "/lib/kernels.glsl"
// #include "/lib/noise.glsl"
// #include "/lib/functions.glsl"
// #include "/lib/TAA.glsl"
// #include "/lib/spaceConvert.glsl"
// #include "/lib/sample.glsl"
// #include "/lib/lighting.glsl"
// #include "/lib/raytrace.glsl"


// // ------------------------ File Contents -----------------------
//     // Deferred rendering for opaque objects
//     // Vertically filters SSAO for final SSAO filtered value
//     // BRDF lighting calculations
//     // Dynamic Handlight


// in vec2 texcoord;
// in vec3 viewVector;
// flat in vec3 skyAmbient;
// flat in vec3 skyDirect;

// /* RENDERTARGETS: 7,9 */
// layout(location = 0) out vec4 colorOut;
// layout(location = 1) out vec4 SSAOOut;

// void main() {

//     // Read depth and albedo values
//     float depth = texture(depthtex0, texcoord).r;
//     vec3 albedo = texture(colortex1, texcoord).rgb;
//     albedo = sRGBToLinear3(albedo);
//     colorOut.a = 1.0;


// // ---------------------- Opaque Rendering ----------------------
//     if(depth < 1.0) {
//         // Reading texture value and calculate position
//         uvec3 material = texture(colortex2, texcoord).rgb;
//         vec3 lmcoordRaw = texture(colortex3, texcoord).rgb;
//         vec3 pomResults = texture(colortex8, texcoord).rgb;

//         vec3 normal 	    = NormalDecode(material.x);
// 	    vec3 normalGeometry = NormalDecode(material.y);
//         vec4 specMap        = SpecularDecode(material.z);
//         vec3 viewPos        = calcViewPos(viewVector, depth);
//         vec2 lmcoord        = lmcoordRaw.rg;
//         float isHand        = lmcoordRaw.b;
//         float emissiveness  = specMap.a > 254.5/255.0 ? 0.0 : specMap.a * EmissiveStrength;


//     // ---------------------------- SSAO ----------------------------
//         #ifdef SSAO
//             if(isHand < 0.5) {
//                 vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight);
//                 vec3 occlusion = vec3(0.0);

//                 for(int i = 0; i < 5; i++) {
//                     vec2 offset = vec2(0.0, (i-2)) * texelSize;

//                     occlusion += 0.2 * texture(colortex9, texcoord + offset).rgb;
//                 }

//                 SSAOOut = vec4(occlusion, 1.0);
//             }
//             else {
//                 SSAOOut = vec4(1.0);
//             }
//         #else
//             SSAOOut = vec4(1.0);
//         #endif


//     // -------------------------- Lighting --------------------------
//         vec3 playerDir = (gbufferModelViewInverse * vec4(normalize(viewVector), 0.0)).xyz;
//         float NGdotL = dot(normalGeometry, lightDir);

//         colorOut.rgb = cookTorrancePBRLighting(albedo.rgb, playerDir, normal, specMap, skyDirect * pomResults.g, lightDir);
//         colorOut.rgb += calcAmbient(albedo.rgb, lmcoord, skyAmbient, specMap) * SSAOOut.r;


//     // --------------------- Dynamic Hand Light ---------------------
//         #ifdef HandLight
//             vec3 viewNormal = (gbufferModelView * vec4(normal, 0.0)).xyz;

//             DynamicHandLight(colorOut.rgb, viewPos, albedo.rgb, viewNormal, specMap, isHand > 0.5);
//         #endif

//     }
//     else {
//         colorOut.rgb = albedo;
//     }
// }