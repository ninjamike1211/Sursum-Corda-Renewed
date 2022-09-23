#version 420 compatibility

uniform sampler2D colortex11;
uniform float viewWidth;
uniform float viewHeight;

#include "/defines.glsl"
#include "/kernels.glsl"
#include "/bloomTile.glsl"

/* RENDERTARGETS: 11*/
layout(location = 0) out vec4 bloomOut;

in vec2 texcoord;

void main() {
    vec2 offset = vec2(1.0 / viewWidth, 0.0);
    bloomOut = vec4(0.0, 0.0, 0.0, 1.0);

    vec4 bounds = getTileBoundsBlur(texcoord, 1.0 / vec2(viewWidth, viewHeight), Bloom_Tiles);

    if(bounds.x < -0.5) {
        // bloomOut = vec4(0.0);
        return;
    }

    for(int i = 0; i < 7; i++) {
        vec2 samplecoord = texcoord + (i-3)*offset;
        samplecoord = min(max(samplecoord, bounds.xy), bounds.zw);

        bloomOut.rgb += gaussian_7[i] * texture2D(colortex11, samplecoord).rgb;
    }
}