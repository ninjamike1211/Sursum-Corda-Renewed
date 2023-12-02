
// // Performs a backwards raytrace to the find the nearest edge to a tangent position given a trace direction
// void traceToEdge(inout vec3 tangentPos, vec3 traceDir, vec4 textureBounds, ivec2 atlasSize, mat2 dFdXY) {

//     // Get size of texel in atlas space
//     vec2 texelSize = 1.0 / atlasSize;

//     // Get the upper and lower bounds for the current texel
//     vec2 lowerBounds = tangentPos.xy - mod(tangentPos.xy, texelSize);
//     vec2 upperBounds = lowerBounds + texelSize;
//     float heightmapBound = textureGrad(normals, tangentPos.xy, dFdXY[0], dFdXY[1]).a;

//     float heightmapDiff = tangentPos.z - heightmapBound;

//     if(heightmapDiff > -0.0 / 50) {
//         traceDir /= -traceDir.z;
//         traceDir.xy *= (textureBounds.zw - textureBounds.xy);

//         // tangentPos += traceDir * heightmapDiff;
//         // wrapTexcoord(tangentPos.xy, textureBounds);
//     }
//     else {
//         // Z normalize inverse trace direction since we are raytracing in 2D
//         // vec2 tangentDir = -normalize(traceDir.xy);
//         traceDir /= -length(traceDir.xy);
//         traceDir.xy *= (textureBounds.zw - textureBounds.xy);
//         // traceDir.xy = normalize(traceDir.xy);

//         vec2 t0 = (lowerBounds - tangentPos.xy) / traceDir.xy;
//         vec2 t1 = (upperBounds - tangentPos.xy) / traceDir.xy;
//         float t2 = (heightmapBound - tangentPos.z) / traceDir.z;
//         float tmax = min(max(t0.x, t1.x), max(t0.y, t1.y));

//         if(sign(t2) == 1.0)
//             tmax = min(t2, tmax);

//         tangentPos += traceDir * tmax;
//         // tangentPos.xy += traceDir.xy * tmax;

//         #ifdef gbuffersTextured
//             testOut = vec4(tmax * atlasSize.x);
//         #endif

//         wrapTexcoord(tangentPos.xy, textureBounds);
//     }
// }

// // Performs a backwards raytrace to the find the nearest edge to a tangent position given a trace direction
// // Assumes that traceDir.z < 0.0, i.e. the trace vector is going into the block
// void traceToEdge(inout vec3 tangentPos, vec3 traceDir, vec4 textureBounds, ivec2 atlasSize, mat2 dFdXY) {

//     // Get size of texel in atlas space
//     vec2 texelSize = 1.0 / atlasSize;

//     // Scale trace direction to account for scale of texture atlas
//     // traceDir *= -1;
//     vec3 rayDir = -traceDir;
//     // rayDir.xy *= textureBounds.zw - textureBounds.xy;
//     rayDir.xy *= textureBounds.zw - textureBounds.xy;
//     // rayDir = normalize(rayDir);
//     // traceDir = -traceDir;
//     vec3 invRayDir = 1.0 / rayDir;
//     vec3 raySign = sign(rayDir);

//     // Get heightmap value
//     float heightmapBound = textureGrad(normals, tangentPos.xy, dFdXY[0], dFdXY[1]).a;

//     // Compute distances to 3 bounding planes
//     vec3 dists;
//     // dists.xy = mod(tangentPos.xy, texelSize) * -raySign.xy + (texelSize * (raySign.xy * 0.5 + 0.5));
//     dists.xy = -mod(tangentPos.xy, texelSize) + (texelSize * (raySign.xy * 0.5 + 0.5));
//     // dists.x = (raySign.x == -1.0) ? (mod(tangentPos.x, texelSize.x)) : (texelSize.x - mod(tangentPos.x, texelSize.x));
//     // dists.y = (raySign.y == -1.0) ? (mod(tangentPos.y, texelSize.y)) : (texelSize.y - mod(tangentPos.y, texelSize.y));
//     dists.z  = 1000.0 * (heightmapBound - tangentPos.z);
//     // dists *= abs(invTraceDir);
//     dists *= invRayDir;


//     // bvec3 hits = bvec3(
//     //     mod(tangentPos.y, texelSize.y) == mod(tangentPos.y + traceDir.y * dists.x, texelSize.y) && (tangentPos.z + traceDir.z * dists.x) < heightmapBound,
//     //     mod(tangentPos.x, texelSize.x) == mod(tangentPos.x + traceDir.x * dists.y, texelSize.x) && (tangentPos.z + traceDir.z * dists.y) < heightmapBound,
//     //     mod(tangentPos.xy, texelSize) == mod(tangentPos.xy + traceDir.xy * dists.z, texelSize)
//     // );

//     // tangentPos += traceDir * (hits.x ? dists.x : (hits.y ? dists.y : dists.z));

//     vec3 hits = vec3(bvec3(
//         dists.x < dists.y && dists.x < dists.z,
//         dists.y < dists.x && dists.y < dists.z,
//         dists.z < dists.x && dists.z < dists.y
//     ));

//     tangentPos += rayDir * min(min(dists.x, dists.y), dists.z);
//     // tangentPos += traceDir * min(dists.x, dists.y);
//     // tangentPos += traceDir * dists.z;

//     #ifdef gbuffersTextured
//         // testOut = vec4(dists, 1.0);
//         // testOut = vec4(vec3(min(dists.x, dists.y, dists.z)), 1.0);
//         // testOut = vec4((tangentPos.xy - textureBounds.xy) / (textureBounds.zw - textureBounds.xy), 0.0, 1.0);
//         // testOut = vec4(0.0, tangentPos.z, 1.0);

//         testOut = vec4(hits, 1.0);
//     #endif

//     wrapTexcoord(tangentPos.xy, textureBounds);
// }

// // Performs a backwards raytrace to the find the nearest edge to a tangent position given a trace direction
// // Assumes that traceDir.z < 0.0, i.e. the trace vector is going into the block
// vec2 traceToEdge(inout vec3 tangentPos, vec3 traceDir, int stepCount, vec4 textureBounds, ivec2 atlasSize, mat2 dFdXY) {

//     // Get size of texel in atlas space
//     vec2 texelSize = 1.0 / atlasSize;

//     vec3 hits = vec3(0.0);
//     vec2 samplePos = texelSize * floor(tangentPos.xy/texelSize) + 0.5 * texelSize;

//     // Check if the current position is at the top of the heightmap
//     float heightmapBound = textureGrad(normals, samplePos, dFdXY[0], dFdXY[1]).a;
//     float diff = tangentPos.z - heightmapBound;

//     if(diff >= -0.999999 / stepCount) {
//         tangentPos -= traceDir / traceDir.z * diff * 1.0001;
//         wrapTexcoord(tangentPos.xy, textureBounds);
//         hits.z = 1.0;

//         #ifdef gbuffersTextured
//             testOut = vec4(hits, 1.0);
//             // testOut = vec4((samplePos - textureBounds.xy) / (textureBounds.zw - textureBounds.xy), 0.0, 1.0);
//         #endif

//         return samplePos;
//     }

//     // Scale trace direction to account for scale of texture atlas
//     vec3 rayDir = -traceDir / length(traceDir.xy);
//     // rayDir.xy *= 0.25 * (textureBounds.zw - textureBounds.xy);
    
//     vec2 invRayDir = 1.0 / rayDir.xy;
//     vec2 raySign = sign(rayDir.xy);

//     for(int i = 0; i < 1; i++) {
//         // Compute distances to 2 bounding planes
//         vec2 dists = -mod(tangentPos.xy, texelSize) + (texelSize * (raySign.xy * 0.5 + 0.5));
//         dists *= invRayDir;

//         tangentPos += rayDir * min(dists.x, dists.y);
//         samplePos += raySign * texelSize * vec2(step(dists.x, dists.y), step(dists.y, dists.x));
//         wrapTexcoord(samplePos, textureBounds);

//         float heightmapBound = textureGrad(normals, samplePos, dFdXY[0], dFdXY[1]).a;
//         heightmapBound -= mod(heightmapBound, 1.0 / stepCount);
//         if(tangentPos.z - heightmapBound >= -0.0 / stepCount) {
//             if(dists.x < dists.y)
//                 hits.x = 1.0;
//             else
//                 hits.y = 1.0;

//             samplePos -= raySign * texelSize * vec2(step(dists.x, dists.y), step(dists.y, dists.x));
//             wrapTexcoord(samplePos, textureBounds);

//             break;
//         }

//     }
//     wrapTexcoord(tangentPos.xy, textureBounds);

//     #ifdef gbuffersTextured
//         testOut = vec4(hits, 1.0);
//         // testOut = vec4((samplePos - textureBounds.xy) / (textureBounds.zw - textureBounds.xy), 0.0, 1.0);
//     #endif

//     return samplePos;
// }