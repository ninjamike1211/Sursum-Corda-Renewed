#ifndef WATER
#define WATER

/*  
 *  Requirements:
 *  include "noise.glsl"
 */ 

// #include "defines.glsl"

const vec2 waveDirs[] = vec2[] (
#if Water_Direction == 0
    vec2(-0.65364, -0.75680),
    vec2(0.26749, 0.96355),
    vec2(-0.84810, -0.52983),
    vec2(0.90044, 0.43496),
    vec2(0.92747, -0.37387)
#elif Water_Direction == 1
    vec2(-0.65364, -0.75680),
    vec2(-0.26749, -0.96355),
    vec2(-0.84810, -0.52983),
    vec2(-0.90044, -0.43496),
    vec2(-0.92747, -0.37387)
#elif Water_Direction == 2
    vec2(-0.65364, 0.75680),
    vec2(-0.26749, 0.96355),
    vec2(-0.84810, 0.52983),
    vec2(-0.90044, 0.43496),
    vec2(-0.92747, 0.37387)
#elif Water_Direction == 3
    vec2(0.65364, -0.75680),
    vec2(0.26749, -0.96355),
    vec2(0.84810, -0.52983),
    vec2(0.90044, -0.43496),
    vec2(0.92747, -0.37387)
#elif Water_Direction == 4
    vec2(0.65364, 0.75680),
    vec2(0.26749, 0.96355),
    vec2(0.84810, 0.52983),
    vec2(0.90044, 0.43496),
    vec2(0.92747, 0.37387)
#endif
);

float waveFunction(vec2 pos, float time, float amplitude, float frequency, float speed, vec2 direction) {
    return amplitude * (sin(dot(pos, direction) * frequency + time * speed) + 1.0) / 2.0;
}

vec2 waveFunctionDeriv(vec2 pos, float time, float amplitude, float frequency, float speed, vec2 direction) {
    float partialX = direction.x * frequency * amplitude * cos(dot(pos, direction) * frequency + time * speed);
    float partialZ = direction.y * frequency * amplitude * cos(dot(pos, direction) * frequency + time * speed);

    return 0.5 * Water_Depth * vec2(partialX, partialZ);
}

float waterHeightFuncSimple(vec2 horizontalPos, float frameTimeCounter) {

    float offset  = 0.20  * SimplexPerlin2D( vec2(1.0)  * (horizontalPos + vec2( 0.62,  0.82 ) * frameTimeCounter));
          offset += 0.25  * SimplexPerlin2D( vec2(0.5)  * (horizontalPos + vec2( 1.53, -0.26 ) * frameTimeCounter));
          offset += 0.30  * SimplexPerlin2D( vec2(0.4)  * (horizontalPos + vec2(-1.74,  0.78 ) * frameTimeCounter));

    return offset * 0.5 + 0.5;
}

float waterHeightFunc(vec2 horizontalPos, float frameTimeCounter) {

    float offset  = 0.05  * Cellular2D(      vec2(3.0)  * (horizontalPos + vec2(-0.30,  1.16 ) * frameTimeCounter));
          offset += 0.07  * Cellular2D(      vec2(2.5)  * (horizontalPos + vec2( 0.18, -1.26 ) * frameTimeCounter));
          offset += 0.08  * Cellular2D(      vec2(2.0)  * (horizontalPos + vec2( 0.78,  0.34 ) * frameTimeCounter));
          offset += 0.10  * Cellular2D(      vec2(1.5)  * (horizontalPos + vec2(-1.04, -0.74 ) * frameTimeCounter));
          offset += 0.20  * SimplexPerlin2D( vec2(1.0)  * (horizontalPos + vec2( 0.62,  0.82 ) * frameTimeCounter));
          offset += 0.25  * SimplexPerlin2D( vec2(0.5)  * (horizontalPos + vec2( 1.53, -0.26 ) * frameTimeCounter));
          offset += 0.30  * SimplexPerlin2D( vec2(0.4)  * (horizontalPos + vec2(-1.74,  0.78 ) * frameTimeCounter));

    return offset * 0.5 + 0.5;
}

float waterHeightSimple(vec2 horizontalPos, float frameTimeCounter) {

    float offset = waterHeightFuncSimple(horizontalPos, frameTimeCounter);

    return (offset * Water_Depth + (1-Water_Depth));
}

float waterHeight(vec2 horizontalPos, float frameTimeCounter) {

    float offset = waterHeightFunc(horizontalPos, frameTimeCounter);

    return (offset * Water_Depth + (1-Water_Depth));
}

// vec3 waterNormal(vec3 worldPos, float frameTimeCounter) {

//     // vec2 partials = waveFunctionDeriv(horizontalPos, frameTimeCounter, 0.6, 1, PI / 3.0, waveDirs[0]);
//     // partials += waveFunctionDeriv(horizontalPos, frameTimeCounter, 0.1, 1, PI / 1.25, waveDirs[1]);
//     // partials += waveFunctionDeriv(horizontalPos, frameTimeCounter, 0.1, 2, PI, waveDirs[2]);
//     // partials += waveFunctionDeriv(horizontalPos, frameTimeCounter, 0.1, 4, PI / 0.75, waveDirs[3]);
//     // partials += waveFunctionDeriv(horizontalPos, frameTimeCounter, 0.1, 6, PI / 0.5, waveDirs[4]);
    
//     // #ifdef Water_Noise
//     //     vec4 noiseVal = texture2D(noisetex, 0.05 * horizontalPos + vec2(0.01 * frameTimeCounter));
//     //     return normalize(mix(vec3(0.2 * partials, 1.0), vec3(-Water_Depth, -Water_Depth, 1.0) * (noiseVal.rgb * 2.0 - 1.0), noiseVal.a * 0.2));
//     // #else
//     //     return vec3(Water_Depth * partials, 1.0);
//     // #endif

//     // vec2 partials  = waveFunctionDeriv(horizontalPos, frameTimeCounter, 0.6, 1, PI / 3.0,  waveDirs[0]);
//     //      partials += waveFunctionDeriv(horizontalPos, frameTimeCounter, 0.1, 1, PI / 1.25, waveDirs[1]);
//     //      partials += waveFunctionDeriv(horizontalPos, frameTimeCounter, 0.1, 2, PI,        waveDirs[2]);
//     //      partials += waveFunctionDeriv(horizontalPos, frameTimeCounter, 0.1, 4, PI / 0.75, waveDirs[3]);
//     //      partials += waveFunctionDeriv(horizontalPos, frameTimeCounter, 0.1, 6, PI / 0.5,  waveDirs[4]);

//     // vec2 partials  = waveFunctionDeriv(horizontalPos, frameTimeCounter, 0.6, 1, PI / 3.0,  waveDirs[0]) * sin(frameTimeCounter * 3.0);
//     //      partials += waveFunctionDeriv(horizontalPos, frameTimeCounter, 0.1, 1, PI / 1.25, waveDirs[1]) * sin(frameTimeCounter * 5.0);
//     //      partials += waveFunctionDeriv(horizontalPos, frameTimeCounter, 0.1, 2, PI,        waveDirs[2]) * sin(frameTimeCounter * 0.5);
//     //      partials += waveFunctionDeriv(horizontalPos, frameTimeCounter, 0.1, 4, PI / 0.75, waveDirs[3]) * sin(frameTimeCounter * 0.9);
//     //      partials += waveFunctionDeriv(horizontalPos, frameTimeCounter, 0.1, 6, PI / 0.5,  waveDirs[4]) * sin(frameTimeCounter * 1.0);

//     // vec2 partials  = waveFunctionDeriv(horizontalPos, frameTimeCounter, 1.0, 1.0, 0.1, waveDirs[1]) * sin(frameTimeCounter * 2.0);
//     // vec2 partials = cos(frameTimeCounter) * cos(horizontalPos) * 0.1;

//     // vec2 partials = vec2(0.0);
//     vec2 partials  = 0.10  * Cellular2D_Deriv(      vec2(6.0)  * (worldPos.xz + vec2(-0.15,  0.58 ) * frameTimeCounter * 1.0)).yz;
//          partials += 0.10  * Cellular2D_Deriv(      vec2(6.0)  * (worldPos.xz + vec2( 0.09, -0.63 ) * frameTimeCounter * 1.0)).yz;
//          partials += 0.10  * Cellular2D_Deriv(      vec2(6.0)  * (worldPos.xz + vec2( 0.39,  0.17 ) * frameTimeCounter * 1.0)).yz;
//          partials += 0.10  * Cellular2D_Deriv(      vec2(6.0)  * (worldPos.xz + vec2(-0.52, -0.37 ) * frameTimeCounter * 1.0)).yz;
//          partials += 0.15  * SimplexPerlin2D_Deriv( vec2(3.0)  * (worldPos.xz + vec2( 0.31,  0.41 ) * frameTimeCounter * 1.0)).yz;
//          partials += 0.20  * SimplexPerlin2D_Deriv( vec2(1.5)  * (worldPos.xz + vec2( 0.51, -0.12 ) * frameTimeCounter * 1.5)).yz;
//          partials += 0.25  * SimplexPerlin2D_Deriv( vec2(0.8)  * (worldPos.xz + vec2(-0.58,  0.26 ) * frameTimeCounter * 1.5)).yz;

//     partials *= Water_Depth * 0.0625;

//     return normalize(vec3(partials.xy, 1.0));

//     // vec3 normal = gerstnerWaves_normal(horizontalPos, frameTimeCounter, 1.0, 0.01, 1.0, vec2(1.0, 0.0));

//     // return normal;
// }

// Normal from heightmap function, https://wiki.shaderlabs.org/wiki/Shader_Tricks#Numerical_solutions
vec3 waterNormal(vec3 worldPos, float frameTimeCounter) {

    float stepSize = 0.03;

    vec2 e = vec2(stepSize, 0);
    vec3 px1 = vec3(worldPos.x - e.x, Water_Depth * 0.15 * waterHeightFunc(worldPos.xz - e.xy, frameTimeCounter), worldPos.z - e.y);
    vec3 px2 = vec3(worldPos.x + e.x, Water_Depth * 0.15 * waterHeightFunc(worldPos.xz + e.xy, frameTimeCounter), worldPos.z + e.y);
    vec3 py1 = vec3(worldPos.x - e.y, Water_Depth * 0.15 * waterHeightFunc(worldPos.xz - e.yx, frameTimeCounter), worldPos.z - e.x);
    vec3 py2 = vec3(worldPos.x + e.y, Water_Depth * 0.15 * waterHeightFunc(worldPos.xz + e.yx, frameTimeCounter), worldPos.z + e.x);

    return normalize(cross(px2 - px1, py2 - py1)).xzy * vec3(1.0, 1.0, -1.0);
}

// Parallax Occlusion Mapping, outputs new texcoord with inout parameter and returns texture-alligned depth into texture after POM
// void waterParallaxMapping(inout vec3 worldPos, in vec3 sceneDir) {
    
//     vec2 deltaPos = Water_Depth / Water_POM_Layers * worldPos.xz / worldPos.y;
//     float layerHeight = 1.0;
//     float mapHeight = waterHeight(worldPos.xz);

//     for(int i = 0; i < Water_POM_Layers && layerHeight > mapHeight; i++) {
//         worldPos.xz -= deltaPos;
        
//         layerHeight -= Water_Depth / Water_POM_Layers;
//         mapHeight = waterHeight(worldPos.xz);
//     }
// }


void waterParallaxMapping(inout vec3 worldPos, vec2 texWorldSize, vec3 cameraPosition, float frameTimeCounter) {

    // Variable layer POM
    #ifdef POM_Variable_Layer
        // float layerCount = mix(256, 20, clamp(dot(normal, viewDir), 0.0, 1.0));
        // float layerCount = mix(256, 20, dot(viewDir, vec3(0.0, 0.0, -1.0)));
        float layerCount = Water_POM_Layers;
    #else
        float layerCount = Water_POM_Layers;
    #endif

    // Calculate texture space vectors and deltas used in loop
    float layerDepth = 1.0 / layerCount;
    vec3 playerPos = worldPos - cameraPosition;
    vec2 viewVector = (-playerPos.xz / playerPos.y) / texWorldSize * Water_Depth;
    vec2 deltaPos = viewVector / layerCount;

    // Set up depth varialbes and read initial height map value
    float currentLayerDepth = 0.0;
    float currentDepthMapValue = 1.0 - waterHeightSimple(worldPos.xz, frameTimeCounter);
    float lastDepthMapValue = 0.0;
	
    // loop until the view vector hits the height map
	while(currentLayerDepth < currentDepthMapValue) {

		// shift texture coordinates along direction of view vector
		worldPos.xz += deltaPos;
        currentLayerDepth += layerDepth;

		// get depthmap value at current texture coordinates
        lastDepthMapValue = currentDepthMapValue;
        float currentDepthMapValue = 1.0 - waterHeightSimple(worldPos.xz, frameTimeCounter);
	}

    // Linear Interpolation between last 2 layers
    vec2 prevPos = worldPos.xz - deltaPos;

    float beforeDepth = lastDepthMapValue - currentLayerDepth + layerDepth;
    float afterDepth = currentDepthMapValue - currentLayerDepth;

    float weight = afterDepth / (afterDepth - beforeDepth);
    worldPos.xz = mix(worldPos.xz, prevPos, weight);

    float yOffset = mix(currentDepthMapValue, lastDepthMapValue, weight) * Water_Depth;
    worldPos.y -= yOffset;
}

#endif