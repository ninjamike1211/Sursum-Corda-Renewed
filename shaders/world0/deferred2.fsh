#version 420 compatibility

uniform sampler2D colortex8;
uniform sampler2D colortex9;
uniform float viewWidth;
uniform float viewHeight;

#include "/lib/defines.glsl"
#include "/lib/kernels.glsl"


// ------------------------ File Contents -----------------------
    // Horizontal blurring of unfiltered SSAO
    // Outputs horizontally filtered SSAO to colortex9


in vec2 texcoord;

/* RENDERTARGETS: 8,9 */
layout(location = 0) out vec4 POMOut;
layout(location = 1) out vec4 SSAOOut;

void main() {

// ------------------------ SSAO Filter -------------------------
    #ifdef SSAO
        vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight);
        vec3 occlusion = vec3(0.0);

        for(int i = 0; i < 5; i++) {
            vec2 offset = vec2((i-2), 0.0) * texelSize;

            occlusion += gaussian_5[i] * texture(colortex9, texcoord + offset).rgb;
        }

        SSAOOut = vec4(occlusion, 1.0);
    #else
        SSAOOut = vec4(1.0);
    #endif

    POMOut = texture(colortex8, texcoord);

    #ifdef POM_Shadow
        #ifndef SSAO
            vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight);
        #endif
        
        float shadow = 0.0;

        for(int i = 0; i < 9; i++) {
            vec2 offset = vec2((i-4), 0.0) * texelSize;

            shadow += gaussian_9[i] * texture(colortex8, texcoord + offset).g;
        }

        POMOut.g = shadow;
    #endif
}