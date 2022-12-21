#version 400 compatibility

uniform usampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex8;
uniform sampler2D colortex9;
uniform sampler2D colortex12;
uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D noisetex;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 lightDir;
// uniform vec3 lightDirView;
uniform float frameTimeCounter;
uniform sampler2D depthtex1;
uniform bool inEnd;
uniform bool inNether;
uniform int heldItemId;
uniform int heldBlockLightValue;
uniform int heldItemId2;
uniform int heldBlockLightValue2;
// uniform int frameCounter;

uniform mat4  gbufferProjection;
uniform mat4  shadowModelView;
uniform mat4  shadowProjection;
uniform vec3  cameraPosition;
uniform float rainStrength;
// uniform float wetness;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform int   frameCounter;
uniform int   worldTime;
uniform bool  cameraMoved;
uniform float eyeAltitude;
uniform float fogDensityMult;

#include "/lib/defines.glsl"
#include "/lib/material.glsl"
#include "/lib/kernels.glsl"
#include "/lib/noise.glsl"
#include "/lib/functions.glsl"
#include "/lib/TAA.glsl"
#include "/lib/spaceConvert.glsl"
#include "/lib/sample.glsl"
#include "/lib/shadows.glsl"
#include "/lib/lighting.glsl"
#include "/lib/raytrace.glsl"

in vec2 texcoord;
in vec3 viewVector;
flat in vec3 skyAmbient;
flat in vec3 skyDirect;

const int noiseTextureResolution = 512;

/* RENDERTARGETS: 7,9 */
layout(location = 0) out vec4 colorOut;
layout(location = 1) out vec4 SSAOOut;
// layout(location = 2) out vec4 testOut; // buffer 12

void main() {
    // Read depth value
    float depth = texture(depthtex0, texcoord).r;
    vec4 albedo = texture(colortex2, texcoord);
    albedo.rgb = sRGBToLinear(albedo).rgb;

    colorOut.a = 1.0;

    // Opaque rendering if there is an obect there to render
    if(depth < 1.0) {
        // Reading texture value and calculate position
        uvec2 normalRaw = texture(colortex1, texcoord).rg;
        vec3 lmcoordRaw = texture(colortex3, texcoord).rgb;
        vec4 specMap = texture(colortex4, texcoord);
        vec3 pomResults = texture(colortex8, texcoord).rgb;

        vec3 normal 	= NormalDecode(normalRaw.x);
	    vec3 normalGeometry = NormalDecode(normalRaw.y);
        vec3 viewPos = calcViewPos(viewVector, depth);
        vec3 worldPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz + cameraPosition;
        vec2 lmcoord = lmcoordRaw.rg;
        float isHand = lmcoordRaw.b;
        float emissiveness = specMap.a > 254.5/255.0 ? 0.0 : specMap.a * EmissiveStrength;

        // Prepare lighting and shadows
        float NGdotL = dot(normalGeometry, lightDir);
        float blockerDist;

        vec3 offset = normalToView(lightDir) * pomResults.r;
        vec3 shadowResult = min(vec3(pomResults.g), pcssShadows(viewPos + offset, texcoord, NGdotL, blockerDist));
        
        // SSAO
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
        // #ifdef SSAO
        //     SSAOOut = vec4(mix(calcSSAO(normalToView(normalGeometry), viewPos, texcoord, viewWidth, viewHeight, depthtex0, colortex2, noisetex, gbufferProjectionInverse), vec3(1.0), emissiveness), 1.0);
        // #endif

        // vec4 playerPos = gbufferModelViewInverse * vec4(viewPos, 1.0);
        // vec3 shadowPos = (shadowProjection * (shadowModelView * playerPos)).xyz; //convert to shadow screen space
        // float distortFactor = getDistortFactor(shadowPos.xy);
        // shadowPos.xyz = distort(shadowPos.xyz, distortFactor); //apply shadow distortion
        // shadowPos.xyz = shadowPos.xyz * 0.5 + 0.5; //convert from -1 ~ +1 to 0 ~ 1

        // blockerDist = shadowPos.z - texture(shadowtex0, shadowPos.xy).r;

        float shadowMult = 1.0;
        #ifdef Shadow_LeakFix
            // shadowResult *= smoothstep(9.0/32.0, 21.0/32.0, lmcoord.g);
            shadowMult = texture(colortex12, vec2(0.0)).a;
            shadowResult *= shadowMult;
        #endif

        vec3 playerDir = (gbufferModelViewInverse * vec4(normalize(viewVector), 0.0)).xyz;

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

        // Perform lighting calcualtions
        colorOut.rgb = cookTorrancePBRLighting(albedo.rgb, playerDir, normal, specMap, skyDirect * shadowResult, lightDir);
        colorOut.rgb += calcAmbient(albedo.rgb, lmcoord, skyAmbient, specMap) * SSAOOut.r;

    // -------------- Dynamic Hand Light --------------
        #ifdef HandLight
            vec3 viewNormal = (gbufferModelView * vec4(normal, 0.0)).xyz;

            DynamicHandLight(colorOut.rgb, viewPos, albedo.rgb, viewNormal, specMap, isHand > 0.5);

        //     if(heldBlockLightValue > 0) {
        //         vec3 lightPos = vec3(0.2, -0.1, 0.0);
        //         vec3 lightDir = (gbufferModelViewInverse * vec4(normalize(lightPos - viewPos), 0.0)).xyz;
        //         float dist = length(viewPos - lightPos);
                
        //         vec3 lightColor = vec3(float(heldBlockLightValue) / (7.5 * dist * dist));

        //         #ifdef HandLight_Colors
        //             if(heldItemId == 10001)
        //                 lightColor *= vec3(0.2, 3.0, 10.0);
        //             else if(heldItemId == 10002)
        //                 lightColor *= vec3(10.0, 1.5, 0.0);
        //             else if(heldItemId == 10003)
        //                 lightColor *= vec3(15.0, 4.0, 1.5);
        //             else if(heldItemId == 10004)
        //                 lightColor *= vec3(3.0, 6.0, 15.0);
        //             else if(heldItemId == 10005)
        //                 lightColor *= vec3(1.5, 1.0, 10.0);
        //             else if(heldItemId == 10006)
        //                 lightColor *= vec3(4.0, 1.0, 10.0);
        //             else
        //         #endif
        //             lightColor *= vec3(15.0, 7.2, 2.9);

        //         if(isHand > 0.9 && texcoord.x > 0.5) {
        //             // if(emissiveness < 0.1)
        //                 colorOut.rgb += 0.005 * lightColor * albedo.rgb;
        //         }
        //         else {
        //             #ifdef HandLight_Shadows
        //                 float jitter = texture(noisetex, texcoord * 20.0 + frameTimeCounter).r;
        //                 lightColor *= ssShadows(viewPos, lightPos, jitter, depthtex0);
        //             #endif

        //             colorOut.rgb += cookTorrancePBRLighting(albedo.rgb, playerDir, normal, specMap, lightColor, lightDir);
        //         }
        //     }
        //     if(heldBlockLightValue2 > 0) {
        //         vec3 lightPos = vec3(-0.2, -0.1, 0.0);
        //         vec3 lightDir = (gbufferModelViewInverse * vec4(normalize(lightPos - viewPos), 0.0)).xyz;
        //         float dist = length(viewPos - lightPos);
                
        //         vec3 lightColor = vec3(float(heldBlockLightValue2) / (7.5 * dist * dist));

        //         #ifdef HandLight_Colors
        //             if(heldItemId2 == 10001)
        //                 lightColor *= vec3(0.2, 3.0, 10.0);
        //             else if(heldItemId2 == 10002)
        //                 lightColor *= vec3(10.0, 1.5, 0.0);
        //             else if(heldItemId2 == 10003)
        //                 lightColor *= vec3(15.0, 4.0, 1.5);
        //             else if(heldItemId2 == 10004)
        //                 lightColor *= vec3(3.0, 6.0, 15.0);
        //             else if(heldItemId2 == 10005)
        //                 lightColor *= vec3(1.5, 1.0, 10.0);
        //             else if(heldItemId2 == 10006)
        //                 lightColor *= vec3(4.0, 1.0, 10.0);
        //             else
        //         #endif
        //             lightColor *= vec3(15.0, 7.2, 2.9);

        //         if(isHand > 0.9 && texcoord.x < 0.5) {
        //             // if(emissiveness < 0.1)
        //                 colorOut.rgb += 0.005 * lightColor * albedo.rgb;
        //         }
        //         else {
        //             #ifdef HandLight_Shadows
        //                 float jitter = texture(noisetex, texcoord * 20.0 + frameTimeCounter).r;
        //                 lightColor *= ssShadows(viewPos, lightPos, jitter, depthtex0);
        //             #endif

        //             colorOut.rgb += cookTorrancePBRLighting(albedo.rgb, playerDir, normal, specMap, lightColor, lightDir);
        //         }
        //     }
        #endif


        #ifdef SSS
            float subsurface = extractSubsurface(specMap);
			SubsurfaceScattering(colorOut.rgb, albedo.rgb, subsurface, blockerDist, skyDirect * shadowMult);
            // float subsurface = specMap.b > 64.5/255.0 ? (specMap.b - 65.0/255.0) * 255.0/190.0 : 0.0;

            // if(subsurface > 0.0 ) {
            //     // vec3 shadowPos = calcShadowPos(viewPos, gbufferModelViewInverse);
            //     // float shadowMapDepth = texture(shadowtex0, shadowPos.xy).r;
            //     float diff = blockerDist * (far-near) - near;

            //     #ifdef Shadow_LeakFix
			// 		subsurface *= smoothstep(9.0/32.0, 21.0/32.0, lmcoord.g);
			// 	#endif

            //     colorOut.rgb += albedo.rgb * exp(min(-diff * 2.5 / subsurface, 0.0)) * 0.2 * subsurface * skyDirect;
            // }
        #endif

        // if(wetness > 0.0 && normalGeometry.y > 0.99 && pomResults.b > 0.01) {
        //     colorOut.rgb *= 0.1;
        // }
    }
    else {
        colorOut.rgb = albedo.rgb;
    }
}