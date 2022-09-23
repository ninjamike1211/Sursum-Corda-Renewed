#version 400 compatibility

uniform usampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex8;
uniform sampler2D colortex12;
uniform sampler2D depthtex0;
uniform sampler2D noisetex;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
// uniform vec3 lightDir;
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
uniform vec3  cameraPosition;
uniform float rainStrength;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform int   frameCounter;
uniform int   worldTime;
uniform bool  cameraMoved;
uniform float eyeAltitude;
uniform float fogDensityMult;

#include "/defines.glsl"
#include "/kernels.glsl"
#include "/noise.glsl"
#include "/functions.glsl"
#include "/lighting.glsl"
#include "/raytrace.glsl"

in vec2 texcoord;
in vec3 viewVector;
flat in vec3 skyAmbient;
flat in vec3 skyDirect;
flat in vec3 lightDir;
// flat in vec3 lightDirView;

const int noiseTextureResolution = 512;

/* RENDERTARGETS: 7,9 */
layout(location = 0) out vec4 colorOut;
layout(location = 1) out vec4 SSAOOut;
// layout(location = 2) out vec4 testOut; // buffer 12

void main() {
    // Read depth value
    float depth = texture2D(depthtex0, texcoord).r;
    vec4 albedo = texture2D(colortex2, texcoord);
    albedo.rgb = sRGBToLinear(albedo).rgb;

    colorOut.a = 1.0;

    // Opaque rendering if there is an obect there to render
    if(depth < 1.0) {
        // Reading texture value and calculate position
        uvec2 normalRaw = texture2D(colortex1, texcoord).rg;
        vec3 lmcoordRaw = texture2D(colortex3, texcoord).rgb;
        vec4 specMap = texture2D(colortex4, texcoord);
        vec2 pomResults = texture2D(colortex8, texcoord).rg;

        vec3 normal 	= NormalDecode(normalRaw.x);
	    vec3 normalGeometry = NormalDecode(normalRaw.y);
        vec3 viewPos = calcViewPos(viewVector, depth);
        vec2 lmcoord = lmcoordRaw.rg;
        float isHand = lmcoordRaw.b;
        float emissiveness = specMap.a > 254.5/255.0 ? 0.0 : specMap.a * EmissiveStrength;

        // Prepare lighting and shadows
        float NGdotL = dot(normalGeometry, lightDir);

        vec3 shadowResult = vec3(pomResults.g);

        vec3 playerDir = (gbufferModelViewInverse * vec4(normalize(viewVector), 0.0)).xyz;

        // Perform lighting calcualtions
        colorOut.rgb = cookTorrancePBRLighting(albedo.rgb, playerDir, normal, specMap, skyDirect * shadowResult, lightDir);
        colorOut.rgb += calcAmbient(albedo.rgb, lmcoord, skyAmbient, specMap);

    // -------------- Dynamic Hand Light --------------
        #ifdef HandLight
            if(heldBlockLightValue > 0) {
                vec3 lightPos = vec3(0.2, -0.1, 0.0);
                vec3 lightDir = (gbufferModelViewInverse * vec4(normalize(lightPos - viewPos), 0.0)).xyz;
                float dist = length(viewPos - lightPos);
                
                vec3 lightColor = vec3(float(heldBlockLightValue) / (7.5 * dist * dist));

                #ifdef HandLight_Colors
                    if(heldItemId == 10001)
                        lightColor *= vec3(0.2, 3.0, 10.0);
                    else if(heldItemId == 10002)
                        lightColor *= vec3(10.0, 1.5, 0.0);
                    else if(heldItemId == 10003)
                        lightColor *= vec3(15.0, 4.0, 1.5);
                    else if(heldItemId == 10004)
                        lightColor *= vec3(3.0, 6.0, 15.0);
                    else if(heldItemId == 10005)
                        lightColor *= vec3(1.5, 1.0, 10.0);
                    else if(heldItemId == 10006)
                        lightColor *= vec3(4.0, 1.0, 10.0);
                    else
                #endif
                    lightColor *= vec3(15.0, 7.2, 2.9);

                if(isHand > 0.9 && texcoord.x > 0.5) {
                    // if(emissiveness < 0.1)
                        colorOut.rgb += 0.005 * lightColor * albedo.rgb;
                }
                else {
                    #ifdef HandLight_Shadows
                        float jitter = texture2D(noisetex, texcoord * 20.0 + frameTimeCounter).r;
                        lightColor *= ssShadows(viewPos, lightPos, jitter, depthtex0);
                    #endif

                    colorOut.rgb += cookTorrancePBRLighting(albedo.rgb, playerDir, normal, specMap, lightColor, lightDir);
                }
            }
            if(heldBlockLightValue2 > 0) {
                vec3 lightPos = vec3(-0.2, -0.1, 0.0);
                vec3 lightDir = (gbufferModelViewInverse * vec4(normalize(lightPos - viewPos), 0.0)).xyz;
                float dist = length(viewPos - lightPos);
                
                vec3 lightColor = vec3(float(heldBlockLightValue2) / (7.5 * dist * dist));

                #ifdef HandLight_Colors
                    if(heldItemId2 == 10001)
                        lightColor *= vec3(0.2, 3.0, 10.0);
                    else if(heldItemId2 == 10002)
                        lightColor *= vec3(10.0, 1.5, 0.0);
                    else if(heldItemId2 == 10003)
                        lightColor *= vec3(15.0, 4.0, 1.5);
                    else if(heldItemId2 == 10004)
                        lightColor *= vec3(3.0, 6.0, 15.0);
                    else if(heldItemId2 == 10005)
                        lightColor *= vec3(1.5, 1.0, 10.0);
                    else if(heldItemId2 == 10006)
                        lightColor *= vec3(4.0, 1.0, 10.0);
                    else
                #endif
                    lightColor *= vec3(15.0, 7.2, 2.9);

                if(isHand > 0.9 && texcoord.x < 0.5) {
                    // if(emissiveness < 0.1)
                        colorOut.rgb += 0.005 * lightColor * albedo.rgb;
                }
                else {
                    #ifdef HandLight_Shadows
                        float jitter = texture2D(noisetex, texcoord * 20.0 + frameTimeCounter).r;
                        lightColor *= ssShadows(viewPos, lightPos, jitter, depthtex0);
                    #endif

                    colorOut.rgb += cookTorrancePBRLighting(albedo.rgb, playerDir, normal, specMap, lightColor, lightDir);
                }
            }
        #endif

        // SSAO
        #ifdef SSAO
            SSAOOut = vec4(mix(calcSSAO(normalToView(normalGeometry), viewPos, texcoord, depthtex0, noisetex), vec3(1.0), emissiveness), 1.0);
        #endif
    }
    else {
        colorOut.rgb = albedo.rgb;
    }
}