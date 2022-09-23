#version 420 compatibility

uniform float wetness;
uniform float rainStrength;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D colortex0;
uniform usampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex10;
uniform sampler2D colortex13;
uniform sampler2D colortex15;
uniform sampler2D noisetex;
uniform vec3 sunDir;
uniform vec3 sunDirView;
uniform vec3 sunPosition;
uniform vec3 fogColor;
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
uniform float aspectRatio;

uniform mat4  gbufferProjection;
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

#include "/defines.glsl"
#include "/kernels.glsl"
#include "/noise.glsl"
#include "/functions.glsl"
#include "/lighting.glsl"
#include "/sky2.glsl"
#include "/raytrace.glsl"
#include "/clouds.glsl"

in vec2 texcoord;
in vec3 viewVector;
flat in vec3 SunMoonColor;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 colorOut;
// layout(location = 1) out vec4 testOut; 12

void main() {
    colorOut = texture2D(colortex0, texcoord);
    vec4 specMap = texture2D(colortex4, texcoord);

    // albedo = linearToSRGB(albedo);

    // if(depth != 1.0)
        // albedo.rgb = mix(albedo.rgb, SunMoonColor /* * vec3(0.7, 0.75, 0.9) */, clamp(-1.0 + exp(length(viewPos) * 0.0007), 0.0, 1.0));

    if(specMap.r > 0.45) {
        // Read buffers
        uint normalRaw   = texture2D(colortex1, texcoord).x;
        vec4 albedo      = texture2D(colortex2, texcoord);
        vec2 lmcoord     = texture2D(colortex3, texcoord).rg;
        float waterDepth = texture2D(colortex5, texcoord).r;
        float depth      = texture2D(depthtex0, texcoord).r;

        // Calculate basic values
        vec3 normal     = NormalDecode(normalRaw);
        vec3 normalView = normalToView(normal);
        vec3 viewPos    = calcViewPos(viewVector, depth);
        vec3 rayDir     = reflect(normalize(viewPos), normalView);
        vec3 eyePos     = mat3(gbufferModelViewInverse) * viewPos;

        vec3 fresnel    = calcFresnel(max(dot(normalView, normalize(-viewPos)), 0.0), specMap, albedo.rgb);

        // Read sky value from buffer
        vec3 eyeDir     = mat3(gbufferModelViewInverse) * (-reflect(normalize(-viewPos), normalView));
        vec3 skyColor   = texture2D(colortex10, projectSphere(eyeDir) * AS_RENDER_SCALE).rgb;
        
        // Apply clouds
        #ifdef cloudsEnable
            applyNetherCloudColor(eyeDir, vec3(1.0, 1.0, -1.0) * eyePos + vec3(0.0, eyeAltitude, 0.0), skyColor, fogColor);
        #endif

        // Darken sky reflecion if underwater
        if(isEyeInWater == 1)
            skyColor *= vec3(0.1, 0.3, 0.4);
        
        // Screen Space reflections
        #ifdef SSR
            float jitter = texture2D(noisetex, texcoord * 20.0 + frameTimeCounter).r;
            jitter = 1.0;

            vec3 rayPos = vec3(-1.0);
            bool rayHit = raytrace(viewPos, rayDir, 64, jitter, rayPos, depthtex1);

            vec3 reflectColor;
            if(rayHit) {
                reflectColor = texture2D(colortex0, rayPos.xy).rgb;
                // reflectColor = vec3(rayPos.xy, 0.0);

                // testOut.rgb = vec3(rayPos.xyz);
            }
            else {
                reflectColor = skyColor;
                // reflectColor = vec3(0.0);
            }

        #else
            vec3 reflectColor = skyColor;
        #endif

        // Apply reflection to object, slightly different process for water
        if(abs(waterDepth - depth) < 0.01)
            colorOut.rgb = mix(colorOut.rgb, reflectColor * smoothstep(0.45, 0.8, specMap.r), fresnel);
        else
            colorOut.rgb += fresnel * reflectColor * smoothstep(0.45, 0.8, specMap.r);
    }
}