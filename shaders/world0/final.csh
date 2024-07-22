#version 430

uniform float rainStrength;
uniform float frameTime;
uniform float frameTimeCounter;

#include "/lib/defines.glsl"
#include "/lib/noise.glsl"
#include "/lib/weather.glsl"

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
const ivec3 workGroups = ivec3(1, 1, 1);

void main() {
    float nextPhase = weather.windPhase + ((weather.windAmplitude * Wind_Phase_Slope + Wind_Phase_Offset) * frameTime);
    weather.windPhase = mod(nextPhase, TAU);

    weather.windAngle     = snoise(vec2(Wind_AngleSpeed * frameTimeCounter, 0.0)) * 0.5 + 0.5;
    weather.windAmplitude = (snoise(vec2(Wind_AmplitudeSpeed * frameTimeCounter)) * 0.5 + 0.5);
    weather.windAmplitude = mix(Wind_MinAmp, Wind_MinAmpRain, rainStrength) + mix((Wind_MaxAmp - Wind_MinAmp), (Wind_MaxAmpRain - Wind_MinAmpRain), rainStrength) * weather.windAmplitude;
}