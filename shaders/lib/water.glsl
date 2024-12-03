
float cosOffset(float amp, vec2 pos, float angle, float posMult, float offset) {
    return amp * cos(posMult*dot(pos, vec2(cos(angle), sin(angle))) + offset);
}

vec2 cosDerivs(float amp, vec2 pos, float angle, float posMult, float offset) {
    float derivX = amp * posMult * cos(angle) * sin(posMult*dot(pos, vec2(cos(angle), sin(angle))) + offset);
    float derivY = amp * posMult * sin(angle) * sin(posMult*dot(pos, vec2(cos(angle), sin(angle))) + offset);

    return vec2(derivX, derivY);
}

float waterOffset(vec3 worldPos, float time) {
    float offset  = cosOffset(0.550, worldPos.xz, 1.580*PI, 0.125, 0.9*time);
          offset += cosOffset(0.200, worldPos.xz, 0.966*PI, 0.250, 1.1*time);
          offset += cosOffset(0.150, worldPos.xz, 1.163*PI, 0.500, 1.3*time);
          offset += cosOffset(0.100, worldPos.xz, 0.364*PI, 0.750, 1.5*time);

    return Water_Height * Water_VertexHeightMult * offset;
}

vec3 waterNormal(vec3 worldPos, float time) {
    vec2 derivs  = cosDerivs(0.550, worldPos.xz, 1.580*PI, 0.125, 0.9*time);
         derivs += cosDerivs(0.200, worldPos.xz, 0.966*PI, 0.250, 1.1*time);
         derivs += cosDerivs(0.150, worldPos.xz, 1.163*PI, 0.500, 1.3*time);
         derivs += cosDerivs(0.100, worldPos.xz, 0.364*PI, 0.750, 1.5*time);

         derivs += cosDerivs(0.050, worldPos.xz, 1.555*PI, 1.000, 1.8*time);
         derivs += cosDerivs(0.020, worldPos.xz, 2.175*PI, 1.750, 2.0*time);
         derivs += cosDerivs(0.010, worldPos.xz, 0.367*PI, 2.750, 2.4*time);
         derivs += cosDerivs(0.005, worldPos.xz, 0.734*PI, 4.000, 2.9*time);
         derivs += cosDerivs(0.003, worldPos.xz, 1.967*PI, 6.000, 2.9*time);

    derivs *= Water_Height;

    return normalize(vec3(derivs.x, derivs.y, 1.0));
}

void simpleWaterFog(inout vec3 sceneColor, float vectorLen, vec3 skyAmbient) {
	float fogFactor = exp(-vectorLen*0.07);
	sceneColor = mix(0.2*vec3(0.4, 0.7, 0.8) * skyAmbient, sceneColor, fogFactor);
}

#ifdef WaterVolumetrics
void volumetricWaterFog(inout vec3 sceneColor, vec3 startPos, vec3 endPos, float eyeAltitude, vec3 skyDirect, vec3 skyAmbient, float bias, sampler2D shadowSampler) {
    int sampleCount = 32;
    
    vec3  diff = -(endPos - startPos) / sampleCount;
    vec3  rayPos = endPos + bias*diff;

    float diffLength = length(diff);
    float fogFactor = exp(-diffLength*0.07);

    float sunDot = normalize(endPos).y;

    for(int i = 0; i < sampleCount; i++) {
        rayPos += diff;

        vec3 shadowPos = calcShadowPosScene(rayPos);
        distortShadowPos(shadowPos);
        float shadowVal = step(shadowPos.z, texture(shadowSampler, shadowPos.xy).x);
        // vec3 shadowVal = shadowVisibility(shadowPos);
        // float waterDist = (60.0 - rayPos.y+eyeAltitude) / sunDot;
        // float waterScatterMult = 1.0-exp(-diffLength*0.07);
        // waterScatterMult = 1.0;

        vec3 fogColor = 0.04*vec3(0.4, 0.7, 0.8) * (skyAmbient + shadowVal*skyDirect);
        // vec3 fogColor = waterScatterMult * 0.1*vec3(0.4, 0.7, 0.8) * (skyAmbient + shadowVal*skyDirect);

	    sceneColor = mix(fogColor, sceneColor, fogFactor);
    }
    
    // float vectorLen = length(endPos - startPos);
    // float fogFactor = exp(-vectorLen*0.07);
	// sceneColor = mix(0.2*vec3(0.4, 0.7, 0.8) * skyAmbient, sceneColor, fogFactor);
}
#endif