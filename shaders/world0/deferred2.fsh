#version 430 compatibility

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

/* RENDERTARGETS: 9 */
layout(location = 0) out vec4 SSAOOut;

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

}