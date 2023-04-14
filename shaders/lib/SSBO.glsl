#ifndef SSBO_GLSL
#define SSBO_GLSL

layout(std430, binding = 0) buffer ssbo_temporalData {
    float previousMood;
    float moodVelocityAvg;
    float caveShadowMult;
    float windAmplitude;
    float windAngle;
    float windPhase;
    vec2 centerDepthSmooth;
} ssbo;


#ifdef SSBO_Vertex
void setSSBO() {
    // --------------------- Temporal Variables ---------------------
    float moodVelocity = (playerMood - ssbo.previousMood) / frameTime;
    if(playerMood < 0.0001)
        moodVelocity = -1.0;

    if(sign(moodVelocity) != 0.0)
        ssbo.moodVelocityAvg = clamp(mix(ssbo.moodVelocityAvg, sign(moodVelocity), 0.01), -1.0, 1.0);

    // ssbo.caveShadowMult = step(ssbo.moodVelocityAvg, 0.0);
    // ssbo.caveShadowMult = clamp(-ssbo.moodVelocityAvg, 0.0, 1.0);
    ssbo.caveShadowMult = smoothstep(0.8, -0.8, ssbo.moodVelocityAvg);

    ssbo.previousMood = playerMood;

    
    float nextPhase = ssbo.windPhase + ((ssbo.windAmplitude * Wind_Phase_Slope + Wind_Phase_Offset) * frameTime);
    ssbo.windPhase = mod(nextPhase, TAU);

    ssbo.windAngle     = snoise(vec2(Wind_AngleSpeed * frameTimeCounter, 0.0)) * 0.5 + 0.5;
    ssbo.windAmplitude = (snoise(vec2(Wind_AmplitudeSpeed * frameTimeCounter)) * 0.5 + 0.5);
    ssbo.windAmplitude = mix(Wind_MinAmp, Wind_MinAmpRain, rainStrength) + mix((Wind_MaxAmp - Wind_MinAmp), (Wind_MaxAmpRain - Wind_MinAmpRain), rainStrength) * ssbo.windAmplitude;


    vec2 newCenterDepth = vec2(texture(depthtex0, vec2(0.5)).r, texture(depthtex2, vec2(0.5)).r);

    if(DOF_FocusSpeed > 0.0) {
        float newAmount = clamp(frameTime * DOF_FocusSpeed, 0.0, 1.0);
        newCenterDepth = mix(ssbo.centerDepthSmooth, newCenterDepth, frameTime * DOF_FocusSpeed);
    }
    
    ssbo.centerDepthSmooth = newCenterDepth;
}
#endif


#endif