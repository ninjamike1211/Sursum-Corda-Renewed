#version 400 compatibility

// uniform float centerDepthSmooth;
uniform sampler2D depthtex0;
uniform mat4 gbufferModelView;
uniform bool inEnd;
uniform bool inNether;

#include "/functions.glsl"

out vec2 texcoord;
flat out float centerDepthLinear;

void main() {
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    // centerDepthLinear = linearizeDepthFast(centerDepthSmooth);
    centerDepthLinear = linearizeDepthFast(texture2D(depthtex0, vec2(0.5)).r);
}