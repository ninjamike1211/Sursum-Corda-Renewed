#version 400 compatibility

uniform float playerMood;
uniform float playerMoodSmooth;

in vec2 texcoord;

flat in float moodVelocity;
flat in float moodAccumulation;
flat in float moodMultiplier;

flat in float windAmplitude;
flat in float windAngle;
flat in vec2  windPhase;

/* RENDERTARGETS: 12 */
layout(location = 0) out vec4 moodOut;

void main() {

    if(texcoord.x < 0.5) {
        moodOut.r = playerMood;
        moodOut.g = moodVelocity;
        moodOut.b = moodAccumulation;
        moodOut.a = moodMultiplier;
    }
    else {
        moodOut.r  = windAmplitude;
        moodOut.g  = windAngle;
        moodOut.ba = windPhase;
    }
}