
// Wraps a texcoord value to stay within given bounds
void wrapTexcoord(inout vec2 texcoord, vec4 textureBounds) {
    vec2 texSize = (textureBounds.zw - textureBounds.xy);
    texcoord -= floor((texcoord - textureBounds.xy) / texSize) * texSize;
}

// Wraps a texcoord value to stay within given bounds
void wrapTexcoord(inout vec2 texcoord, vec4 textureBounds, bvec4 discardEdges, inout bool wrappedEdge) {
    #ifdef Parallax_DiscardEdge
        vec2 texSize = (textureBounds.zw - textureBounds.xy);
        vec2 offset = floor((texcoord - textureBounds.xy) / texSize) * texSize;

        if(!wrappedEdge) {
            if(discardEdges.x && sign(offset.x) == 1.0)
                discard;
            if(discardEdges.y && sign(offset.x) == -1.0)
                discard;
            if(discardEdges.z && sign(offset.y) == -1.0)
                discard;
            if(discardEdges.w && sign(offset.y) == 1.0)
                discard;
        }

        texcoord -= offset;
        
        if(any(notEqual(offset, vec2(0.0))))
            wrappedEdge = true;
    #else
        vec2 texSize = (textureBounds.zw - textureBounds.xy);
        texcoord -= floor((texcoord - textureBounds.xy) / texSize) * texSize;
    #endif
}

#ifdef gbuffersTextured
// Wraps a texcoord value to stay within given bounds
void wrapTexcoord(inout vec2 texcoord, vec4 textureBounds, mat3 tbn, inout ivec3 voxelPos, inout bool discardBlocked) {
    #ifdef Parallax_DiscardEdge
        vec2 texSize = (textureBounds.zw - textureBounds.xy);
        vec2 offset = floor((texcoord - textureBounds.xy) / texSize) * texSize;

        if(clamp(texcoord, textureBounds.xy, textureBounds.zw) != texcoord) {
            
            if(!discardBlocked) {
                if(sign(offset.x) != 0.0) {
                    if(sign(offset.x) == 1.0) {
                        voxelPos += ivec3(round(tbn[0]));
                        texcoord.x -= offset.x;
                    }
                    else if(sign(offset.x) == -1.0) {
                        voxelPos -= ivec3(round(tbn[0]));
                        texcoord.x -= offset.x;
                    }

                    if(imageLoad(voxelImage, voxelPos).r == 0) {
                        if(imageLoad(voxelImage, voxelPos + ivec3(round(tbn[2]))).r == 0)
                            discard;
                        else
                            discardBlocked = true;
                    }
                }

                if(!discardBlocked && sign(offset.y) != 0.0) {
                    if(sign(offset.y) == 1.0) {
                        voxelPos += ivec3(round(tbn[1]));
                        texcoord.y -= offset.y;
                    }
                    else if(sign(offset.y) == -1.0) {
                        voxelPos -= ivec3(round(tbn[1]));
                        texcoord.y -= offset.y;
                    }

                    if(imageLoad(voxelImage, voxelPos).r == 0) {
                        if(imageLoad(voxelImage, voxelPos + ivec3(round(tbn[2]))).r == 0)
                            discard;
                        else
                            discardBlocked = true;
                    }
                }

                discardBlocked = true;
            }
            else {
                texcoord -= offset;
            }
        }
    #else
        vec2 texSize = (textureBounds.zw - textureBounds.xy);
        texcoord -= floor((texcoord - textureBounds.xy) / texSize) * texSize;
    #endif
}
#endif

// Performs a raymarch algorithm on the normals heightmap
// with a given direction in tangent space and given step count
vec3 heightmapMarch(vec3 tangentPos, vec3 traceDir, int stepCount, bvec4 discardEdges, vec4 textureBounds, mat2 dFdXY) {

    bool wrappedEdge = false;

    vec3 deltaPos;
    deltaPos.xy = traceDir.xy / abs(traceDir.z) / stepCount * (textureBounds.zw - textureBounds.xy) * 0.25;
    deltaPos.z = sign(traceDir.z) / stepCount;

    vec3 nextTangentPos = tangentPos;

    for(int i = 0; i < stepCount; i++) {
        float heightmapSample = textureGrad(normals, nextTangentPos.xy, dFdXY[0], dFdXY[1]).a;

        if(heightmapSample >= nextTangentPos.z)
            break;

        tangentPos = nextTangentPos;
        nextTangentPos += deltaPos;
        wrapTexcoord(nextTangentPos.xy, textureBounds, discardEdges, wrappedEdge);
    }

    return tangentPos;
}


#ifdef gbuffersTextured
// Performs a raymarch algorithm on the normals heightmap
// with a given direction in tangent space and given step count
vec3 heightmapMarch(vec3 tangentPos, vec3 traceDir, int stepCount, ivec3 voxelPos, mat3 tbn, vec4 textureBounds, mat2 dFdXY) {

    bool discardBlocked = false;

    vec3 deltaPos;
    deltaPos.xy = traceDir.xy / abs(traceDir.z) / stepCount * (textureBounds.zw - textureBounds.xy) * 0.25;
    deltaPos.z = sign(traceDir.z) / stepCount;

    vec3 nextTangentPos = tangentPos;

    for(int i = 0; i < stepCount; i++) {
        float heightmapSample = textureGrad(normals, nextTangentPos.xy, dFdXY[0], dFdXY[1]).a;

        if(heightmapSample >= nextTangentPos.z)
            break;

        tangentPos = nextTangentPos;
        nextTangentPos += deltaPos;
        wrapTexcoord(nextTangentPos.xy, textureBounds, tbn, voxelPos, discardBlocked);
    }

    return tangentPos;
}
#endif

// Performs a raymarch algorithm on the normals heightmap
// with a given direction in tangent space and given step count
vec3 heightmapMarch(vec3 tangentPos, vec3 traceDir, int stepCount, bool skipFirstCheck, vec4 textureBounds, mat2 dFdXY) {

    float layerDepth = 1.0 / stepCount;

    vec3 deltaPos;
    // deltaPos.xy = traceDir.xy / abs(traceDir.z) * (textureBounds.zw - textureBounds.xy) * layerDepth * Parallax_Depth * 0.25;
    deltaPos.xy = traceDir.xy / abs(traceDir.z) * layerDepth;
    deltaPos.z = sign(traceDir.z) * layerDepth;

    float heightmapSample = 1.0;
    float previousHeightmapSample = 1.0;

    for(int i = 0; i < stepCount; i++) {

        heightmapSample = textureGrad(normals, tangentPos.xy, dFdXY[0], dFdXY[1]).a;

        if((i > 0 || !skipFirstCheck) && heightmapSample >= tangentPos.z)
            break;
        
        tangentPos += deltaPos;
        wrapTexcoord(tangentPos.xy, textureBounds);
        previousHeightmapSample = heightmapSample;
    }

    return tangentPos;
}

// Performs a backwards raytrace to the find the nearest edge to a tangent position given a trace direction
// Assumes that traceDir.z < 0.0, i.e. the trace vector is going into the block
vec2 traceToEdge(inout vec3 tangentPos, vec3 traceDir, int stepCount, vec4 textureBounds, ivec2 atlasSize, mat2 dFdXY, out vec3 normal) {

    // Get size of texel in atlas space
    vec2 texelSize = 1.0 / atlasSize;

    vec3 hits = vec3(0.0);
    vec2 samplePos = texelSize * floor(tangentPos.xy/texelSize) + 0.5 * texelSize;
    vec2 prevSamplePos = samplePos;

    // Check if the current position is at the top of the heightmap
    float heightmapBound = textureGrad(normals, samplePos, dFdXY[0], dFdXY[1]).a;
    // heightmapBound -= mod(heightmapBound, 1.0 / stepCount);
    
    vec3 rayDir = -traceDir;
    vec3 invRayDir = 1.0 / rayDir;
    vec3 raySign = sign(rayDir);

    for(int i = 0; i < 3; i++) {
        // Compute distances to 2 bounding planes
        vec3 dists;

        if(i == 0)
            dists.xy = -mod(tangentPos.xy, texelSize) + (texelSize * (raySign.xy * 0.5 + 0.5));
        else
            dists.xy = mix(-mod(tangentPos.xy, texelSize) + (texelSize * (raySign.xy * 0.5 + 0.5)), texelSize * raySign.xy, hits.xy);

        
        dists.z = heightmapBound - tangentPos.z;
        dists *= invRayDir;

        // if(dists.z < 0.0) {
        //     hits = vec3(1.0);
        //     break;
        // }

        float minDist = min(min(dists.x, dists.y), dists.z);
        tangentPos += rayDir * minDist;

        // If we hit the top, break and we are done
        if(dists.z < min(dists.x, dists.y)) {
            hits = vec3(0.0, 0.0, 1.0);
            // tangentPos += rayDir * minDist * 0.01;

            break;
        }

        // We hit a side, check next texel
        prevSamplePos = samplePos;
        samplePos += raySign.xy * texelSize * vec2(step(dists.x, dists.y), step(dists.y, dists.x));
        wrapTexcoord(samplePos, textureBounds);

        heightmapBound = textureGrad(normals, samplePos, dFdXY[0], dFdXY[1]).a;
        // heightmapBound -= mod(heightmapBound, 1.0 / stepCount);

        if(dists.x < dists.y)
            hits = vec3(1.0, 0.0, 0.0);
        else
            hits = vec3(0.0, 1.0, 0.0);

        // Check if we hit a side that is exposed
        if(tangentPos.z - heightmapBound >= -0.0 / stepCount) {
            samplePos = prevSamplePos;
            // tangentPos += rayDir * minDist * 0.1;

            break;
        }

    }
    wrapTexcoord(tangentPos.xy, textureBounds);

    #ifdef gbuffersTextured
        // testOut = vec4(hits, 1.0);
        // testOut = vec4((samplePos - textureBounds.xy) / (textureBounds.zw - textureBounds.xy), 0.0, 1.0);
    #endif

    normal = hits * raySign;

    return samplePos;
}


void parallax(inout vec3 tangentPos, vec3 scenePos, mat3 tbn, bvec4 discardEdges, vec4 textureBounds, mat2 dFdXY) {
    vec3 tangentDir = normalize(scenePos) * tbn;
    // vec3 tangentPos = vec3(texcoord, 1.0);

    tangentPos = heightmapMarch(tangentPos, tangentDir, 50, discardEdges, textureBounds, dFdXY);

    // texcoord = tangentPos.xy;
}

float parallaxWithShadows(inout vec3 tangentPos, vec3 scenePos, vec3 lightDir, mat3 tbn, bvec4 discardEdges, vec4 textureBounds, mat2 dFdXY) {
    vec3 tangentDir = normalize(scenePos) * tbn;
    // vec3 tangentPos = vec3(texcoord, 1.0);

    tangentPos = heightmapMarch(tangentPos, tangentDir, 50, discardEdges, textureBounds, dFdXY);

    if(tangentPos.z < 1.0) {
        // texcoord = tangentPos.xy;

        vec3 tangentLightDir = lightDir * tbn;

        vec3 shadowTangentPos = heightmapMarch(tangentPos, tangentLightDir, 50, bvec4(false), textureBounds, dFdXY);
        // vec3 shadowTangentPos = tangentPos;

        return step(1.0, shadowTangentPos.z);
        // return shadowTangentPos.z;
    }
    else {
        return 1.0;
    }
}


#ifdef gbuffersTextured
float parallaxWithShadows(inout vec3 tangentPos, vec3 scenePos, vec3 lightDir, mat3 tbn, ivec3 voxelPos, vec4 textureBounds, mat2 dFdXY) {
    vec3 tangentDir = normalize(scenePos) * tbn;
    // vec3 tangentPos = vec3(texcoord, 1.0);

    tangentPos = heightmapMarch(tangentPos, tangentDir, 50, voxelPos, tbn, textureBounds, dFdXY);

    if(tangentPos.z < 1.0) {
        // texcoord = tangentPos.xy;

        vec3 tangentLightDir = lightDir * tbn;

        vec3 shadowTangentPos = heightmapMarch(tangentPos, tangentLightDir, 50, bvec4(false), textureBounds, dFdXY);
        // vec3 shadowTangentPos = tangentPos;

        return step(1.0, shadowTangentPos.z);
        // return shadowTangentPos.z;
    }
    else {
        return 1.0;
    }
}
#endif

float parallax(inout vec3 tangentPos, out vec2 texcoord, out vec3 normal, vec3 scenePos, vec3 lightDir, mat3 tbn, vec4 textureBounds, ivec2 atlasSize, mat2 dFdXY) {
    vec3 tangentDir = normalize(scenePos) * tbn;
    tangentDir.xy *= textureBounds.zw - textureBounds.xy;
    tangentDir.z /= Parallax_Depth * 0.25;
    tangentDir = normalize(tangentDir);

    tangentPos = heightmapMarch(tangentPos, tangentDir, 50, false, textureBounds, dFdXY);

    texcoord = tangentPos.xy;
    normal = vec3(0.0, 0.0, 1.0);

    if(tangentPos.z < 1.0) {

        #ifdef Parallax_TraceToEdge
            texcoord = traceToEdge(tangentPos, tangentDir, 50, textureBounds, atlasSize, dFdXY, normal);
        #endif

        #ifdef Parallax_Shadows
            vec3 tangentLightDir = lightDir * tbn;
            tangentLightDir.xy *= textureBounds.zw - textureBounds.xy;
            tangentLightDir.z /= Parallax_Depth * 0.25;
            tangentLightDir = normalize(tangentLightDir);

            vec3 shadowTangentPos = heightmapMarch(tangentPos, tangentLightDir, 50, true, textureBounds, dFdXY);

            return step(1.0, shadowTangentPos.z);
        #else
            return 1.0;
        #endif
    }
    else {
        return 1.0;
    }
}

void parallaxApplyDepthOffset(vec3 tangentPos, vec3 scenePos, vec2 texcoord, mat3 tbn, mat4 modelViewMatrix, mat4 projectionMatrix) {
    vec3 texDir = normalize(scenePos) * tbn;
    scenePos -= tbn * (texDir / texDir.z) * (1.0 - tangentPos.z) * Parallax_Depth * 0.25;
    vec3 viewPos = (modelViewMatrix * vec4(scenePos, 1.0)).xyz;
    vec3 screenPos = projectAndDivide(projectionMatrix, viewPos) * 0.5 + 0.5;

    gl_FragDepth = screenPos.z;
}

float parallaxShadowDist(vec3 tangentPos, vec3 lightDir, mat3 tbn) {
    vec3 lightDirTbn = lightDir * tbn;
    vec3 lightDiff = lightDirTbn / lightDirTbn.z * (1.0 - tangentPos.z) * Parallax_Depth * 0.25;
    return length(lightDiff);
}