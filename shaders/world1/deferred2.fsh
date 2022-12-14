#version 400 compatibility

uniform float viewWidth;
uniform float viewHeight;
uniform sampler2D colortex9;

#include "/lib/kernels.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 9 */
layout(location = 0) out vec4 SSAOOut;

void main() {
    // #ifdef SSAO

        vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight);
        vec3 occlusion = vec3(0.0);

        for(int i = 0; i < 5; i++) {
            vec2 offset = vec2((i-2), 0.0) * texelSize;

            occlusion += 0.2 * texture2D(colortex9, texcoord + offset).rgb;
        }

        SSAOOut = vec4(occlusion, 1.0);

    // #endif
}