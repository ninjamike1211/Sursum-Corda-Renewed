#version 420 compatibility

#define moodSpeed 0.1

uniform sampler2D colortex12;
uniform sampler2D depthtex0;
uniform sampler2D depthtex2;
uniform float playerMood;
uniform ivec2 eyeBrightness;
uniform float frameTime;
uniform float frameTimeCounter;
uniform float rainStrength;


// ------------------------ File Contents -----------------------
    // Calculates and stores temporal variables, each stored in a pixel of a non-clearing buffer
    // Calculates shadow leak fix using mood
    // Calculates wind effects for waving plants
    // Calculates smoothed centered depth for DOF


#include "/lib/defines.glsl"
#include "/lib/noise.glsl"

flat out float moodVelocity;
flat out float moodAccumulation;
flat out float moodMultiplier;

flat out float windAmplitude;
flat out float windAngle;
flat out float  windPhase;

flat out vec4  smoothCenterDepth;

void main() {
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;


// -------------------- Shadow Leak Mood Fix --------------------
    vec3 moodData = texelFetch(colortex12, ivec2(0), 0).rgb;
    moodData.gb = moodData.gb * 2.0 - 1.0;

    if(moodData.g == -1.0)
        moodData.g = -0.95;

    float diff = playerMood - moodData.r;
    float dir = (playerMood == 0.0 && eyeBrightness.y > 0) ? -1.0 : (abs(diff) > 0.004 && abs(diff) < 0.9 ? sign(diff) : 0.0);

    moodVelocity = moodData.g + dir;

    if(abs(moodVelocity) < 0.1 * frameTime)
        moodVelocity = 0.0;
    else
        moodVelocity -= sign(moodVelocity) * 0.1 * frameTime;

    moodAccumulation = moodData.b + moodSpeed * sign(moodVelocity);

    moodMultiplier = smoothstep(0.89, 0.11, moodAccumulation);

    if(moodVelocity == -1.0)
        moodVelocity = -0.95;

    moodVelocity     = moodVelocity     * 0.5 + 0.5;
    moodAccumulation = moodAccumulation * 0.5 + 0.5;


// --------------------- Wind Waving Effects --------------------
    windAngle     = snoise(vec2(Wind_AngleSpeed * frameTimeCounter, 0.0)) * 0.5 + 0.5;
    windAmplitude = (snoise(vec2(Wind_AmplitudeSpeed * frameTimeCounter)) * 0.5 + 0.5);
    windAmplitude = mix(Wind_MinAmp, Wind_MinAmpRain, rainStrength) + mix((Wind_MaxAmp - Wind_MinAmp), (Wind_MaxAmpRain - Wind_MinAmpRain), rainStrength) * windAmplitude;

    vec2  prevPhaseData = texelFetch(colortex12, ivec2(0,1), 0).rb;
    float prevPhase  = prevPhaseData.y * TAU;
    
    float nextPhase = prevPhase + ((prevPhaseData.r * Wind_Phase_Slope + Wind_Phase_Offset) * frameTime);
    windPhase = mod(nextPhase, TAU) * RCP_TAU;


// --------------------- Smooth Center Depth --------------------
    vec4 prevDepthData = texelFetch(colortex12, ivec2(1,0), 0).rgba;

    vec2 newCenterDepth = vec2(texture(depthtex0, vec2(0.5)).r, texture(depthtex2, vec2(0.5)).r);

    if(DOF_FocusSpeed > 0.0) {
        vec2 prevCenterDepth = prevDepthData.rb + (prevDepthData.ga / 255.0);
        
        float newAmount = clamp(frameTime * DOF_FocusSpeed, 0.0, 1.0);
        newCenterDepth = mix(prevCenterDepth, newCenterDepth, frameTime * DOF_FocusSpeed);
    }
    
    newCenterDepth *= 255.0;

    smoothCenterDepth.rb = floor(newCenterDepth);
    smoothCenterDepth.ga = floor((newCenterDepth - smoothCenterDepth.rb) * 255.0);

    smoothCenterDepth /= 255.0;
}