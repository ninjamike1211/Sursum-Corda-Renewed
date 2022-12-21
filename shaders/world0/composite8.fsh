#version 420 compatibility

uniform sampler2D colortex0;
uniform sampler2D colortex11;
uniform float viewWidth;
uniform float viewHeight;

#include "/lib/defines.glsl"
#include "/lib/sample.glsl"
#include "/lib/bloomTile.glsl"

/* RENDERTARGETS: 0*/
layout(location = 0) out vec4 colorOut;

in vec2 texcoord;


void main() {
    
    colorOut = texture(colortex0, texcoord);

    #ifdef Bloom
        vec3 bloom = vec3(0.0);
        for(int i = 0; i < Bloom_Tiles; i++) {
            vec4 bounds;
            vec2 samplecoord = getTileCoordRead(texcoord, 1.0 / vec2(viewWidth, viewHeight), i, bounds);

            #ifdef Bloom_Bicubic
                bloom += Bloom_Strength * 0.25 * textureBicubic(colortex11, samplecoord).rgb;
            #else
                bloom += Bloom_Strength * 0.25 * texture(colortex11, samplecoord).rgb;
            #endif
        }

        colorOut.rgb += bloom /* * smoothstep(0.2, 1.0, luminance(bloom)) */;
        // colorOut.rgb = mix(colorOut.rgb, bloom, clamp(luminance(bloom), 0.0, 1.0));

        // colorOut.rgb = texelFetch(colortex11, ivec2(texcoord * vec2(viewWidth, viewHeight)), 0).rgb;
    #endif
}