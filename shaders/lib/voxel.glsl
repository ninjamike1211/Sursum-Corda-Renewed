#ifndef VOXEL_GLSL
#define VOXEL_GLSL

// #define Voxel_PerVertex
// #define Floodfill_PerPixel

ivec3 sceneToVoxel(vec3 scenePos, vec3 cameraPosition) {
    return ivec3(scenePos + vec3(256.0 + fract(cameraPosition.x), 64.0 + cameraPosition.y, 256.0 + fract(cameraPosition.z)));
}

vec3 sceneToVoxelSmooth(vec3 scenePos, vec3 cameraPosition) {
    return vec3(scenePos + vec3(256.0 + fract(cameraPosition.x), 64.0 + cameraPosition.y, 256.0 + fract(cameraPosition.z))) / vec3(512.0, 384.0, 512.0);
}

vec3 sceneToVoxelVertex(vec3 scenePos, vec3 cameraPosition) {
    return vec3(scenePos + vec3(256.5 + fract(cameraPosition.x), 64.5 + cameraPosition.y, 256.5 + fract(cameraPosition.z))) / vec3(512.0, 384.0, 512.0);
}

#endif