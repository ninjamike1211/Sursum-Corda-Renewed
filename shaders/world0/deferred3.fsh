#version 420 compatibility

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
// uniform sampler2D  shadowtex0;
// uniform sampler2D  shadowtex1;
// uniform sampler2D  shadowcolor0;
// uniform sampler2D  noisetex;

// uniform mat4 gbufferModelView;
// uniform mat4 gbufferProjectionInverse;
// uniform mat4 gbufferModelViewInverse;
// uniform vec3 lightDir;
// uniform float frameTimeCounter;
// uniform bool inEnd;
// uniform bool inNether;
// uniform int heldItemId;
// uniform int heldBlockLightValue;
// uniform int heldItemId2;
// uniform int heldBlockLightValue2;
// uniform mat4  gbufferProjection;
// uniform mat4  shadowModelView;
// uniform mat4  shadowProjection;
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

// #include "/lib/defines.glsl"
// #include "/lib/material.glsl"
// #include "/lib/kernels.glsl"
// #include "/lib/noise.glsl"
// #include "/lib/functions.glsl"
// #include "/lib/TAA.glsl"
// #include "/lib/spaceConvert.glsl"
// #include "/lib/sample.glsl"
// #include "/lib/shadows.glsl"
// #include "/lib/lighting.glsl"
// #include "/lib/raytrace.glsl"


// // ------------------------ File Contents -----------------------
//     // Deferred rendering for opaque objects
//     // Vertically filters SSAO for final SSAO filtered value
//     // PCSS Shadows
//     // BRDF lighting calculations
//     // Dynamic Handlight
//     // Sub-surface Scattering


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


//     // --------------------------- Shadows --------------------------
//         float NGdotL = dot(normalGeometry, lightDir);
//         float blockerDist;

//         vec3 offset = normalToView(lightDir) * pomResults.r;
//         vec3 shadowResult = min(vec3(pomResults.g), pcssShadows(viewPos + offset, texcoord, NGdotL, blockerDist));
        
//         float shadowMult = 1.0;
//         #ifdef Shadow_LeakFix
//             // shadowResult *= smoothstep(9.0/32.0, 21.0/32.0, lmcoord.g);
//             shadowMult = texelFetch(colortex12, ivec2(0.0), 0).a;
//             shadowResult *= shadowMult;
//         #endif

//         // Contact Shadows (NOT FINISHED)
//         // vec3 coords;
//         // float jitter = texture(noisetex, texcoord * 20.0 + frameTimeCounter).r;
//         // // if(calcSSRNew(viewPos, normalize(shadowLightPosition), 0.0, coords, gbufferProjection, depthtex0, colortex1) == 1)
//         // // if(raytrace(viewPos, normalize(shadowLightPosition), 640, jitter, coords))
//         // if(shadowRaytrace(viewPos, lightDirView, 64, 1.0))
//         //     shadowResult = vec3(0.0);
//         // else
//         //     shadowResult = vec3(1.0);

//         // if (contactShadow(viewPos, normalize(shadowLightPosition), gbufferProjection, depthtex0))
//         //     shadowResult = vec3(0.0);
//         // else
//         //     shadowResult = vec3(1.0);


//     // -------------------------- Lighting --------------------------
//         vec3 playerDir = (gbufferModelViewInverse * vec4(normalize(viewVector), 0.0)).xyz;

//         colorOut.rgb = cookTorrancePBRLighting(albedo, playerDir, normal, specMap, skyDirect * shadowResult, lightDir);
//         colorOut.rgb += calcAmbient(albedo, lmcoord, skyAmbient, specMap) * SSAOOut.r;


//     // --------------------- Dynamic Hand Light ---------------------
//         #ifdef HandLight
//             vec3 viewNormal = (gbufferModelView * vec4(normal, 0.0)).xyz;

//             DynamicHandLight(colorOut.rgb, viewPos, albedo, viewNormal, specMap, isHand > 0.5);
//         #endif


//     // ------------------- Sub-surface Scattering -------------------
//         #ifdef SSS
//             float subsurface = getSubsurface(specMap);
// 			SubsurfaceScattering(colorOut.rgb, albedo, subsurface, blockerDist, skyDirect * shadowMult);
//         #endif
        
//     }
//     else {
//         colorOut.rgb = albedo;
//     }
// }