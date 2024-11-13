
float cosOffset(float amp, vec2 pos, vec2 angle, float posMult, float offset) {
    return amp * cos(posMult*dot(pos, angle) + offset);
}

vec2 cosDerivs(float amp, vec2 pos, vec2 angle, float posMult, float offset) {
    float derivX = amp * posMult * angle.x * sin(posMult*dot(pos, angle) + offset);
    float derivY = amp * posMult * angle.y * sin(posMult*dot(pos, angle) + offset);

    return vec2(derivX, derivY);
}

float waterOffset(vec3 worldPos, float time) {
    // float offset  = 0.05*cos(1.2*worldPos.x + 1.8*time);
    //       offset += 0.05*cos(0.8*worldPos.z + 0.9*time);

    float offset  = cosOffset(0.05, worldPos.xz, vec2(cos(2.8), sin(2.8)), 1.2, 1.8*time);
          offset += cosOffset(0.05, worldPos.xz, vec2(cos(4.8), sin(4.8)), 0.8, 1.8*time);

    return offset;
}

vec3 waterNormal(vec3 worldPos, float time) {
    vec2 derivs  = cosDerivs(0.05, worldPos.xz, vec2(cos(2.8), sin(2.8)), 1.2, 1.8*time);
         derivs += cosDerivs(0.05, worldPos.xz, vec2(cos(4.8), sin(4.8)), 0.8, 1.8*time);

    return normalize(vec3(derivs.x, 1.0, derivs.y));
}