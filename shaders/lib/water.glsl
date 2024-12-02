
float cosOffset(float amp, vec2 pos, vec2 angle, float posMult, float offset) {
    return amp * cos(posMult*dot(pos, angle) + offset);
}

vec2 cosDerivs(float amp, vec2 pos, vec2 angle, float posMult, float offset) {
    float derivX = amp * posMult * angle.x * sin(posMult*dot(pos, angle) + offset);
    float derivY = amp * posMult * angle.y * sin(posMult*dot(pos, angle) + offset);

    return vec2(derivX, derivY);
}

float waterOffset(vec3 worldPos, float time) {
    float offset  = cosOffset(0.6, worldPos.xz, vec2(cos(2.8), sin(2.8)), 0.5, 1.1*time);
          offset += cosOffset(0.4, worldPos.xz, vec2(cos(4.8), sin(4.8)), 0.7, 1.6*time);

    return Water_Height * Water_VertexHeightMult * offset;
}

vec3 waterNormal(vec3 worldPos, float time) {
    vec2 derivs  = cosDerivs(0.6,   worldPos.xz, vec2(cos(2.8), sin(2.8)), 0.5, 1.1*time);
         derivs += cosDerivs(0.4,   worldPos.xz, vec2(cos(4.8), sin(4.8)), 0.7, 1.6*time);
         derivs += cosDerivs(0.04,  worldPos.xz, vec2(cos(0.8), sin(0.8)), 2.0, 2.8*time);
         derivs += cosDerivs(0.02, worldPos.xz, vec2(cos(1.8), sin(1.8)), 4.0, 3.8*time);
         derivs += cosDerivs(0.01, worldPos.xz, vec2(cos(3.8), sin(3.8)), 6.5, 4.8*time);
         derivs += cosDerivs(0.01, worldPos.xz, vec2(cos(4.8), sin(5.8)), 8.8, 5.8*time);

    derivs *= Water_Height;

    return normalize(vec3(derivs.x, 1.0, derivs.y));
}