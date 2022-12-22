#version 400 compatibility

uniform sampler2D colortex10;

uniform mat4  gbufferModelView;
uniform mat4  gbufferModelViewInverse;
uniform mat4  gbufferProjection;
uniform mat4  gbufferProjectionInverse;
uniform vec3  cameraPosition;
uniform vec3 fogColor;
uniform float frameTimeCounter;
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
#include "/lib/noise.glsl"
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
flat out vec3 lightDir;

void main() {
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    viewVector = calcViewVector(texcoord);
    
    skyAmbient = netherAmbientLight;
    skyDirect = netherDirectLight;

    lightDir = normalize(vec3(0.0, 1.0, 0.0) + 0.03 * vec3(
        SimplexPerlin2D(frameTimeCounter * vec2(2.0, 3.0)), 0.0, SimplexPerlin2D(frameTimeCounter * vec2(2.5, 1.5))
    ));
}



// #version 400 compatibility

// uniform mat4 gbufferProjectionInverse;
// // uniform mat4 gbufferModelViewInverse;
// uniform mat4 gbufferModelView;
// // uniform vec3 sunPosition;
// // uniform vec3 moonPosition;
// // uniform vec3 sunDir;
// // uniform vec3 lightDir;
// // uniform float eyeAltitude;
// uniform float rainStrength;
// // uniform int worldTime;
// uniform bool inEnd;
// uniform bool inNether;
// uniform sampler2D colortex10;
// uniform float shadowAngle;
// uniform float sunAngle;
// uniform float sunHeight;
// uniform float shadowHeight;
// uniform int moonPhase;
// uniform vec3 fogColor;
// uniform float frameTimeCounter;

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
// #include "/lib/noise.glsl"
// #include "/lib/functions.glsl"
// #include "/lib/sky2.glsl"

// out vec2 texcoord;
// out vec3 viewVector;
// flat out vec3 skyAmbient;
// flat out vec3 skyDirect;
// flat out vec3 lightDir;
// // flat out vec3 lightDirView;


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
//     // skyDirect = skyLightColor(worldTime, rainStrength);
//     skyAmbient = netherAmbientLight;
//     skyDirect = netherDirectLight;

//     // vec3 lightDir = normalize(vec3(0.0, 1.0, 0.0) - 0.05 * vec3(
//     //     0.6 * cos(frameTimeCounter * PI * 2 + 1.0) + 0.3 * cos(frameTimeCounter * PI * 10 + 2.0) + 0.1 * cos(frameTimeCounter * PI * 20 + 0.5), 0.0, 
//     //     0.6 * cos(frameTimeCounter * PI * 3 + 4.0) + 0.3 * cos(frameTimeCounter * PI * 8  + 1.5) + 0.1 * cos(frameTimeCounter * PI * 22 + 0.2)));
//     lightDir = normalize(vec3(0.0, 1.0, 0.0) + 0.03 * vec3(
//         SimplexPerlin2D(frameTimeCounter * vec2(2.0, 3.0)), 0.0, SimplexPerlin2D(frameTimeCounter * vec2(2.5, 1.5))
//     ));
//     // lightDirView = (gbufferModelView * vec4(lightDir, 0.0)).xyz;
// }