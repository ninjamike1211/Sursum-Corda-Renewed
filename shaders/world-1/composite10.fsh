#version 420 compatibility

flat in float windAmplitude;
flat in float windAngle;
flat in float windPhase;

flat in vec4  smoothCenterDepth;

#include "/lib/defines.glsl"

/* RENDERTARGETS: 12 */
layout(location = 0) out vec4 moodOut;

void main() {

    if(all(lessThan(gl_FragCoord.xy - vec2(0.5, 1.5), vec2(EPS)))) {
        moodOut.r = windAmplitude;
        moodOut.g = windAngle;
        moodOut.b = windPhase;
    }
    else if(all(lessThan(gl_FragCoord.xy - vec2(1.5, 0.5), vec2(EPS)))) {
        moodOut = smoothCenterDepth;
    }
}