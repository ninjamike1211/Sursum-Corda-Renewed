#ifndef LIGHTING
#define LIGHTING

/*
// #include "/lib/defines.glsl"
// #include "/lib/noise.glsl"
// #include "/lib/functions.glsl"
// #include "/lib/spaceConvert.glsl"

// uniform sampler2D depthtex1;
// uniform float     rainStrength;
// uniform float     viewWidth;
// uniform float     viewHeight;
// uniform float     frameTimeCounter;
// uniform float     fogDensityMult;
// uniform vec3      fogColor;
// uniform float     heldBlockLightValue;
// uniform float     heldBlockLightValue2;
// uniform int       heldItemId;
// uniform int       heldItemId2;
// uniform int       worldTime;
*/

const vec3 metalsF0[8] = vec3[8](
    vec3(0.53123, 0.51236, 0.49583), // Iron
    vec3(0.94423, 0.77610, 0.37340), // Gold
    vec3(0.91230, 0.91385, 0.91968), // Aluminium
    vec3(0.55560, 0.55454, 0.55478), // Chrome
    vec3(0.92595, 0.72090, 0.50415), // Copper
    vec3(0.63248, 0.62594, 0.64148), // Lead
    vec3(0.67885, 0.64240, 0.58841), // Platinum
    vec3(0.96200, 0.94947, 0.92212)  // Silver
);


float dayTimeFactor() {
	float adjustedTime = mod(worldTime + 785.0, 24000.0);

	if(adjustedTime > 13570.0)
			return sin((adjustedTime - 3140.0) * PI / 10430.0);

	return sin(adjustedTime * PI / 13570.0);
}

vec3 skyLightColor() {
	#ifdef inEnd
		return vec3(0.075, 0.04, 0.15);
	#endif

	#ifdef inNether
		return vec3(0.4, 0.02, 0.01);
	#endif

    float timeFactor = dayTimeFactor();
    vec3 night = mix(vec3(0.02, 0.02, 0.035), vec3(0.03), rainStrength);
    vec3 day = mix(mix(vec3(1.0, 0.6, 0.4), vec3(0.9, 0.87, 0.85), clamp(5.0 * (timeFactor - 0.2), 0.0, 1.0)), vec3(0.3), rainStrength);
    return mix(night, day, clamp(2.0 * (timeFactor + 0.4), 0.0, 1.0));
}

void fog(inout vec4 albedo, vec3 viewOrigin, vec3 viewPos, vec3 SunMoonColor) {
    vec3 coefs = mix(10.0, 500.0, fogDensityMult) * vec3(2.0, 1.5, 1.0)*vec3(0.0000038, 0.0000105, 0.0000331);

    float dist = length(viewPos - viewOrigin);
    vec3 fogFactor = vec3(exp(-dist*coefs.r), exp(-dist*coefs.g), exp(-dist*coefs.b));

    albedo.rgb = mix(2.0 * SunMoonColor, albedo.rgb, fogFactor);
}

void netherFog(inout vec4 albedo, vec3 viewOrigin, vec3 viewPos, vec3 fogColor) {
    float dist = length(viewPos - viewOrigin);
    float fogFactor = clamp(exp(-dist*0.02), 0.0, 1.0);

    albedo.rgb = mix(fogColor, albedo.rgb, fogFactor);
}

void waterFog(inout vec4 albedo, vec3 viewOrigin, vec3 viewPos, vec3 SunMoonColor) {
    vec3 absorptionCoef = 1.0 * vec3(0.13, 0.07, 0.06);
    vec3 scatteringCoef = 0.3 * vec3(0.04);

    vec3 transmittance = exp(-absorptionCoef * length(viewPos - viewOrigin));
    vec3 scattering = SunMoonColor * transmittance * scatteringCoef * (1.0 - transmittance) / absorptionCoef;

    albedo.rgb = albedo.rgb * transmittance + scattering;
}

vec3 adjustLightMap(vec2 lmcoord, vec3 SunMoonColor) {
    // vec3 skyAmbient = SunMoonColor * mix(vec3(0.07), vec3(4.0), lmcoord.y);
    lmcoord = pow((lmcoord - 1.0/32.0) * 32.0/31.0, vec2(2.0));
    vec3 skyAmbient = mix(vec3(0.06), 4 * SunMoonColor, lmcoord.y);
    vec3 torchAmbient = mix(vec3(0.0), 1.5*vec3(15.0, 7.2, 2.9), lmcoord.x) /* * (1.2 - skyAmbient) */;

    #ifdef inNether
        torchAmbient = mix(vec3(0.5, 0.1, 0.05), vec3(8.0, 2.2, 0.6), lmcoord.x);
    #endif

    return skyAmbient + torchAmbient;
}

vec3 calcAmbient(vec3 albedo, vec2 lmcoord, vec3 skyAmbient, vec4 specMap) {
    float emissiveness = specMap.a > 254.5/255.0 ? 0.0 : specMap.a * EmissiveStrength;
    return albedo * (adjustLightMap(lmcoord, skyAmbient) * 0.2 + 10.0 * emissiveness);
}

// void diffuseLighting(inout vec4 albedo, vec3 shadowVal, vec2 lmcoord, int time, float rainStrength) {
//     vec3 SunMoonColor = skyLightColor(time, rainStrength);
//     vec3 skyLight = SunMoonColor * shadowVal;
//     vec3 skyAmbient = SunMoonColor * mix(vec3(0.07), vec3(0.4), lmcoord.y) * (1.0 - shadowVal);
//     vec3 torchAmbient = mix(vec3(0.0), vec3(0.9, 0.7, 0.4), lmcoord.x) * (1.2 - skyLight);

//         // if(NGdotL) < 0.01)
//     //     NdotL = 0.0;
//     // albedo.rgb *= min(vec3(max(NdotL, 0.0)), shadowVal) * 0.5 + 0.5;

//     // albedo = linearToSRGB(albedo);
//     albedo.rgb *= skyLight + skyAmbient + torchAmbient;
//     // albedo = sRGBToLinear(albedo);
//     // albedo.rgb *= 1.0;
// }

vec3 fresnelSchlick(float cosTheta, vec3 F0) {
    return F0 + (1.0 - F0) * pow(max(1.0 - cosTheta, 0.0), 5.0);
}

// Hardcoded metals fresnel function by Jessie#7257
vec3 Lazanyi2019(float cosTheta, in vec3 f0, in vec3 f82) {
    vec3 a = 17.6513846 * (f0 - f82) + 8.16666667 * (1.0 - f0);
    return clamp(f0 + (1.0 - f0) * pow(1.0 - cosTheta, 5.0) - a * cosTheta * pow(1.0 - cosTheta, 6.0), 0.0, 1.0);
}

float DistributionGGX(vec3 normal, vec3 halfwayDir, float roughness) {
    float a2 = roughness*roughness;
    float NdotH = max(dot(normal, halfwayDir), 0.0);
    float NdotH2 = NdotH*NdotH;
	
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;
	
    return a2 / denom;
}

float GeometrySchlickGGX(float NdotV, float roughness) {
    float r = (roughness + 1.0);
    float k = (r*r) / 8.0;

    return NdotV / (NdotV * (1.0 - k) + k);
}

float GeometrySmith(vec3 normal, vec3 viewDir, vec3 lightDir, float roughness) {
    float NdotV = max(dot(normal, viewDir), 0.0);
    float NdotL = max(dot(normal, lightDir), 0.0);
    float ggx2  = GeometrySchlickGGX(NdotV, roughness);
    float ggx1  = GeometrySchlickGGX(NdotL, roughness);
	
    return ggx1 * ggx2;
}

// Hardcoded metal values by Jessie#7257
void hardcodeMetalValue(int index, out vec3 F0, out vec3 F82) {
    switch(index) {
        case 0: {
            //Iron
            F0 = sRGBToLinear3(vec3(0.78, 0.77, 0.74));
            F82 = sRGBToLinear3(vec3(0.75, 0.76, 0.74));
            break;
        }
        case 1: {
            //Gold
            F0 = sRGBToLinear3(vec3(1.00, 0.90, 0.61));
            F82 = sRGBToLinear3(vec3(1.00, 0.92, 0.73));
            break;
        }
        case 2: {
            //Aluminum
            F0 = sRGBToLinear3(vec3(1.00, 0.98, 1.00));
            F82 = sRGBToLinear3(vec3(0.96, 0.97, 0.96));
            break;
        }
        case 3: {
            //Chrome
            F0 = sRGBToLinear3(vec3(0.77, 0.80, 0.79));
            F82 = sRGBToLinear3(vec3(0.76, 0.77, 0.77));
            break;
        }
        case 4: {
            //Copper
            F0 = sRGBToLinear3(vec3(1.00, 0.89, 0.73));
            F82 = sRGBToLinear3(vec3(0.99, 0.90, 0.78));
            break;
        }
        case 5: {
            //Lead
            F0 = sRGBToLinear3(vec3(0.79, 0.87, 0.85));
            F82 = sRGBToLinear3(vec3(0.80, 0.81, 0.83));
            break;
        }
        case 6: {
            //Platinum
            F0 = sRGBToLinear3(vec3(0.92, 0.90, 0.83));
            F82 = sRGBToLinear3(vec3(0.87, 0.87, 0.83));
            break;
        }
        case 7: {
            //Silver
            F0 = sRGBToLinear3(vec3(1.00, 1.00, 0.91));
            F82 = sRGBToLinear3(vec3(0.99, 0.99, 0.93));
            break;
        }
    }
}

vec3 calcFresnel(float cosTheta, vec4 specMap, vec3 albedo) {
    if(specMap.g < 229.5/255.0) {
        vec3 F0 = vec3(max(specMap.ggg, 0.04));
        return fresnelSchlick(cosTheta, F0);
    }
    else if(specMap.g < 237.5/255.0) {
        int index = int(specMap.g * 255.0 + 0.5) - 230;
        vec3 F0, F82;
        hardcodeMetalValue(index, F0, F82);
        return Lazanyi2019(cosTheta, F0, F82);
    }
    else {
        return fresnelSchlick(cosTheta, albedo);
    }
}

vec3 cookTorrancePBRLighting(vec3 albedo, vec3 viewDir, vec3 normal, vec4 specMap, vec3 light, vec3 lightDir) {
    vec3 halfwayDir = normalize(viewDir + lightDir);

    float metalness = step(229.5/255.0, specMap.g);
    float roughness = max(pow(1.0 - specMap.r, 2.0), 0.02);

    vec3 fresnel = calcFresnel(max(dot(halfwayDir, viewDir), 0.0), specMap, albedo);
    float geometry = GeometrySmith(normal, viewDir, lightDir, roughness);
    float distribution = DistributionGGX(normal, halfwayDir, roughness);

    vec3 diffuse = albedo / PI * (1.0 - fresnel) * (1.0 - metalness);
    vec3 specular = (fresnel * geometry * distribution) / max(4.0 * dot(viewDir, normal) * dot(lightDir, normal), 0.001);

    return (diffuse + specular) * light * max(dot(normal, lightDir), 0.0);
    // return vec3(fresnel);
}

vec3 calcSSAO(vec3 normal, vec3 viewPos, vec2 texcoord, sampler2D depthTex, sampler2D aoNoiseTex) {
    vec2 noiseCoord = vec2(mod(texcoord.x * viewWidth, 4.0) / 4.0, mod(texcoord.y * viewHeight, 4.0) / 4.0);
    vec3 rvec = vec3(texture2D(aoNoiseTex, noiseCoord).xy * 2.0 - 1.0, 0.0);
	// vec3 rvec = vec3(1.0);
	vec3 tangent = normalize(rvec - normal * dot(rvec, normal));
	vec3 bitangent = cross(normal, tangent);
	mat3 tbn = mat3(tangent, bitangent, normal);

    vec3 fragPos = viewPos;

    vec3 occlusion = vec3(0.0);
	for (int i = 0; i < half_sphere_16.length(); ++i) {
		// get sample position:
		vec3 sampleVal = tbn * half_sphere_16[i];
		sampleVal = sampleVal * SSAO_Radius + fragPos;
		
		// project sample position:
		vec4 offset = vec4(sampleVal, 1.0);
		offset = gbufferProjection * offset;
		offset.xy /= offset.w;
		offset.xy = offset.xy * 0.5 + 0.5;
		
		// get sample depth:
		float sampleDepth = screenToView(offset.xy, texture2D(depthTex, offset.xy).r).z; // texture2D(viewTex, offset.xy).z;
		
		// range check & accumulate:
		float rangeCheck = smoothstep(0.0, 1.0, SSAO_Radius / abs(fragPos.z - sampleDepth));
        // float rangeCheck= abs(fragPos.z - sampleDepth) < SSAO_Radius ? 1.0 : 0.0;
		occlusion += (sampleDepth >= sampleVal.z ? 1.0 : 0.0) * rangeCheck;
        // float occlusionFactor = (sampleDepth >= sampleVal.z ? 1.0 : 0.0) * rangeCheck;

        // if(occlusionFactor > 0.0) {
        //     vec4 albedo = texture2D(colortex, offset.xy);
        //     vec3 lightColor = albedo.rgb * (1.0 - albedo.a);
        //     occlusion += (1.0 - albedo.rgb) * occlusionFactor;
        // }
	}

	return clamp(1.0 - (SSAO_Strength * occlusion / half_sphere_16.length()), 0.0, 1.0);
}

// vec2 calcSSRNew(vec2 texcoord, float depth, vec3 viewPos, vec3 normal, float jitter, vec3 sunPosition, float eyeAltitude, sampler2D depthtex, mat4 projectionMatrix, mat4 modelViewInverse) {
//     vec3 rayDir = -reflect(normalize(-viewPos), normal);
//     vec3 rayScreenDir = normalize(viewToScreen(viewPos + rayDir, projectionMatrix) - vec3(texcoord, depth));

//     float xDist = rayScreenDir.x > 0 ? 1.0-texcoord.x : texcoord.x;
//     float yDist = rayScreenDir.y > 0 ? 1.0-texcoord.y : texcoord.y;

//     float xSlope = sqrt(1 + pow(rayScreenDir.y / rayScreenDir.x, 2.0));
//     float ySlope = sqrt(1 + pow(rayScreenDir.x / rayScreenDir.y, 2.0));

//     float xLength = xDist * xSlope;
//     float yLength = yDist * ySlope;

//     float rayLength = min(xLength, yLength);

//     int initialSteps = 64;
//     int binarySteps = 5;

//     float thickness = 0.15;
//     float depthToleranceFactor = 0.000;
//     float depthThreshold = 0.1;

//     vec3 raySubDir = rayScreenDir * rayLength / initialSteps;

//     vec3 startPoint = vec3(-1.0);
//     vec3 endPoint = vec3(texcoord, depth) + jitter * raySubDir;
//     vec2 reflectionPos = vec2(-1.0);
//     float bufferDepth = 0.0;
    
//     for(int i = 0; i < initialSteps; i++) {
//         endPoint += raySubDir;
//         bufferDepth = texture2D(depthtex, endPoint.xy).r;
//         float depthDiff = linearizeDepthNorm(endPoint.z) - linearizeDepthNorm(bufferDepth);

//         if(clamp(endPoint.xy, 0.0, 1.0) != endPoint.xy) {
//             // return skyColor(rayDir, normalize(sunPosition), eyeAltitude, mat3(modelViewInverse));
//             return vec2(-1.0);
//         }

//         if(depthDiff > 0 && depthDiff < thickness) {
//             startPoint = endPoint - raySubDir;
//             reflectionPos = endPoint.xy;
//             break;
//         }
//     }

//     if(startPoint.x < -0.9 || bufferDepth == 1.0) {
//         // return skyColor(rayDir, normalize(sunPosition), eyeAltitude, mat3(modelViewInverse));
//         return vec2(-1.0);
//     }

//     for(int i = 0; i < binarySteps; i++) {
//         vec3 midPoint = (startPoint + endPoint) / 2.0;
//         bufferDepth = texture2D(depthtex, midPoint.xy).r;
//         float depthDiff = linearizeDepthNorm(endPoint.z) - linearizeDepthNorm(bufferDepth);

//         if(depthDiff > 0 && depthDiff < thickness) {
//             reflectionPos = midPoint.xy;
//             endPoint = midPoint;
//         }
//         else {
//             startPoint = midPoint;
//         }
//     }

//     // // float depthDiff = endPoint.z - bufferDepth;
//     // float depthDiff = linearizeDepthNorm(endPoint.z) - linearizeDepthNorm(bufferDepth);
//     // if(abs(depthDiff) > 0.005)
//     //     return skyColor(rayDir, normalize(sunPosition), eyeAltitude, mat3(modelViewInverse));
//     //     // return vec3(0.0);

//     // return vec3(float(abs(depthDiff) > 0.01));
//     return reflectionPos;

// }

vec3 calcSSRSues(vec3 viewSpacePos, vec3 normal, vec3 sunPosition, float eyeAltitude, sampler2D depthTex, sampler2D colortex, mat4 modelViewInverse, mat4 projectionMatrix, mat4 projectionInverse) {
    // #ifdef SSR_Rough
    //     normal = normalize(normal * (texture2D(noisetex, texcoord).rgb * 0.002 - 0.001));
    // #endif

    vec3 reflectDir = reflect(normalize(viewSpacePos), normal);
    
    // vec2 screenSpacePos = texcoord;
    // vec3 viewSpaceDir = normalize(viewSpacePos);

    // vec3 reflectDir = normalize(reflect(viewSpaceDir, normal));
    vec3 viewSpaceVector = .999 * reflectDir;
    vec3 viewSpaceVectorFar = far * reflectDir;
    vec3 viewSpaceVectorPos = viewSpacePos + viewSpaceVector;
    vec3 currentPosition = viewToScreen(viewSpaceVectorPos);

    const int maxRefinements = 5;
	int numRefinements = 0;
	vec3 finalSamplePos = vec3(0.0/* , 0.0, -1.0 */);

	int numSteps = 0;

	float finalSampleDiff = 0.0;


    for(int i = 0; i < 40; i++) {

        if(-viewSpaceVectorPos.z > far * 1.4f ||
           -viewSpaceVectorPos.z < 0.0f)
        {
		   break;
		}

        vec2 samplePos = currentPosition.xy;
        float sampleDepth = screenToView(samplePos, texture2D(depthTex, samplePos).r).z;


        float currentDepth = viewSpaceVectorPos.z;
        float diff = sampleDepth - currentDepth;
        float error = length(viewSpaceVector / pow(2.0, numRefinements));

        if(diff >= 0 && diff <= error * 2.0 && numRefinements <= maxRefinements) {
            viewSpaceVectorPos -= viewSpaceVector / pow(2.0, numRefinements);
            numRefinements++;
        }
        else if(diff >= 0 && diff <= error * 4.0 && numRefinements > maxRefinements) {
            finalSamplePos = vec3(samplePos, 1.0);
            finalSampleDiff = diff;
            break;
        }
        // else if(numRefinements > maxRefinements) {
        //     finalSamplePos = vec3(samplePos, -1.0);
        //     finalSampleDiff = diff;
        //     break;
        // }

        viewSpaceVectorPos += viewSpaceVector / pow(2.0f, numRefinements);

        if(numSteps > 1)
            viewSpaceVector *= 1.375;

        currentPosition = viewToScreen(viewSpaceVectorPos);

        if (currentPosition.x < 0 || currentPosition.x > 1 ||
            currentPosition.y < 0 || currentPosition.y > 1 ||
            currentPosition.z < 0 || currentPosition.z > 1)
        {
            break;
        }
        // currentPosition = clamp(currentPosition, vec3(0.001), vec3(0.999));

        numSteps++;
    }

    // vec4 color = vec4(1.0);
    // color.rgb = texture2D(colorTex, finalSamplePos).rgb;

    /* if(finalSampleDiff < 0) {
        finalSamplePos.z = -1.0;
    }
    else  */if (finalSamplePos.x == 0.0 || finalSamplePos.y == 0.0) {
		finalSamplePos.z = 0.0;
        // return skyColor(reflectDir, normalize(sunPosition), eyeAltitude, mat3(modelViewInverse));
	}

    // return color;
    return texture2D(colortex, finalSamplePos.xy).rgb;
}

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

// bool raytrace(vec3 viewPos, vec3 rayDir, float jitter, inout vec3 hitPos, mat4 projectionMatrix, sampler2D depthtex) {
//     // "inout vec3 hitPos" is our ray's position, we use it as an "inout" parameter to be able to return both the intersection check and the hit position
//     vec3 screenPos = viewToScreen(viewPos, projectionMatrix); 
//     // Starting position in screen space, it's better to perform space conversions OUTSIDE of the loop to increase performance
//     vec3 screenDir = normalize(viewToScreen(viewPos + rayDir, projectionMatrix) - screenPos) * (1.0 / SSR_Steps);
//     // Calculate the ray's direction in screen space, we multiply it by a "step size" that depends on the amount of raytracing steps we use

//     hitPos = screenPos + screenDir * jitter;
//     // We settle the ray's starting point and jitter it
//     // Jittering reduces the banding caused by a low amount of steps, it's basically multiplying the direction by a random value (like noise)
//     for(int i = 0; i < SSR_Steps; i++, hitPos += screenDir) {
//         // Loop until we reach the max amount of steps, add 1 at each iteration AND march the ray (position += direction)

//         if(clamp(hitPos.xy, vec2(0.0), vec2(1.0)) != hitPos.xy) { return false; }
//         // Checking if the ray goes outside of the screen (if clamping the coordinates to [0;1] returns a different value, then we're outside)
//         // There's no need to continue ray marching if the ray goes outside of the screen
//         float depth = texture2D(depthtex, hitPos.xy).r;
//         // Sampling the depth at the ray's position
//         // We use depthtex1 to get the depth of all blocks EXCEPT translucents, it's useful for refractions

//         if(abs(0.001 - (hitPos.z - depth)) < 0.001) {
//         // Comparing the ray's depth and the depth at the ray's position depending on a tolerance threshold (usually around 0.001, a low value in general)
//             // #if BINARY_REFINEMENT == 1
//                 binarySearch(hitPos, screenDir, depthtex);
//                 // Binary search for some extra accuracy and optimization
//             // #endif
//             return true;
//             // If the comparison is below the threshold, then we found our intersection, hurray!
//         }
//     }
//     return false;
//     // No intersection found :( *sad trombone noises*
// }

float calcSSRNew(vec3 viewPos, vec3 rayDir, float jitter, out vec3 hitPos, mat4 projectionMatrix, sampler2D depthtex, sampler2D normaltex) {
    vec3 screenPos = viewToScreen(viewPos);
    vec3 screenDir = normalize(viewToScreen(viewPos + rayDir) - screenPos);

    float xDist = screenDir.x > 0 ? 1.0-screenPos.x : screenPos.x;
    float yDist = screenDir.y > 0 ? 1.0-screenPos.y : screenPos.y;

    float xSlope = sqrt(1 + pow(screenDir.y / screenDir.x, 2.0));
    float ySlope = sqrt(1 + pow(screenDir.x / screenDir.y, 2.0));

    float xLength = xDist * xSlope;
    float yLength = yDist * ySlope;

    float stepLength = min(xLength, yLength) / SSR_Steps;
    // float stepLength = 1.0 / SSR_Steps;

    vec3 rayStep = screenDir * stepLength;

    hitPos = screenPos + jitter * rayStep;

    for(int i = 0; i < SSR_Steps; i++, hitPos += rayStep) {
        float sampleDepth = texture2D(depthtex, hitPos.xy).r;

        if(clamp(hitPos.xy, 0.0, 1.0) != hitPos.xy) {
            return 0.0;
            // hitPos = vec3(0.0);
            // return true;
        }

        // float depthToleranceFactor = mix(0.0006, 0.0009, linearizeDepthNorm(hitPos.z));
        float depthDiff = linearizeDepthNorm(hitPos.z) - linearizeDepthNorm(sampleDepth);

        // if(abs(0.001 - (hitPos.z - sampleDepth)) < 0.0009) {
        if(sampleDepth - hitPos.z < -0.00001) {
        // if(depthDiff > 0.0 && depthDiff < 0.15) {
            binarySearch(hitPos, rayStep, depthtex);
            sampleDepth = texture2D(depthtex, hitPos.xy).r;

            if(/* texture2D(depthtex, hitPos.xy).r == 1.0 || */ sampleDepth - hitPos.z < -0.0001)
                return 0.0;

            // vec3 normal = NormalDecode(texture2D(normaltex, hitPos.xy).zw);
            // if(dot(rayDir, normal) > 0.1)
            //     return -1;
            
            // return 1;
            float edgeVal = min(min(min(hitPos.x, hitPos.y), 1.0-hitPos.x), 1.0-hitPos.y);
            return smoothstep(0.0, 0.03, edgeVal);
        }
    }

    return 0.0;
    // hitPos = vec3(0.0);
    // return true;
}

bool contactShadow(vec3 viewPos, vec3 lightPosNorm, mat4 projectionMatrix, sampler2D depthtex) {
    
    int steps = 64;
    vec3 rayStep = lightPosNorm * 1.25 / steps;

    for (int step = 0; step < 64; step++) {
        viewPos += rayStep;
        vec3 screenPos = viewToScreen(viewPos);

        if (clamp(screenPos.xy, 0.0, 1.0) != screenPos.xy) {
            return false;
        }

        float sampleDepth = texture2D(depthtex, screenPos.xy).r;

        if(abs(linearizeDepthNorm(sampleDepth) - linearizeDepthNorm(screenPos.z)) < 0.0001) {
            return true;
        }
    }

    return false;
}

float ssShadows(vec3 startPos, vec3 endPos, float jitter, sampler2D depthtex) {
    float steps = 32.0;

    vec3 screenStep = (viewToScreen(endPos) - viewToScreen(startPos)) / steps;
    vec3 screenPos = startPos;

    vec3 viewStep = (endPos - startPos) / steps;
    vec3 viewPos = startPos + viewStep * jitter;
    viewStep -= viewStep * jitter / steps;

    for(int i = 0; i < steps; i++) {
        // screenPos += screenStep;
        viewPos += viewStep;
        screenPos = viewToScreen(viewPos);

        if(clamp(screenPos.xy, 0.0, 1.0) == screenPos.xy) {
            float sampleDepth = texture2D(depthtex, screenPos.xy).r;

            if(screenPos.z - sampleDepth > 0.001 && sampleDepth > 0.58)
                return 0.0;
        }
    }

    return 1.0;
}

#ifdef SSS
void SubsurfaceScattering(inout vec3 color, in vec3 albedo, in float subsurface, in float blockerDist, in vec3 light) {
    if(subsurface > 0.0 ) {
        // vec3 shadowPos = calcShadowPos(viewPos, gbufferModelViewInverse);
        // float shadowMapDepth = texture2D(shadowtex0, shadowPos.xy).r;
        float diff = blockerDist * (far-near) - near;

        // #ifdef Shadow_LeakFix
        //     subsurface *= smoothstep(9.0/32.0, 21.0/32.0, lmcoord.g);
        // #endif

        color += albedo * exp(min(-diff * 2.5 / subsurface, 0.0)) * 0.2 * subsurface * light;
    }
}
#endif

#ifdef HandLight
void DynamicHandLight(inout vec3 color, in vec3 viewPos, in vec3 albedo, in vec3 normal, in vec4 specMap, bool isHand) {
    if(heldBlockLightValue > 0) {
        vec3 lightPos = vec3(0.2, -0.1, -0.24);
        // vec3 lightPos = screenToView(vec2(0.873, 0.213), 0.55);
        vec3 lightDir = -normalize(viewPos - lightPos);
        float dist = length(viewPos - lightPos);
        
        vec3 lightColor = vec3(2.0 * float(heldBlockLightValue) / (15.0 * dist * dist));

        #ifdef HandLight_Colors
            if(heldItemId == 10001)
                lightColor *= vec3(0.2, 3.0, 10.0);
            else if(heldItemId == 10002)
                lightColor *= vec3(10.0, 1.5, 0.0);
            else if(heldItemId == 10003)
                lightColor *= vec3(15.0, 4.0, 1.5);
            else if(heldItemId == 10004)
                lightColor *= vec3(3.0, 6.0, 15.0);
            else if(heldItemId == 10005)
                lightColor *= vec3(1.5, 1.0, 10.0);
            else if(heldItemId == 10006)
                lightColor *= vec3(4.0, 1.0, 10.0);
            else
        #endif
            lightColor *= vec3(15.0, 7.2, 2.9);

        if(!isHand || dist > 0.07) {
            #ifdef HandLight_Shadows
                // float jitter = texture2D(noisetex, texcoord * 20.0 + frameTimeCounter).r;
                float jitter = interleaved_gradient(ivec2(gl_FragCoord.xy), frameCounter);
                lightColor *= ssShadows(viewPos, lightPos, jitter, depthtex1);
            #endif

            // vec3 normalUse = isHand < 0.9 ? normal : playerDir;
            color += cookTorrancePBRLighting(albedo, normalize(-viewPos), normal, specMap, lightColor, lightDir);
        }
        else {
            color += lightColor * albedo * 0.001;
        }

        // color = vec3(dist);
    }
    if(heldBlockLightValue2 > 0) {
        vec3 lightPos = vec3(-0.2, -0.1, -0.24);
        // vec3 lightPos = screenToView(vec2(0.127, 0.213), 0.55);
        vec3 lightDir = -normalize(viewPos - lightPos);
        float dist = length(viewPos - lightPos);
        
        vec3 lightColor = vec3(2.0 * float(heldBlockLightValue2) / (15.0 * dist * dist));

        #ifdef HandLight_Colors
            if(heldItemId2 == 10001)
                lightColor *= vec3(0.2, 3.0, 10.0);
            else if(heldItemId2 == 10002)
                lightColor *= vec3(10.0, 1.5, 0.0);
            else if(heldItemId2 == 10003)
                lightColor *= vec3(15.0, 4.0, 1.5);
            else if(heldItemId2 == 10004)
                lightColor *= vec3(3.0, 6.0, 15.0);
            else if(heldItemId2 == 10005)
                lightColor *= vec3(1.5, 1.0, 10.0);
            else if(heldItemId2 == 10006)
                lightColor *= vec3(4.0, 1.0, 10.0);
            else
        #endif
            lightColor *= vec3(15.0, 7.2, 2.9);

        if(!isHand || dist > 0.07) {
            #ifdef HandLight_Shadows
                // float jitter = texture2D(noisetex, texcoord * 20.0 + frameTimeCounter).r;
                float jitter = interleaved_gradient(ivec2(gl_FragCoord.xy), frameCounter);
                lightColor *= ssShadows(viewPos, lightPos, jitter, depthtex1);
            #endif

            // vec3 normalUse = isHand < 0.9 ? normal : playerDir;
            color += cookTorrancePBRLighting(albedo, normalize(-viewPos), normal, specMap, lightColor, lightDir);
        }
        else {
            color += lightColor * albedo * 0.001;
        }
    }
}
#endif

#ifdef baseFragment
void applyEndPortal(in vec3 worldPos, out vec3 albedo, out vec4 specMap) {
    mat2 rot0 = mat2(cos(0.0), -sin(0.0), sin(0.0), cos(0.0));
    mat2 rot1 = mat2(cos(1.0), -sin(1.0), sin(1.0), cos(1.0));
    mat2 rot2 = mat2(cos(2.0), -sin(2.0), sin(2.0), cos(2.0));
    mat2 rot3 = mat2(cos(3.0), -sin(3.0), sin(3.0), cos(3.0));
    mat2 rot4 = mat2(cos(4.0), -sin(4.0), sin(4.0), cos(4.0));
    mat2 rot5 = mat2(cos(5.0), -sin(5.0), sin(5.0), cos(5.0));
    mat2 rot6 = mat2(cos(6.0), -sin(6.0), sin(6.0), cos(6.0));
    mat2 rot7 = mat2(cos(7.0), -sin(7.0), sin(7.0), cos(7.0));
    mat2 rot8 = mat2(cos(8.0), -sin(8.0), sin(8.0), cos(8.0));
    
    // albedoOut = vec4(vec3(0.0, 0.01, 0.015) * (texelFetch(noisetex, ivec2(gl_FragCoord.xy / viewWidth * 100), 0).r * 0.9 + 0.1), 1.0);
    albedo = 5*vec3(0.0, 0.02, 0.025) * pow(Cellular2D(gl_FragCoord.xy / viewWidth * 30), 2.0);

    albedo += 2.5 * sin(1.0 * frameTimeCounter + 0         ) * vec3(0.10, 0.20, 0.18) * pow(Cellular2D(3 * rot0 * ((worldPos.xz + worldPos.y)  *  1.5) + vec2(0.0, 0.2 * frameTimeCounter)), 1.8);
    albedo += 2.5 * sin(1.2 * frameTimeCounter + 5/8.0 * PI) * vec3(0.10, 0.20, 0.18) * pow(Cellular2D(3 * rot1 * ((worldPos.xz + worldPos.y)  *  0.9) + vec2(0.0, 0.2 * frameTimeCounter)), 1.8);
    albedo += 2.5 * sin(1.7 * frameTimeCounter + 2/8.0 * PI) * vec3(0.10, 0.20, 0.18) * pow(Cellular2D(3 * rot2 * (gl_FragCoord.xy / viewWidth *  7.0) + vec2(0.0, 0.2 * frameTimeCounter)), 1.8);
    albedo += 2.5 * sin(1.8 * frameTimeCounter + 7/8.0 * PI) * vec3(0.18, 0.12, 0.20) * pow(Cellular2D(3 * rot3 * ((worldPos.xz + worldPos.y)  *  0.5) + vec2(0.0, 0.2 * frameTimeCounter)), 1.8);
    albedo += 2.5 * sin(1.9 * frameTimeCounter + 4/8.0 * PI) * vec3(0.15, 0.15, 0.08) * pow(Cellular2D(3 * rot4 * (gl_FragCoord.xy / viewWidth *  2.0) + vec2(0.0, 0.2 * frameTimeCounter)), 1.8);
    albedo += 2.5 * sin(1.2 * frameTimeCounter + 1/8.0 * PI) * vec3(0.03, 0.20, 0.13) * pow(Cellular2D(3 * rot5 * (gl_FragCoord.xy / viewWidth *  1.5) + vec2(0.0, 0.2 * frameTimeCounter)), 1.8);
    albedo += 2.5 * sin(1.0 * frameTimeCounter + 6/8.0 * PI) * vec3(0.18, 0.10, 0.09) * pow(Cellular2D(3 * rot6 * ((worldPos.xz + worldPos.y)  *  0.1) + vec2(0.0, 0.2 * frameTimeCounter)), 1.8);
    albedo += 2.5 * sin(1.3 * frameTimeCounter + 3/8.0 * PI) * vec3(0.05, 0.15, 0.20) * pow(Cellular2D(3 * rot7 * (gl_FragCoord.xy / viewWidth *  0.8) + vec2(0.0, 0.2 * frameTimeCounter)), 1.8);

    albedo += 5.0 * vec3(0.10, 0.20, 0.18) * textureLod(texture, rot0 * ((worldPos.xz + worldPos.yy) * 0.6)  + vec2(0.0, 0.09 * frameTimeCounter), 0.0).r;
    albedo += 5.0 * vec3(0.10, 0.20, 0.18) * textureLod(texture, rot1 * ((worldPos.xz + worldPos.yy) * 0.5)  + vec2(0.0, 0.08 * frameTimeCounter), 0.0).r;
    albedo += 5.0 * vec3(0.10, 0.20, 0.18) * textureLod(texture, rot2 * ((worldPos.xz + worldPos.yy) * 0.4)  + vec2(0.0, 0.07 * frameTimeCounter), 0.0).r;
    albedo += 5.0 * vec3(0.18, 0.12, 0.20) * textureLod(texture, rot3 * (gl_FragCoord.xy / viewWidth *  1.8) + vec2(0.0, 0.06 * frameTimeCounter), 0.0).r;
    albedo += 5.0 * vec3(0.15, 0.15, 0.08) * textureLod(texture, rot4 * (gl_FragCoord.xy / viewWidth *  1.3) + vec2(0.0, 0.06 * frameTimeCounter), 0.0).r;
    albedo += 5.0 * vec3(0.03, 0.20, 0.13) * textureLod(texture, rot5 * (gl_FragCoord.xy / viewWidth *  1.0) + vec2(0.0, 0.06 * frameTimeCounter), 0.0).r;
    albedo += 5.0 * vec3(0.18, 0.10, 0.09) * textureLod(texture, rot6 * (gl_FragCoord.xy / viewWidth *  0.8) + vec2(0.0, 0.06 * frameTimeCounter), 0.0).r;
    albedo += 5.0 * vec3(0.05, 0.15, 0.20) * textureLod(texture, rot7 * (gl_FragCoord.xy / viewWidth *  0.5) + vec2(0.0, 0.06 * frameTimeCounter), 0.0).r;

    // albedo  = textureLod(texture, 1.0 * gl_FragCoord.xy / viewWidth + vec2(0.0, 0.1 * frameTimeCounter), 0.0).rgb;
    // albedo += textureLod(texture, 0.5 * gl_FragCoord.xy / viewWidth + vec2(0.0, 0.1 * frameTimeCounter), 0.0).rgb;

    specMap = vec4(1.0, 0.0, 0.0, 254.0/255.0);
}
#endif

#endif