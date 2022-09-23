#version 420 compatibility

uniform sampler2D colortex0;
uniform sampler2D colortex11;
uniform mat4 gbufferModelView;
uniform bool inEnd;
uniform bool inNether;

#include "/functions.glsl"
#include "/bloomTile.glsl"

/* RENDERTARGETS: 0*/
layout(location = 0) out vec4 colorOut;

in vec2 texcoord;


void main() {
    
    colorOut = texture2D(colortex0, texcoord);

    #ifdef Bloom
        vec3 bloom = vec3(0.0);
        for(int i = 0; i < Bloom_Tiles; i++) {
            vec2 samplecoord = getTileCoordRead(texcoord, 1.0 / vec2(viewWidth, viewHeight), i);
            bloom += Bloom_Strength * 0.25 * texture2D(colortex11, samplecoord).rgb;
        }

        colorOut.rgb += bloom /* * smoothstep(0.2, 1.0, luminance(bloom)) */;
    #endif
}