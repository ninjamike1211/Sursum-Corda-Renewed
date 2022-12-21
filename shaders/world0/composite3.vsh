#version 400 compatibility

// uniform float centerDepthSmooth;
uniform sampler2D depthtex0;
uniform mat4 gbufferModelView;
uniform mat4  gbufferModelViewInverse;
uniform mat4  gbufferProjection;
uniform mat4  gbufferProjectionInverse;
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
    // Calculate linear center depth


out vec2 texcoord;
flat out float centerDepthLinear;

void main() {
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    // centerDepthLinear = linearizeDepthFast(centerDepthSmooth);
    centerDepthLinear = linearizeDepthFast(texture(depthtex0, vec2(0.5)).r);
}