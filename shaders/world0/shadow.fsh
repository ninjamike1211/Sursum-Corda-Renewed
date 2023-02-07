#version 420 compatibility

#define shadowGbuffer

uniform sampler2D tex;
uniform float alphaTestRef;
uniform float frameTimeCounter;
uniform vec3  cameraPosition;

#include "/lib/defines.glsl"
#include "/lib/noise.glsl"
#include "/lib/water.glsl"
#include "/lib/functions.glsl"


// ------------------------ File Contents -----------------------
    // Shadows fragment shader
    // Applies water cuastics to shadows


in vec2 texcoord;
in vec4 glColor;
in vec3 worldPosVertex;
flat in int entity;

layout(location = 0) out vec4 shadowColor;

void main() {

    vec2 texcoordFinal = texcoord;

    shadowColor = texture(tex, texcoordFinal) * glColor;
    if (shadowColor.a < alphaTestRef) discard;

    shadowColor.rgb = sRGBToLinear3(shadowColor.rgb);

    if(entity == 10010) {
        shadowColor.a = 0.0;

        float caustics = (pow(waterHeightFunc(worldPosVertex.xz), 5.0) * 0.8 + 0.2) * 1.8;

        shadowColor.rgb = sRGBToLinear3(glColor.rgb) * caustics * 1.0;
    }
}