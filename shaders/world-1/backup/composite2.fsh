#version 420 compatibility

uniform float wetness;
uniform float rainStrength;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D colortex0;
uniform usampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex10;
uniform sampler2D colortex15;
uniform sampler2D noisetex;
uniform vec3 sunDir;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform float eyeAltitude;
uniform float frameTimeCounter;
uniform int isEyeInWater;
uniform vec3 cameraPosition;
uniform mat4 gbufferModelView;
uniform vec3 lightDir;
uniform bool inEnd;
uniform bool inNether;

#include "/functions.glsl"
#include "/sky2.glsl"
#include "/lighting.glsl"
#include "/raytrace.glsl"
#include "/noise.glsl"
#include "/clouds.glsl"

uniform vec3 fogColor;

in vec2 texcoord;
in vec3 viewVector;
flat in vec3 SunMoonColor;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 colorOut;
// layout(location = 1) out vec4 testOut;

void main() {
    colorOut = texture2D(colortex0, texcoord);
    vec4 albedo = texture2D(colortex2, texcoord);
    float depth = texture2D(depthtex0, texcoord).r;
    float waterDepth = texture2D(colortex5, texcoord).r;
    vec4 specMap = texture2D(colortex4, texcoord);

    // albedo = linearToSRGB(albedo);

    // if(depth != 1.0)
        // albedo.rgb = mix(albedo.rgb, SunMoonColor /* * vec3(0.7, 0.75, 0.9) */, clamp(-1.0 + exp(length(viewPos) * 0.0007), 0.0, 1.0));

    if(specMap.r > 0.45) {
        vec3 normal = NormalDecode(texture2D(colortex1, texcoord).x);
        vec3 normalView = normalToView(normal);
        vec3 viewPos = calcViewPos(viewVector, depth);
        vec4 f0 = calcF0(specMap, albedo.rgb);
        vec3 fresnel = fresnelSchlick(dot(normalView, normalize(-viewPos)), f0.rgb);

        // float jitter = texture2D(noisetex, texcoord * 20.0 + frameTimeCounter).r;
        // jitter = 0.0;
        // vec2 reflectCoords = calcSSRNew(texcoord, depth, viewPos, normal, jitter, sunPosition, eyeAltitude, depthtex0, gbufferProjection, gbufferModelViewInverse);
        // vec3 reflectColor;
        // if(clamp(reflectCoords, 0.0, 1.0) == reflectCoords)
        //     reflectColor = texture2D(colortex0, reflectCoords).rgb;
        // else {
        //     vec3 eyeDir = mat3(gbufferModelViewInverse) * (-reflect(normalize(-viewPos), normal));
        //     reflectColor = texture2D(colortex10, projectSphere(eyeDir) * AS_RENDER_SCALE).rgb;
        // }

        vec3 rayDir = reflect(normalize(viewPos), normalView);
        vec3 eyePos = mat3(gbufferModelViewInverse) * viewPos;
        vec3 eyeDir = mat3(gbufferModelViewInverse) * (-reflect(normalize(-viewPos), normalView));
        vec3 skyColor = texture2D(colortex10, projectSphere(eyeDir) * AS_RENDER_SCALE).rgb;
        
        #ifdef cloudsEnable
            applyNetherCloudColor(eyeDir, vec3(1.0, 1.0, -1.0) * eyePos + vec3(0.0, eyeAltitude, 0.0), skyColor, fogColor);
        #endif

        if(isEyeInWater == 1)
            skyColor *= vec3(0.1, 0.3, 0.4);
        
        #ifdef SSR
            float jitter = texture2D(noisetex, texcoord * 20.0 + frameTimeCounter).r;
            jitter = 1.0;

            // testOut = vec4(eyePos + vec3(0.0, eyeAltitude, 0.0), 1.0);

            // vec3 reflectCoords;
            // float reflectResult = calcSSRNew(viewPos, rayDir, jitter, reflectCoords, gbufferProjection, depthtex0, colortex1);
            // vec3 reflectColor = texture2D(colortex0, reflectCoords.xy).rgb;
            // reflectColor = mix(skyColor, reflectColor, reflectResult);

            vec3 rayPos = vec3(-1.0);
            bool rayHit = raytrace(viewPos, rayDir, 64, jitter, rayPos);

            vec3 reflectColor;
            if(rayHit) {
                reflectColor = texture2D(colortex0, rayPos.xy).rgb;
                // reflectColor = vec3(rayPos.xy, 0.0);
            }
            else {
                reflectColor = skyColor;
                // reflectColor = vec3(0.0);
            }

        #else
            vec3 reflectColor = skyColor;
        #endif

        if(abs(waterDepth - depth) < 0.01)
            colorOut.rgb = mix(colorOut.rgb, reflectColor * smoothstep(0.45, 0.8, specMap.r), fresnel);
        else
            colorOut.rgb += fresnel * reflectColor * smoothstep(0.45, 0.8, specMap.r);

        // albedo.rgb = reflectColor;

        // albedo.rgb = fresnel;
        // albedo.rgb = calcSSRSues(viewPos, normal, sunPosition, eyeAltitude, depthtex0, colortex0, gbufferModelViewInverse, gbufferProjection, gbufferProjectionInverse);

        
    }
}