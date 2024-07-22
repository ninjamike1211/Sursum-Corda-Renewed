#version 430

#include "/lib/defines.glsl"
#include "/lib/exposure.glsl"
#include "/lib/functions.glsl"

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