#include "/lib/functions.glsl"
#include "/lib/spaceConvert.glsl"

void binarySearch(inout vec3 screenPos, vec3 rayStep, sampler2D depthtex, int stepCount) {
    for(int i = 0; i < stepCount; i++) {
        float depthDiff = texture(depthtex, screenPos.xy).r - screenPos.z;
        screenPos += sign(depthDiff) * rayStep;
        rayStep *= 0.5;
    }
}

bool screenspaceRaymarch(vec3 screenPos, vec3 viewPos, vec3 viewRayDir, int stepCount, int binStepCount, float jitter, out vec3 hitPos, int frameCounter, vec2 screenSize, float near, float far, sampler2D depthtex, mat4 projectionMatrix) {
    
    // Exit if SSR has no chance of hitting
    if (viewRayDir.z > 0.0 && viewRayDir.z >= -viewPos.z)
        return false;

    // Calculate screen space ray direction
    vec3 screenRayDir = viewToScreen(viewPos + viewRayDir, frameCounter, screenSize, projectionMatrix) - screenPos;

    // Scale the ray to reach the edge of the screen, and scale by the step count
    // Pre-scales the ray to reach from the current position to the nearest screen edge
    vec3 screenDelta = screenRayDir * min3((sign(screenRayDir) - screenPos) / screenRayDir) * 0.9999 / (stepCount+jitter);
    // vec3 screenDelta = screenRayDir * 0.9999 / (stepCount+jitter);

    screenPos += screenDelta * jitter;

    // Iterate over the ray in equal lengthed increments
    for(int i = 0; i < stepCount; i++, screenPos += screenDelta) {

        // if(i < 10)
        //     continue;

        // Check that we haven't exited the sceenspace bounds
        if(clamp(screenPos.xyz, 0.0, 1.0) != screenPos.xyz) return false;

        // Sample the depth map at the current position
        float depth = texture(depthtex, screenPos.xy).r;

        // DrDesten's depth lenience factor, it's used as a "threshold" for our intersection's depth
        float depthLenience = max(abs(screenDelta.z) * 3.0, 0.02 / pow(viewPos.z, 2.0));

        if(abs(depthLenience - (screenPos.z - depth)) < depthLenience && depth >= 0.56) {
            binarySearch(screenPos, screenDelta, depthtex, binStepCount);
            hitPos = screenPos;
            return true;
        }
    }

    return false;
}


#define SSR_BinarySteps 16

vec3 diag3(mat4 mat) { return vec3(mat[0].x, mat[1].y, mat[2].z);      }
vec3 projMAD3(mat4 mat, vec3 v) { return diag3(mat) * v + mat[3].xyz;  }
float minOf3(vec3 x) { return min(x.x, min(x.y, x.z)); }

// vec3 viewToScreen(vec3 viewPos) {
// 	return (projMAD3(gbufferProjection, viewPos) / -viewPos.z) * 0.5 + 0.5;
// }

void binarySearch(inout vec3 rayPos, vec3 rayDir, sampler2D depthtex) {
    for(int i = 0; i < SSR_BinarySteps; i++) {
        float depthDelta = texture2D(depthtex, rayPos.xy).r - rayPos.z; 
        // Calculate the delta of both ray's depth and depth at ray's coordinates
        rayPos += sign(depthDelta) * rayDir; 
        // Go back and forth
        rayDir *= 0.5; 
        // Decrease the "go back and forth" movement each time we iterate
    }
}

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

    binarySearch(rayPos, rayDir, depthtex);
    // Binary search for some extra accuracy

    // if(texture2D(depthtex1, rayPos.xy).r == 1.0)
    //     intersect = false;

    return intersect;
    // Outputting the boolean
}