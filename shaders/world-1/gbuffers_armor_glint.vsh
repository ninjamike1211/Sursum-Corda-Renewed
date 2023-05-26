#version 430 compatibility

uniform float viewWidth;
uniform float viewHeight;
uniform int frameCounter;

#include "/lib/defines.glsl"
// #include "/lib/kernels.glsl"
#include "/lib/TAA.glsl"


// ------------------------ File Contents -----------------------
    // Gbuffers basic objects vertex shader
    // Position calculations
    // Normals calculations
    // Motion vector calculations for TAA or Motion Blur


out vec2 texcoord;
flat out vec4 glColor;

void main() {
    gl_Position = ftransform();

    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glColor = gl_Color;

    #if defined TAA
        int taaIndex = frameCounter % 16;
        gl_Position += vec4((TAAOffsets[taaIndex] * 2.0 - 1.0) * gl_Position.w / vec2(viewWidth, viewHeight), 0.0, 0.0);
    #endif

}