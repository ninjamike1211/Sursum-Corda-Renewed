#version 420 compatibility

uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform sampler2D colortex6;

uniform float viewWidth;

#include "/lib/defines.glsl"


// ------------------------ File Contents -----------------------
    // Apply Motion Blur


/* RENDERTARGETS: 0*/
layout(location = 0) out vec4 colorOut;

in vec2 texcoord;

void main() {

    colorOut = texture(colortex0, texcoord);

    // ------------------- Motion Blur -------------------
    #ifdef MotionBlur
        vec2 velocity = clamp(texture(colortex6, texcoord).xy, vec2(-0.1), vec2(0.1));

        if(length(velocity) > 0.0) {
            float isHand = texture(colortex3, texcoord).b;
            int samples = 1;
            vec2 delta = MotionBlur_Strength * velocity / (MotionBlur_Samples);
            vec2 sampleCoord = texcoord;
            
            for(int i = 0; i < MotionBlur_Samples; i++) {
                sampleCoord += delta;
                if(clamp(sampleCoord, 0.0, 1.0) == sampleCoord) {
                    if(isHand == texture(colortex3, sampleCoord).b) {
                        colorOut.rgb += texture(colortex0, sampleCoord).rgb;
                        samples++;
                    }
                }
            }
            
            colorOut.rgb /= samples;
        }
    #endif
}



// #version 420 compatibility

// uniform sampler2D colortex0;
// uniform sampler2D colortex3;
// uniform sampler2D colortex6;
// uniform mat4 gbufferModelView;
// uniform bool inNether;
// uniform bool inEnd;

// uniform mat4  gbufferModelViewInverse;
// uniform mat4  gbufferProjection;
// uniform mat4  gbufferProjectionInverse;
// uniform vec3  cameraPosition;
// uniform float rainStrength;
// uniform float near;
// uniform float far;
// uniform float viewWidth;
// uniform float viewHeight;
// uniform int   frameCounter;
// uniform int   worldTime;
// uniform bool  cameraMoved;

// #include "/lib/defines.glsl"
// #include "/lib/kernels.glsl"
// #include "/lib/functions.glsl"

// /* RENDERTARGETS: 0*/
// layout(location = 0) out vec4 colorOut;

// in vec2 texcoord;

// void main() {

//     colorOut = texture2D(colortex0, texcoord);

//     // ------------------- Motion Blur -------------------
//     #ifdef MotionBlur
//         vec2 velocity = clamp(texture2D(colortex6, texcoord).xy, vec2(-0.1), vec2(0.1));

//         if(length(velocity) > 1.0 / viewWidth) {
//             float isHand = texture2D(colortex3, texcoord).b;
//             int samples = 1;
            
//             for(int i = 1; i < MotionBlur_Samples+1; i++) {
//                 vec2 sampleCoord = texcoord + 1.0 * i * velocity / (MotionBlur_Samples+1);
//                 if(clamp(sampleCoord, 0.0, 1.0) == sampleCoord) {
//                     if(isHand == texture2D(colortex3, sampleCoord).b) {
//                         colorOut.rgb += texture2D(colortex0, sampleCoord).rgb;
//                         samples++;
//                     }
//                 }
//             }
            
//             colorOut.rgb /= samples;
//         }
//     #endif
// }