#version 420 compatibility

uniform sampler2D colortex10;

uniform mat4  gbufferModelView;
uniform mat4  gbufferModelViewInverse;
uniform mat4  gbufferProjection;
uniform mat4  gbufferProjectionInverse;
uniform vec3  cameraPosition;
uniform vec3 fogColor;
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
#include "/lib/sky2.glsl"


// ------------------------ File Contents -----------------------
    // Standard fullscreen post-process vertex shader
    // Calculates view vector for cheap view position
    // Calculates direct and indirect light colors


out vec2 texcoord;
out vec3 viewVector;
flat out vec3 skyAmbient;
flat out vec3 skyDirect;

void main() {
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    viewVector = calcViewVector(texcoord);
    
    skyDirect = netherDirectLight;
    skyAmbient = netherAmbientLight;
}



// #version 420 compatibility

// uniform mat4 gbufferProjectionInverse;
// // uniform mat4 gbufferModelViewInverse;
// uniform mat4 gbufferModelView;
// // uniform vec3 sunDir;
// // uniform vec3 moonDir;
// uniform vec3 lightDir;
// // uniform float eyeAltitude;
// uniform float rainStrength;
// // uniform int worldTime;
// uniform bool inEnd;
// uniform bool inNether;
// uniform sampler2D colortex10;
// uniform float sunAngle;
// uniform float shadowAngle;
// uniform float sunHeight;
// uniform float shadowHeight;
// uniform int moonPhase;
// uniform vec3 fogColor;

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
// flat out vec3 skyAmbient;
// flat out vec3 skyDirect;

// void main() {
//     gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    
//     texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

//     viewVector = calcViewVector(texcoord);
//     // vec4 ray = gbufferProjectionInverse * vec4(texcoord * 2.0 - 1.0, 0.0, 1.0);
// 	// viewVector = (ray.xyz / ray.w);
// 	// viewVector /= viewVector.z;

//     // vec3 sunColor = skyColor(normalize(sunPosition), normalize(sunPosition), eyeAltitude, mat3(gbufferModelViewInverse));
//     // vec3 moonColor = skyMoonColor(normalize(moonPosition), normalize(moonPosition), eyeAltitude, mat3(gbufferModelViewInverse));
//     // SunMoonColor = vec3(mix(0.0, 1.5, smoothstep(0.0, 1.0, sunColor.r)) + mix(0.0, 0.6, smoothstep(0.0, 0.01, moonColor.r)));
//     // SunMoonColor = lightColor(normalize(sunPosition), normalize(moonPosition), eyeAltitude, mat3(gbufferModelViewInverse));
//     // SunMoonColor = skyLightColor(worldTime, rainStrength);
//     skyDirect = netherDirectLight;
//     skyAmbient = netherAmbientLight;
// }