uniform sampler2D  colortex0;
uniform sampler2D  colortex1;
uniform usampler2D colortex2;
uniform sampler2D  colortex3;
uniform sampler2D  colortex4;
uniform sampler2D  colortex5;
uniform sampler2D  colortex10;
uniform sampler2D  depthtex0;
uniform sampler2D  depthtex1;
uniform sampler2D  noisetex;

uniform mat4  gbufferModelView;
uniform mat4  gbufferModelViewInverse;
uniform mat4  gbufferProjection;
uniform mat4  gbufferProjectionInverse;
uniform mat4  shadowProjection;
uniform vec3  cameraPosition;
uniform vec3  lightDir;
uniform vec3  sunDir;
uniform vec3  fogColor;
uniform float eyeAltitude;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float sunHeight;
uniform float shadowHeight;
uniform float fogDensityMult;
uniform float heldBlockLightValue;
uniform float heldBlockLightValue2;
uniform int   heldItemId;
uniform int   heldItemId2;
uniform int   moonPhase;
uniform int   isEyeInWater;
uniform int   frameCounter;
uniform int   worldTime;
uniform bool  cameraMoved;

#include "/lib/defines.glsl"
#include "/lib/material.glsl"
#include "/lib/kernels.glsl"
#include "/lib/noise.glsl"
#include "/lib/functions.glsl"
#include "/lib/TAA.glsl"
#include "/lib/spaceConvert.glsl"
#include "/lib/lighting.glsl"
#include "/lib/sky2.glsl"
#include "/lib/raytrace.glsl"
#include "/lib/clouds.glsl"


// ------------------------ File Contents -----------------------
    // Reflections, reflections, reflections


in vec2 texcoord;
in vec3 viewVector;
flat in vec3 skyDirect;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 colorOut;

void main() {
    float depth    = texture(depthtex0, texcoord).r;
          colorOut = texture(colortex0, texcoord);
    uvec2 material = texture(colortex2, texcoord).rb;

    vec4 specMap = SpecularDecode(material.y);
    float roughness = getRoughness(specMap);


// ------------------------- Reflections ------------------------
    if(depth < 1.0 && roughness < SSR_HighThreshold) {
    
    // ---------------- Reading values and setup ----------------
        // Read buffers
        vec3 albedo      = texture(colortex1, texcoord).rgb;
        vec2 lmcoord     = texture(colortex3, texcoord).rg;
        float waterDepth = texture(colortex5, texcoord).r;

        // Calculate basic values
        vec3 normal     = NormalDecode(material.x);
        vec3 normalView = normalToView(normal, gbufferModelView);
        vec3 viewPos    = calcViewPos(viewVector, depth, gbufferProjection);
        vec3 scenePos   = mat3(gbufferModelViewInverse) * viewPos;

        vec3 fresnel    = calcFresnel(max(dot(normalView, normalize(-viewPos)), 0.0), specMap, albedo);


    // ------------- Fallback Sky color and Clouds --------------
        // Read sky value from buffer
        float jitter = interleaved_gradient(ivec2(texcoord * vec2(viewWidth, viewHeight)), frameCounter);
        float roughReflectionAmount = smoothstep(SSR_LowRoughThreshold, SSR_HighRoughThreshold, roughness);
        
        if(roughReflectionAmount > 0.0) {
            vec2  offset = blue_noise_disk[int(jitter * 63.99)] * 0.07 * roughReflectionAmount;
            mat3  tbn    = tbnNormal(normalView);
            normalView   = normalize(normalView + tbn * vec3(offset, 0.0));
        }
        
        vec3 rayDir = reflect(normalize(viewPos), normalView);
        vec3 eyeDir = mat3(gbufferModelViewInverse) * rayDir;

        vec3 skyColor   = texture(colortex10, projectSphere(eyeDir) * AS_RENDER_SCALE).rgb;
        

        // Apply clouds
        #ifdef cloudsEnable
            #ifdef inNether
                applyNetherCloudColor(eyeDir, vec3(1.0, 1.0, -1.0) * scenePos + cameraPosition, skyColor, fogColor, far, lightDir);
            #elif defined inEnd
                applyEndCloudColor(eyeDir, vec3(1.0, 1.0, -1.0) * scenePos + vec3(0.0, eyeAltitude, 0.0), skyColor, -skyDirect, far, lightDir);
            #else
                applyCloudColor(eyeDir, vec3(1.0, 1.0, -1.0) * scenePos + cameraPosition, skyColor, skyDirect, far, lightDir);
            #endif
        #endif

        #ifdef inEnd
            skyColor = abs(skyColor * 5.0);
        #endif

        // Darken sky reflecion if underwater
        #ifdef dimHasWater
            if(isEyeInWater == 1)
                skyColor *= vec3(0.1, 0.3, 0.4);
        #endif

        // Fade out sky reflection in dark enviroments
        #if defined inOverworld && defined Shadow_LeakFix
            skyColor *= smoothstep(9.0/32.0, 21.0/32.0, lmcoord.g) * 0.9 + 0.1;
        #endif
    

    // ---------------- Screen Space Reflections ----------------
        #ifdef SSR
            // jitter to reduce banding
            
            jitter = 1.0;

            // do the raytracing
            vec3 rayPos = vec3(-1.0);
            bool rayHit = raytrace(viewPos, rayDir, 64, jitter, frameCounter, vec2(viewWidth, viewHeight), rayPos, depthtex1, gbufferProjection);

            // Apply raytraced reflection only if it hit
            vec3 reflectColor;
            if(rayHit) {
                reflectColor = texture(colortex0, rayPos.xy).rgb;

                float reflectionFade = min2(smoothstep(1.0, 0.97, abs(rayPos.xy * 2.0 - 1.0)));
                if(reflectionFade < 1.0)
                    reflectColor = mix(skyColor, reflectColor, reflectionFade);
            }
            else {
                reflectColor = skyColor;
            }

        #else
            vec3 reflectColor = skyColor;
        #endif

        reflectColor *= smoothstep(SSR_HighThreshold, SSR_LowThreshold, roughness);


    // -------------------- Apply Reflection --------------------

        #ifdef inNether
            fresnel *= netherFogFactor(vec3(0.0), viewPos);
        #else
            if(isEyeInWater == 1)
                fresnel *= waterFogFactor(vec3(0.0), viewPos);
        #endif


        if(abs(waterDepth - depth) < 0.01)
            colorOut.rgb = mix(colorOut.rgb, reflectColor, fresnel);
        else
            colorOut.rgb += fresnel * reflectColor;
    }
}