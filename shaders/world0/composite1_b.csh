#version 430

#include "/lib/defines.glsl"
#include "/lib/exposure.glsl"
#include "/lib/functions.glsl"

uniform float viewWidth;
uniform float viewHeight;
uniform float frameTime;

shared uint HistogramLocal[Local_Bin_Count];


layout (local_size_x = Local_Size_X, local_size_y = Local_Size_Y, local_size_z = 1) in;
const ivec3 workGroups = ivec3(1, 1, 1);

void main() {
    uint bin = HistogramGlobal[gl_LocalInvocationIndex];
    HistogramLocal[gl_LocalInvocationIndex] = bin * gl_LocalInvocationIndex;
    barrier();

    HistogramGlobal[gl_LocalInvocationIndex] = 0;

    for(uint index = (Local_Bin_Count >> 1); index > 0; index >>= 1) {
        if(gl_LocalInvocationIndex < index) {
            HistogramLocal[gl_LocalInvocationIndex] += HistogramLocal[gl_LocalInvocationIndex + index];
        }
        barrier();
    }

    if(gl_LocalInvocationIndex == 0) {
        float weightedLogAvg = (HistogramLocal[0] / max((viewWidth * viewHeight * Exposure_Scale * Exposure_Scale) - bin, 1.0)) - 1.0;
        
        float averageLumCurr = exp2(((weightedLogAvg / Local_Bin_Size_Positive) * Log_Lum_Range) + Min_Log_Lum);

        float blend = pow(0.4, frameTime * 2.0);
        averageLum = mix(averageLumCurr, averageLum, blend);
    }
}