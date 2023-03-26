#version 420 compatibility

uniform mat4  gbufferProjectionInverse;
uniform mat4  gbufferModelView;
uniform mat4  gbufferModelViewInverse;
uniform mat4  gbufferProjection;
uniform vec3  cameraPosition;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform int   frameCounter;
uniform int   worldTime;
uniform bool  cameraMoved;

#include "/lib/defines.glsl"
#include "/lib/kernels.glsl"
#include "/lib/TAA.glsl"
#include "/lib/spaceConvert.glsl"


// ------------------------ File Contents -----------------------
    // Standard fullscreen post-process vertex shader
    // Calculates view vector for cheap view position
    

out vec2 texcoord;
out vec3 viewVector;

void main() {
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    viewVector = calcViewVector(texcoord, frameCounter, vec2(viewWidth, viewHeight), gbufferProjectionInverse);
}