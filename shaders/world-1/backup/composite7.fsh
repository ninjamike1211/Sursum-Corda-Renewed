#version 420 compatibility

uniform sampler2D colortex11;
uniform float viewWidth;
uniform float viewHeight;

#include "/kernels.glsl"

/* RENDERTARGETS: 11*/
layout(location = 0) out vec4 bloomOut;

in vec2 texcoord;

void main() {
    vec2 offset = vec2(1.0 / viewWidth, 0.0);
    bloomOut = vec4(0.0, 0.0, 0.0, 1.0);

    for(int i = 0; i < 7; i++) {
        bloomOut.rgb += gaussian_7[i] * texture2D(colortex11, texcoord + (i-3)*offset).rgb;
    }
}