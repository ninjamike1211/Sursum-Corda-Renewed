#version 430 compatibility

// uniform float viewWidth;
// uniform float viewHeight;
// uniform vec3 skyColor;
// uniform vec3 cameraPosition;
// uniform mat4 gbufferProjectionInverse;
// uniform mat4 gbufferModelView;
// uniform mat4 gbufferModelViewInverse;

in vec4 starData;

layout(location = 0) out vec4 color;

void main() {
    if(starData.a > 0.5)
        discard;
    color = vec4(0.0);

    // color = skyColor;

    // vec2 screenPos = gl_FragCoord.xy / vec2(viewWidth, viewHeight) * 2.0 - 1.0;
    // vec4 viewPosTemp = gbufferProjectionInverse * vec4(screenPos, 1.0, 1.0);
    // vec3 viewDir = normalize(viewPosTemp.xyz / viewPosTemp.w);
    
    // // vec4 playerPos = gbufferModelViewInverse * vec4(viewDir, 1.0);
    // vec3 playerPos = mat3(gbufferModelViewInverse) * viewDir;

    // // playerPos.y -= 70 - cameraPosition.y;
    // vec3 yNormalizedPlayerPos = playerPos.xyz / playerPos.y;
    // yNormalizedPlayerPos -= yNormalizedPlayerPos * (256 - cloudHeight + cameraPosition.y) / 256.0;
    // yNormalizedPlayerPos += cameraPosition / 256.0;

    // if(abs(yNormalizedPlayerPos.x) < 1.0 && abs(yNormalizedPlayerPos.z) < 1.0 && sign(cloudHeight - cameraPosition.y) * playerPos.y >= 0.0) {
    //     color = vec3(1.0);
    //     gl_FragDepth = -1.0;
    // }
    // else {
    //     color = vec3(0.0);
    //     gl_FragDepth = 1.0;
    // }

    // color = playerPos.xyz;
    // color = vec3(dot(pos.xyz, gbufferModelView[1].xyz));
}