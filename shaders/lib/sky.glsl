

vec3 getSkyColor(vec3 sceneDir, vec3 sunPosition, float sunAngle, mat4 modelViewInverseMatrix) {

    vec3 sunDir = mat3(modelViewInverseMatrix) * normalize(sunPosition);
    float sunDot = dot(sceneDir, sunDir);

    vec3 sunColor = vec3(0.13, 0.09, 0.00);
    vec3 moonColor = vec3(0.1);

    vec3 horizonColor = vec3(0.3, 0.45, 0.9) * max(sin(sunAngle * TAU), 0.0);
    vec3 skyTopColor  = vec3(0.2, 0.3, 0.75) * max(sunDir.y, 0.0);

    vec3 color = vec3(0.0);
    color += sunColor * smootherstep(0.5, 1.0, sunDot) * smootherstep(-0.3, 0.0, sceneDir.y);
    color += moonColor * smootherstep(0.5, 1.0, -sunDot) * smootherstep(-0.3, 0.0, sceneDir.y);
    color += horizonColor * smootherstep(0.7, 0.0, sceneDir.y) * (smootherstep(-0.3, 0.0, sceneDir.y) * 0.55 + 0.45);
    color += skyTopColor * smootherstep(0.0, 0.7, sceneDir.y);

    return color;
}