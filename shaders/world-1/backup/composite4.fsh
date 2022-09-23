#version 420 compatibility

uniform sampler2D colortex0;
uniform sampler2D colortex3;
// uniform sampler2D colortex14;
uniform sampler2D depthtex0;
uniform float aspectRatio;
// uniform float centerDepthSmooth;
uniform mat4 gbufferModelView;
uniform bool inEnd;
uniform bool inNether;

#include "/functions.glsl"

in vec2 texcoord;
in flat float centerDepthLinear;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 albedo;

// float unpackCoC(float value) {
//     return (value * 2.0 - 1.0) * DOF_Factor;
// }

void main() {
    #ifdef DOF
        // float currentDist = unpackCoC(texture2D(colortex14, texcoord).r);
        float hand = texture2D(colortex3, texcoord).b;
        float depth = linearizeDepthFast(texture2D(depthtex0, texcoord).r);
        // float centerDepthLinear = linearizeDepthFast(centerDepthSmooth);
        // float blockerDist = 0.0;
        // float count = 0.0;

        // for(int i = 0; i < DOF_Blocker_Samples; i++) {
        //     vec2 samplePos = texcoord + DOF_Factor * GetVogelDiskSample(i, DOF_Blocker_Samples, 0.0) * vec2(1.0, aspectRatio);
        //     float dist = (texture2D(colortex14, samplePos).r * 2.0 - 1.0) * DOF_Factor;

        //     if(currentDist - dist > -0.01) {
        //         blockerDist += abs(dist-currentDist);
        //         count++;
        //     }
        // }
        // float cof = blockerDist / count;
        // float coc = currentDist;
        // float coc = DOF_Factor / far * abs(depth - centerDepthLinear);
        float focalLength = 1.0 / (1.0 / centerDepthLinear + 1.0 / DOF_ImageDistance);
        // float coc = abs(DOF_FocalLength / (centerDepthLinear - DOF_FocalLength) * (1.0 - (centerDepthLinear / depth)));
        float coc = -(focalLength * (centerDepthLinear - depth)) / (depth * (centerDepthLinear - focalLength));
        // coc = min(abs(coc), 0.05);
        // cof = 0.003;
        if(hand > 0.9)
            coc = min(0.0, coc*0.5 + 0.032);

        int samples = int(DOF_Samples);
        // int samples = int(pow(coc * viewWidth, 2.0) * PI * DOF_Density) + 1;
        int samplesUsed = samples;

        for(int i = 0; i < samples; i++) {
            vec2 samplePos = texcoord + coc * GetVogelDiskSample(i, samples, 0.0) * vec2(1.0, aspectRatio);
            float sampleDepth = linearizeDepthFast(texture2D(depthtex0, samplePos).r);
            // if(depth - sampleDepth > 0.1)
            //     // albedo.rgb += texture2D(colortex0, texcoord).rgb;
            //     samplesUsed--;
            // else
                albedo.rgb += texture2D(colortex0, samplePos).rgb;
        }

        albedo /= samplesUsed;
    #else
        albedo = texture2D(colortex0, texcoord);
    #endif

    // albedo = texture2D(colortex14, texcoord);
}