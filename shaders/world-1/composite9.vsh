#version 400 compatibility

#define ExposureSpeed 1.0

uniform sampler2D colortex0;
uniform sampler2D colortex14;
uniform sampler2D depthtex0;
uniform mat4  gbufferModelView;
uniform mat4  gbufferModelViewInverse;
uniform mat4  gbufferProjection;
uniform mat4  gbufferProjectionInverse;
uniform vec3  sunPosition;
uniform vec3  cameraPosition;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float aspectRatio;
uniform float frameTime;
uniform int   frameCounter;
uniform int   worldTime;
uniform bool  cameraMoved;

#include "/lib/defines.glsl"
#include "/lib/kernels.glsl"
#include "/lib/sample.glsl"
#include "/lib/TAA.glsl"
#include "/lib/spaceConvert.glsl"


// ------------------------ File Contents -----------------------
    // Standard fullscreen post-process vertex shader
    // Auto exposure (currently not used)
    // Calculate sprite positions and sizes for lens flare


out vec2 texcoord;
out vec3 viewVector;
flat out float exposure;


void main() {
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    viewVector = calcViewVector(texcoord);
    // vec4 ray = gbufferProjectionInverse * vec4(texcoord * 2.0 - 1.0, 0.0, 1.0);
	// viewVector = (ray.xyz / ray.w);
	// viewVector /= viewVector.z;


// ------------------------ Auto Exposure -----------------------
    vec3 avgColor = textureLod(colortex0, vec2(0.5), log2(max(viewWidth, viewHeight))).rgb;
    float exposureScreen = 0.1 / dot(avgColor, vec3(0.2125, 0.7154, 0.0721));
    // float exposureScreen = luminance(avgColor);

    float exposurePrev = texture(colortex14, vec2(0.5)).r;
    float diff = exposureScreen - exposurePrev;
    if(abs(diff) <= ExposureSpeed * frameTime)
        exposure = exposureScreen;
        // exposure = 0.5;
    else
        exposure = exposurePrev + sign(diff) * ExposureSpeed * frameTime;
        // exposure = 1.0;

    // exposure = fract(exposurePrev + frameTimeCounter);
    // exposure = exposureScreen;

    // imageStore(colorimg5, ivec2(viewWidth/2, viewHeight/2), vec4(exposure, vec3(0.0)));
}



// #version 400 compatibility

// #define ExposureSpeed 1.0

// uniform mat4 gbufferProjectionInverse;
// uniform sampler2D colortex0;
// uniform sampler2D colortex14;
// uniform float frameTime;
// uniform mat4 gbufferModelView;
// uniform bool inEnd;
// uniform bool inNether;
// uniform vec3 sunPosition;
// uniform sampler2D depthtex0;
// uniform float aspectRatio;

// uniform mat4  gbufferModelViewInverse;
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

// #include "/lib/defines.glsl"
// #include "/lib/kernels.glsl"
// #include "/lib/functions.glsl"

// out vec2 texcoord;
// out vec3 viewVector;
// flat out float exposure;

// #ifdef LensFlare
//     flat out vec2  sunScreenPos;
//     flat out vec2  flareSunCenterVec;
//     flat out float flareFade;
//     flat out mat2  flareRotMat;
//     flat out vec4  flareSprite01;
//     flat out vec4  flareSprite23;
//     flat out vec4  flareSprite45;
// #endif


// void main() {
//     gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    
//     texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

//     viewVector = calcViewVector(texcoord);
//     // vec4 ray = gbufferProjectionInverse * vec4(texcoord * 2.0 - 1.0, 0.0, 1.0);
// 	// viewVector = (ray.xyz / ray.w);
// 	// viewVector /= viewVector.z;

//     vec3 avgColor = textureLod(colortex0, vec2(0.5), log2(max(viewWidth, viewHeight))).rgb;
//     float exposureScreen = 0.1 / dot(avgColor, vec3(0.2125, 0.7154, 0.0721));
//     // float exposureScreen = luminance(avgColor);

//     float exposurePrev = texture2D(colortex14, vec2(0.5)).r;
//     float diff = exposureScreen - exposurePrev;
//     if(abs(diff) <= ExposureSpeed * frameTime)
//         exposure = exposureScreen;
//         // exposure = 0.5;
//     else
//         exposure = exposurePrev + sign(diff) * ExposureSpeed * frameTime;
//         // exposure = 1.0;

//     // exposure = fract(exposurePrev + frameTimeCounter);
//     // exposure = exposureScreen;

//     // imageStore(colorimg5, ivec2(viewWidth/2, viewHeight/2), vec4(exposure, vec3(0.0)));

//     #ifdef LensFlare
//         sunScreenPos = projectAndDivide(gbufferProjection, sunPosition).xy * 0.5 + 0.5;
//         flareSunCenterVec = vec2(0.5) - sunScreenPos;

//         // vec2 factors = smoothstep(1.0, 0.5, abs(sunScreenPos * 2.0 - 1.0));
//         // flareFade = min(factors.x, factors.y);
//         float sunOcclusion = 0.0;
//         int samples = 16;
//         for(int i = 0; i < samples; i++) {
//             vec2 sampleCoords = sunScreenPos + vec2(0.018, 0.018*aspectRatio) * GetVogelDiskSample(i, samples, 0.0);

//             if(clamp(sampleCoords, 0.0, 1.0) == sampleCoords)
//                 sunOcclusion += step(1.0, texture2D(depthtex0, sampleCoords).r);
//         }
//         flareFade = sunOcclusion/float(samples);

//         float spriteAngle = atan(-flareSunCenterVec.x, flareSunCenterVec.y);
//         flareRotMat = mat2(cos(spriteAngle), -sin(spriteAngle), sin(spriteAngle), cos(spriteAngle));

//         flareSprite01 = vec4(sunScreenPos + 0.35 * flareSunCenterVec, sunScreenPos.xy + 0.57 * flareSunCenterVec);
//         flareSprite23 = vec4(sunScreenPos + 0.59 * flareSunCenterVec, sunScreenPos.xy + 0.62 * flareSunCenterVec);
//         flareSprite45 = vec4(sunScreenPos + 0.81 * flareSunCenterVec, sunScreenPos.xy + 0.81 * flareSunCenterVec);
//     #endif
// }