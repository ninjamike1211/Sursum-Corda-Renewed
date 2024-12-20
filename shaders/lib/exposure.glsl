#include "/lib/defines.glsl"
#include "/lib/functions.glsl"

#define Local_Size_X 16
#define Local_Size_Y 16

#define Min_Log_Lum (-9.9)
#define Max_Log_Lum 10.0

#define Exposure_Scale 1.0

const int Local_Bin_Count = Local_Size_X * Local_Size_Y;
const float Local_Bin_Size_Positive = float(Local_Bin_Count - 2);

const float Log_Lum_Range = abs(Max_Log_Lum - Min_Log_Lum);
const float Inv_Log_Lum_Range = 1.0 / (Log_Lum_Range);

layout(std430, binding = 0) buffer Histogram {
    uint HistogramGlobal[Local_Bin_Count];
    float averageLum;
};


#ifdef EXPOSURE_A

    uniform sampler2D colortex0;
    uniform float viewWidth;
    uniform float viewHeight;

    shared uint HistogramLocal[Local_Bin_Count];

    // Gets the luminance bin index for a given linear color and log range
    uint getBinFromColor(vec3 linearColor) {
        float lum = luminance(linearColor);

        if(lum < EPS) {
            return 0;
        }

        float logLum = clamp((log2(lum) - Min_Log_Lum) * Inv_Log_Lum_Range, 0.0, 1.0);
        return uint(logLum * Local_Bin_Size_Positive + 1.0);
    }


    layout (local_size_x = Local_Size_X, local_size_y = Local_Size_Y, local_size_z = 1) in;
    const vec2 workGroupsRender = vec2(Exposure_Scale, Exposure_Scale);

    void main() {
        HistogramLocal[gl_LocalInvocationIndex] = 0;
        barrier();

        ivec2 samplePos = ivec2(gl_GlobalInvocationID.xy / Exposure_Scale);
        if(clamp(samplePos, ivec2(0), ivec2(viewWidth, viewHeight) - 1) == samplePos) {
            vec3 linearColor = texelFetch(colortex0, samplePos, 0).rgb;
            uint binIndex = getBinFromColor(linearColor);

            atomicAdd(HistogramLocal[binIndex], 1);
        }

        barrier();
        atomicAdd(HistogramGlobal[gl_LocalInvocationIndex], HistogramLocal[gl_LocalInvocationIndex]);
    }

#else
#ifdef EXPOSURE_B

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
            float weightedLogAvg = (HistogramLocal[0] / (viewWidth * viewHeight * Exposure_Scale * Exposure_Scale)) - 1.0;
            
            float averageLumCurr = exp2(((weightedLogAvg / Local_Bin_Size_Positive) * Log_Lum_Range) + Min_Log_Lum);

            if(averageLum >= 0.0) {
                float blend = pow(0.4, frameTime * 2.0);
                averageLum = mix(averageLumCurr, averageLum, blend);
            }
            else {
                averageLum = averageLumCurr;
            }
        }
    }

#endif
#endif