#version 430 compatibility

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

    viewVector = calcViewVector(texcoord, frameCounter, vec2(viewWidth, viewHeight), gbufferProjectionInverse);
    
    skyAmbient = netherAmbientLight;
    skyDirect = netherDirectLight;

    lightDir = normalize(vec3(0.0, 1.0, 0.0) + 0.03 * vec3(
        SimplexPerlin2D(frameTimeCounter * vec2(2.0, 3.0)), 0.0, SimplexPerlin2D(frameTimeCounter * vec2(2.5, 1.5))
    ));
}