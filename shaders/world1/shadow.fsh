#version 420 compatibility

#define shadowGbuffer

uniform sampler2D tex;
uniform float alphaTestRef;
uniform float frameTimeCounter;
uniform vec3  cameraPosition;

#include "/lib/defines.glsl"
#include "/lib/noise.glsl"
#include "/lib/water.glsl"


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

    if(entity == 10010) {
        shadowColor.a = 0.0;

        float caustics = (pow(waterHeightFunc(worldPosVertex.xz), 5.0) * 0.9 + 0.1) * 2.0;

        shadowColor.rgb = glColor.rgb * caustics * 2.0;
    }
}