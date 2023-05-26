#version 430 compatibility

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
    // gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    // texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    // Procedurally generates a single triangle that covers the screen
    int id = gl_VertexID;
    ivec2 uv = id & ivec2(1, 2);
    gl_Position = vec4(uv * ivec2(4, 2) - 1, 0.0, 1.0);

    texcoord = gl_Position.xy * 0.5 + 0.5;

    viewVector = calcViewVector(texcoord, frameCounter, vec2(viewWidth, viewHeight), gbufferProjectionInverse);
}