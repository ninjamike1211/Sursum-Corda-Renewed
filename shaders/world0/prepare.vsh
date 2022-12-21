#version 400 compatibility

#define moodSpeed 0.1

uniform sampler2D colortex12;
uniform float playerMood;
uniform float playerMoodSmooth;
uniform ivec2 eyeBrightness;
uniform float frameTime;
uniform float frameTimeCounter;
uniform float rainStrength;

#include "/lib/defines.glsl"
#include "/lib/noise.glsl"

out vec2 texcoord;

flat out float moodVelocity;
flat out float moodAccumulation;
flat out float moodMultiplier;

flat out float windAmplitude;
flat out float windAngle;
flat out vec2  windPhase;

void main() {
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;

    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    vec3 moodData = texture(colortex12, vec2(0.0)).rgb;
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
    // moodMultiplier   = moodMultiplier;


    windAngle     = snoise(vec2(Wind_AngleSpeed * frameTimeCounter, 0.0)) * 0.5 + 0.5;
    windAmplitude = (snoise(vec2(Wind_AmplitudeSpeed * frameTimeCounter)) * 0.5 + 0.5);
    windAmplitude = mix(Wind_MinAmp, Wind_MinAmpRain, rainStrength) + mix((Wind_MaxAmp - Wind_MinAmp), (Wind_MaxAmpRain - Wind_MinAmpRain), rainStrength) * windAmplitude;

    vec2  prevPhaseData = texture(colortex12, vec2(1.0)).rb;
    float prevPhase  = prevPhaseData.y * TAU;
    
    float nextPhase = prevPhase + ((prevPhaseData.r * Wind_Phase_Slope + Wind_Phase_Offset) * frameTime);
    nextPhase = mod(nextPhase, TAU) * RCP_TAU; // Range 0-1

    // windPhase.x = fract(nextPhase * 255.0);
    windPhase.x = nextPhase;
	
	// float windWave = sin((windAmplitude * 0.4 + 0.1) * frameTimeCounter /* + worldPos.x + worldPos.z */);
}