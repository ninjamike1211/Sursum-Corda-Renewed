#version 420 compatibility

uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform sampler2D colortex6;

uniform float viewWidth;

#include "/lib/defines.glsl"

/* RENDERTARGETS: 0*/
layout(location = 0) out vec4 colorOut;

in vec2 texcoord;

void main() {

    colorOut = texture2D(colortex0, texcoord);

    // ------------------- Motion Blur -------------------
    #ifdef MotionBlur
        vec2 velocity = clamp(texture2D(colortex6, texcoord).xy, vec2(-0.1), vec2(0.1));

        if(length(velocity) > 1.0 / viewWidth) {
            float isHand = texture2D(colortex3, texcoord).b;
            int samples = 1;
            vec2 delta = MotionBlur_Strength * velocity / (MotionBlur_Samples);
            vec2 sampleCoord = texcoord;
            
            for(int i = 0; i < MotionBlur_Samples; i++) {
                sampleCoord += delta;
                if(clamp(sampleCoord, 0.0, 1.0) == sampleCoord) {
                    if(isHand == texture2D(colortex3, sampleCoord).b) {
                        colorOut.rgb += texture2D(colortex0, sampleCoord).rgb;
                        samples++;
                    }
                }
            }
            
            colorOut.rgb /= samples;
        }
    #endif
}