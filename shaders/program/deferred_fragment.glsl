#include "/lib/defines.glsl"

uniform sampler2D  colortex1;
uniform usampler2D colortex2;
uniform sampler2D  colortex3;
uniform sampler2D  colortex8;
uniform sampler2D  depthtex0;
uniform sampler2D  depthtex1;

#ifdef SSAO
    uniform sampler2D  colortex9;
#endif

uniform mat4  gbufferModelView;
uniform mat4  gbufferModelViewInverse;
uniform mat4  gbufferProjection;
uniform float viewWidth;
uniform float viewHeight;
uniform int   frameCounter;

#ifdef HandLight
    uniform int heldItemId;
    uniform int heldBlockLightValue;
    uniform int heldItemId2;
    uniform int heldBlockLightValue2;
#endif

#if defined SSS && !defined inNether
    uniform float near;
    uniform float far;
#endif

#ifdef LightningLight
    uniform vec4 lightningBoltPosition;
#endif

const int noiseTextureResolution = 512;

#ifndef inNether
    #ifdef Use_ShadowMap
        uniform sampler2D  shadowtex0;
        uniform sampler2D  shadowtex1;
        uniform sampler2D  shadowcolor0;
        uniform mat4  shadowModelView;
        uniform mat4  shadowProjection;
    #endif

    uniform vec3 lightDir;
#else
    flat in vec3 lightDir;
#endif

#define lightingRendering

#include "/lib/SSBO.glsl"
#include "/lib/material.glsl"
#include "/lib/kernels.glsl"
#include "/lib/noise.glsl"
#include "/lib/functions.glsl"
#include "/lib/TAA.glsl"
#include "/lib/spaceConvert.glsl"
#include "/lib/sample.glsl"

#if !defined inNether && defined Use_ShadowMap
    #include "/lib/shadows.glsl"
#endif

#include "/lib/lighting.glsl"
#include "/lib/raytrace.glsl"


// ------------------------ File Contents -----------------------
    // Deferred rendering for opaque objects
    // Vertically filters SSAO for final SSAO filtered value
    // PCSS Shadows
    // BRDF lighting calculations
    // Dynamic Handlight
    // Sub-surface Scattering


in vec2 texcoord;
in vec3 viewVector;
flat in vec3 skyAmbient;
flat in vec3 skyDirect;


/* RENDERTARGETS: 7,9 */
layout(location = 0) out vec4 colorOut;
layout(location = 1) out vec4 SSAOOut;

void main() {

    // Read depth and albedo values
    float depth = texture(depthtex0, texcoord).r;
    vec3 albedo = texture(colortex1, texcoord).rgb;
    albedo = sRGBToLinear3(albedo);
    colorOut.a = 1.0;


// ---------------------- Opaque Rendering ----------------------
    if(depth < 1.0) {
        // Reading texture value and calculate position
        uvec3 material = texture(colortex2, texcoord).rgb;
        vec3 lmcoordRaw = texture(colortex3, texcoord).rgb;
        vec3 pomResults = texture(colortex8, texcoord).rgb;
	    
        vec3 normal 	    = NormalDecode(material.x);
	    vec3 normalGeometry = NormalDecode(material.y);
        vec4 specMap        = SpecularDecode(material.z);
        vec3 viewPos        = calcViewPos(viewVector, depth, gbufferProjection);
        vec2 lmcoord        = lmcoordRaw.rg;
        float isHand        = lmcoordRaw.b;
        float emissiveness  = specMap.a > 254.5/255.0 ? 0.0 : specMap.a * EmissiveStrength;

        // #ifdef LightningLight
            vec3 scenePos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
        // #endif


    // ---------------------------- SSAO ----------------------------
        #ifdef SSAO
            if(isHand < 0.5) {
                vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight);
                vec3 occlusion = vec3(0.0);

                for(int i = 0; i < 5; i++) {
                    vec2 offset = vec2(0.0, (i-2)) * texelSize;

                    occlusion += 0.2 * texture(colortex9, texcoord + offset).rgb;
                }

                SSAOOut = vec4(occlusion, 1.0);
            }
            else {
                SSAOOut = vec4(1.0);
            }
        #else
            SSAOOut = vec4(1.0);
        #endif


    // --------------------------- Shadows --------------------------
        float NGdotL = dot(normalGeometry, lightDir);

        #if !defined inNether && defined Use_ShadowMap
            float blockerDist;

            vec3 offset = lightDir * pomResults.r;
            vec3 shadowResult = min(vec3(pomResults.g), pcssShadows(scenePos + offset, texcoord, NGdotL, normalGeometry, blockerDist, vec2(viewWidth, viewHeight), frameCounter));
            
            float shadowMult = 1.0;
            #if defined Shadow_LeakFix && !defined inEnd
                // shadowResult *= smoothstep(9.0/32.0, 21.0/32.0, lmcoord.g);
                // shadowMult = texelFetch(colortex12, ivec2(0.0), 0).a;
                // shadowResult *= shadowMult;
                shadowResult *= ssbo.caveShadowMult;
            #endif

            // Contact Shadows (NOT FINISHED)
            // vec3 coords;
            // float jitter = texture(noisetex, texcoord * 20.0 + frameTimeCounter).r;
            // // if(calcSSRNew(viewPos, normalize(shadowLightPosition), 0.0, coords, gbufferProjection, depthtex0, colortex1) == 1)
            // // if(raytrace(viewPos, normalize(shadowLightPosition), 640, jitter, coords))
            // if(shadowRaytrace(viewPos, lightDirView, 64, 1.0))
            //     shadowResult = vec3(0.0);
            // else
            //     shadowResult = vec3(1.0);

            // if (contactShadow(viewPos, normalize(shadowLightPosition), gbufferProjection, depthtex0))
            //     shadowResult = vec3(0.0);
            // else
            //     shadowResult = vec3(1.0);
        #else
            vec3 shadowResult = vec3(pomResults.g);
        #endif

    // -------------------------- Lighting --------------------------
        vec3 sceneDir = (gbufferModelViewInverse * vec4(normalize(viewVector), 0.0)).xyz;
        // vec3 sceneDir = normalize(scenePos);

        colorOut.rgb = cookTorrancePBRLighting(albedo, sceneDir, normal, specMap, skyDirect * shadowResult, lightDir);
        
        colorOut.rgb += calcAmbient(albedo, lmcoord, skyAmbient, specMap) * SSAOOut.r;

        // ----------------- Lightmap PBR lighting ------------------
            // vec4 lightmapDirRaw = texture(colortex4, texcoord);
            // vec3 blockLightDir  = unpackNormalVec2(lightmapDirRaw.xy);
            // vec3 skyLightDir    = unpackNormalVec2(lightmapDirRaw.zw);

            // blockLightDir = normalize(mix(blockLightDir, normalGeometry, 0.5));
            // skyLightDir   = normalize(mix(skyLightDir,   normalGeometry, 0.5));

            // lmcoord = pow(lmcoord, vec2(2.0));

            // vec3 torchAmbient = 0.2 * mix(vec3(0.0), 1.5*vec3(15.0, 7.2, 2.9), lmcoord.x) /* * (1.2 - skyAmbient) */;
            // vec3 skyAmbient   = 0.2 * mix(vec3(0.06), 4 * skyAmbient, lmcoord.y);

            // colorOut.rgb += cookTorrancePBRLighting(albedo, sceneDir, normal, specMap, torchAmbient, blockLightDir);
            // colorOut.rgb += cookTorrancePBRLighting(albedo, sceneDir, normal, specMap, skyAmbient, skyLightDir);
        
            // float NdotLLightmap  = dot(skyLightDir, normal);
            // float NGdotLLightmap = dot(skyLightDir, normalGeometry);
            
            // lmcoord.g += DirectionalLightmap_Strength * (NdotLLightmap - NGdotLLightmap) * lmcoord.g;


    // --------------------- Dynamic Hand Light ---------------------
        vec3 viewNormal = (gbufferModelView * vec4(normal, 0.0)).xyz;
    
        #ifdef HandLight
            DynamicHandLight(colorOut.rgb, viewPos, albedo, viewNormal, specMap, isHand > 0.5, frameCounter, vec2(viewWidth, viewHeight), depthtex1, gbufferProjection, heldItemId, heldBlockLightValue, heldItemId2, heldBlockLightValue2);
        #endif

        #ifdef LightningLight
            DynamicLightningLight(colorOut.rgb, lightningBoltPosition, scenePos, albedo, normal, specMap, frameCounter, vec2(viewWidth, viewHeight), depthtex1, gbufferModelView, gbufferProjection);
        #endif


    // ------------------- Sub-surface Scattering -------------------
        #if defined SSS && !defined inNether && defined Use_ShadowMap
            float subsurface = getSubsurface(specMap);
			SubsurfaceScattering(colorOut.rgb, albedo, subsurface, blockerDist, skyDirect * shadowMult, near, far);
        #endif
        
    }
    else {
        colorOut.rgb = albedo;
    }
}