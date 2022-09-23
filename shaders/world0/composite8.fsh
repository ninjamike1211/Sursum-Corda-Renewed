#version 420 compatibility

uniform sampler2D colortex0;
uniform sampler2D colortex11;
uniform mat4 gbufferModelView;
uniform bool inEnd;
uniform bool inNether;

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform mat4  gbufferModelViewInverse;
uniform mat4  gbufferProjection;
uniform mat4  gbufferProjectionInverse;
uniform mat4  shadowModelView;
uniform mat4  shadowProjection;
uniform vec3  cameraPosition;
uniform float rainStrength;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform int   frameCounter;
uniform int   worldTime;
uniform bool  cameraMoved;

#include "/defines.glsl"
#include "/kernels.glsl"
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
            vec4 bounds;
            vec2 samplecoord = getTileCoordRead(texcoord, 1.0 / vec2(viewWidth, viewHeight), i, bounds);

            #ifdef Bloom_Bicubic
                bloom += Bloom_Strength * 0.25 * textureBicubic(colortex11, samplecoord).rgb;
            #else
                bloom += Bloom_Strength * 0.25 * texture2D(colortex11, samplecoord).rgb;
            #endif
        }

        colorOut.rgb += bloom /* * smoothstep(0.2, 1.0, luminance(bloom)) */;
        // colorOut.rgb = mix(colorOut.rgb, bloom, clamp(luminance(bloom), 0.0, 1.0));

        // colorOut.rgb = texelFetch(colortex11, ivec2(texcoord * vec2(viewWidth, viewHeight)), 0).rgb;
    #endif
}