#version 420 compatibility

uniform mat4  gbufferModelView;
uniform mat4  gbufferModelViewInverse;
uniform mat4  gbufferProjection;
uniform mat4  gbufferProjectionInverse;
uniform vec3  cameraPosition;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float sunHeight;
uniform float shadowHeight;
uniform int   frameCounter;
uniform int   moonPhase;
uniform bool  cameraMoved;

#include "/lib/defines.glsl"
#include "/lib/kernels.glsl"
#include "/lib/TAA.glsl"
#include "/lib/spaceConvert.glsl"


// ------------------------ File Contents -----------------------
    // Standard fullscreen post-process vertex shader
    // Calculates view vector for cheap view position
    // Calculates direct sky light colors


out vec2 texcoord;
out vec3 viewVector;

void main() {
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    viewVector = calcViewVector(texcoord, frameCounter, vec2(viewWidth, viewHeight), gbufferProjectionInverse);
}



// #version 420 compatibility

// #define ExposureSpeed 1000

// uniform mat4 gbufferProjectionInverse;
// uniform mat4 gbufferModelView;
// uniform float rainStrength;
// uniform bool inEnd;
// uniform bool inNether;
// uniform vec3 lightDir;
// uniform float sunAngle;
// uniform float shadowAngle;
// uniform float sunHeight;
// uniform float shadowHeight;
// uniform int moonPhase;

// uniform mat4  gbufferModelViewInverse;
// uniform mat4  gbufferProjection;
// uniform vec3  cameraPosition;
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
// #include "/lib/sky2.glsl"

// out vec2 texcoord;
// out vec3 viewVector;
// flat out vec3 SunMoonColor;

// void main() {
//     gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    
//     texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

//     viewVector = calcViewVector(texcoord);
//     // vec4 ray = gbufferProjectionInverse * vec4(texcoord * 2.0 - 1.0, 0.0, 1.0);
// 	// viewVector = (ray.xyz / ray.w);
// 	// viewVector /= viewVector.z;

//     // SunMoonColor = skyLightColor(worldTime, rainStrength);
//     SunMoonColor = sunLightSample();
// }