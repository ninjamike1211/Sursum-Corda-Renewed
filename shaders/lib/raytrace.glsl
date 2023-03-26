#ifndef RAYTRACE
#define RAYTRACE

// Code by Belmu (https://gist.github.com/BelmuTM/af0fe99ee5aab386b149a53775fe94a3#file-raytracer-glsl)

// #include "/defines.glsl"
// #include "/spaceConvert.glsl"

/* Dependencies:
uniform sampler2D depthtex1;
*/

#define BINARY_REFINEMENT 1
#define BINARY_COUNT 4
#define BINARY_DECREASE 0.5

#define SSR_THICKNESS 10.0

vec3 diag3(mat4 mat) { return vec3(mat[0].x, mat[1].y, mat[2].z);      }
vec3 projMAD3(mat4 mat, vec3 v) { return diag3(mat) * v + mat[3].xyz;  }
float minOf3(vec3 x) { return min(x.x, min(x.y, x.z)); }

// vec3 viewToScreen(vec3 viewPos) {
// 	return (projMAD3(gbufferProjection, viewPos) / -viewPos.z) * 0.5 + 0.5;
// }

// void binarySearch(inout vec3 rayPos, vec3 rayDir, sampler2D depthtex) {
//     for(int i = 0; i < BINARY_COUNT; i++) {
//         rayPos += sign(texture(depthtex, rayPos.xy).r - rayPos.z) * rayDir;
//         // Going back and forth using the delta of the 2 different depths as a parameter for sign()
//         rayDir *= BINARY_DECREASE;
//         // Decreasing the step length (to slowly tend towards the intersection)
//     }
// }

// The favorite raytracer of your favorite raytracer
bool raytrace(vec3 viewPos, vec3 viewRayDir, int stepCount, float jitter, int frameCounter, vec2 screenSize, out vec3 rayPos, sampler2D depthtex, mat4 projectionMatrix) {
    // "out vec3 rayPos" is our ray's position, we use it as an "out" parameter to be able to output both the intersection check and the hit position

    rayPos  = viewToScreen(viewPos, frameCounter, screenSize, projectionMatrix);
    // Starting position in screen space, it's better to perform space conversions OUTSIDE of the loop to increase performance
    vec3 rayDir  = viewToScreen(viewPos + viewRayDir, frameCounter, screenSize, projectionMatrix) - rayPos;
    rayDir *= minOf3((sign(rayDir) - rayPos) / rayDir) * (0.9999 / (stepCount+jitter));
    // Calculating the ray's direction in screen space, we multiply it by a "step size" that depends on a few factors from the DDA algorithm


    // Thanks Bálint#1673 for the fix which prevents ssr errors in close range

    // if (rayDir.z > 0.0) rayDir.z = min(rayDir.z, viewPos.z - EPS); // This was the line used, fixes the clipping issue but breaks SSR
    
    if (viewRayDir.z > 0.0 && viewRayDir.z >= -viewPos.z)
        return false;

    bool intersect = false;
    // Our intersection isn't found by default

    rayPos += rayDir * jitter;
    // We settle the ray's starting point and jitter it
    // Jittering reduces the banding caused by a low amount of steps, it's basically multiplying the direction by a random value (like noise)
    for(int i = 0; i <= stepCount && !intersect; i++, rayPos += rayDir) {
        // Loop until we reach the max amount of steps OR if an intersection is found, add 1 at each iteration AND march the ray (position += direction)

        if(clamp(rayPos.xyz, 0.0, 1.0) != rayPos.xyz) return false;
        // Checking if the ray goes outside of the screen (if clamping the coordinates to [0;1] returns a different value, then we're outside)
        // There's no need to continue ray marching if the ray goes outside of the screen

        float depth         = (texture(depthtex, rayPos.xy).r);
        // Sampling the depth at the ray's position
        // We use depthtex1 to get the depth of all blocks EXCEPT translucents, it's useful for refractions
        float depthLenience = max(abs(rayDir.z) * 3.0, 0.02 / pow(viewPos.z, 2.0));
        // DrDesten's depth lenience factor, it's used as a "threshold" for our intersection's depth

        intersect = abs(depthLenience - (rayPos.z - depth)) < depthLenience && depth >= 0.56;
        // Comparing depths to see if we hit something AND checking if the depth is above 0.56 (= if we didn't intersect the player's hand)

        // intersect = depth < rayPos.z && linearizeDepthFast(depth) + SSR_THICKNESS > linearizeDepthFast(rayPos.z);
    }

    #if BINARY_REFINEMENT == 1
        binarySearch(rayPos, rayDir, depthtex);
        // Binary search for some extra accuracy
    #endif

    // if(texture2D(depthtex1, rayPos.xy).r == 1.0)
    //     intersect = false;

    return intersect;
    // Outputting the boolean
}

// bool raytrace(inout vec3 screenPos, vec3 viewPos, vec3 viewRayDir, int stepCount, float jitter, sampler2D depthtex) {
    
//     // Calculate screen space reflection ray direction
//     vec3 rayDir = viewToScreen(viewPos + viewRayDir) - screenPos;
//     vec3 rayIncrement = rayDir * 0.9999 / stepCount;



// }

// Modified version of raytrace for screen space shadows (contact shadows)
bool shadowRaytrace(vec3 viewPos, vec3 rayDir, int stepCount, float jitter, int frameCounter, vec2 screenSize, sampler2D depthtex, mat4 projectionMatrix) {

    vec3 rayPos  = viewToScreen(viewPos, frameCounter, screenSize, projectionMatrix);
    // Starting position in screen space, it's better to perform space conversions OUTSIDE of the loop to increase performance
    rayDir  = viewToScreen(viewPos + rayDir, frameCounter, screenSize, projectionMatrix) - rayPos;
    rayDir *= minOf3((sign(rayDir) - rayPos) / rayDir) * (0.1 / (stepCount+jitter));
    // Calculating the ray's direction in screen space, we multiply it by a "step size" that depends on a few factors from the DDA algorithm

    bool intersect = false;
    // Our intersection isn't found by default

    rayPos += rayDir * jitter;
    // We settle the ray's starting point and jitter it
    // Jittering reduces the banding caused by a low amount of steps, it's basically multiplying the direction by a random value (like noise)
    for(int i = 0; i <= stepCount && !intersect; i++, rayPos += rayDir) {
        // Loop until we reach the max amount of steps OR if an intersection is found, add 1 at each iteration AND march the ray (position += direction)

        if(clamp(rayPos.xy, 0.0, 1.0) != rayPos.xy) return false;
        // Checking if the ray goes outside of the screen (if clamping the coordinates to [0;1] returns a different value, then we're outside)
        // There's no need to continue ray marching if the ray goes outside of the screen

        float depth         = (texture(depthtex, rayPos.xy).r);
        // Sampling the depth at the ray's position
        // We use depthtex to get the depth of all blocks EXCEPT translucents, it's useful for refractions
        float depthLenience = max(abs(rayDir.z) * 3.0, 0.02 / pow(viewPos.z, 2.0));

        intersect = abs(depthLenience - (rayPos.z - depth)) < depthLenience && depth >= 0.56;
        // Comparing depths to see if we hit something AND checking if the depth is above 0.56 (= if we didn't intersect the player's hand)

        if(intersect) {
            binarySearch(rayPos, rayDir, depthtex);

            float depth         = (texture(depthtex, rayPos.xy).r);
            // Sampling the depth at the ray's position
            // We use depthtex to get the depth of all blocks EXCEPT translucents, it's useful for refractions
            // float depthLenience = max(abs(rayDir.z) * 3.0, 0.02 / pow(viewPos.z, 2.0));

            // intersect = abs(depthLenience - (rayPos.z - depth)) < depthLenience && depth >= 0.56;
            // Comparing depths to see if we hit something AND checking if the depth is above 0.56 (= if we didn't intersect the player's hand)

            intersect = abs((rayPos.z - depth)) < 0.001;
        }


    }

    return intersect;
    // Outputting the boolean
}

#endif