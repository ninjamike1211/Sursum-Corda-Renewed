#ifndef SHADOWS
#define SHADOWS

// #include "/lib/functions.glsl"
// #include "/lib/sample.glsl"
// #include "/lib/spaceConvert.glsl"

// uniform sampler2D shadowtex0;
// uniform sampler2D shadowtex1;
// uniform sampler2D shadowcolor0;
// uniform mat4      shadowModelView;
// uniform mat4      shadowProjection;

// float cubeLength(vec2 v) {
// 	return pow(abs(v.x * v.x * v.x) + abs(v.y * v.y * v.y), 1.0 / 3.0);
// }

// float getDistortFactor(vec2 v) {
// 	// return (cubeLength(v) + Shadow_Distort_Factor) / ((1 + Shadow_Distort_Factor) * 0.95);
// 	return cubeLength(v) + Shadow_Distort_Factor;
// }

// vec3 distort(vec3 v, float factor) {
// 	return vec3(v.xy / factor, v.z * 0.5);
// }

// vec3 distort(vec3 v) {
// 	return distort(v, getDistortFactor(v.xy));
// }




// Beter shadow distortion from Groundwork-4  (https://github.com/DrDesten/Groundwork)

// vec3 shadowDistortion(vec3 clipPos) {
// 	clipPos.xy  /= length(clipPos.xy) + SHADOW_DISTORSION;
// 	clipPos.z   *= SHADOW_ZSCALE;
// 	clipPos.xy  *= (1 + SHADOW_DISTORSION) * SHADOW_SCALE;
// 	return clipPos;
// }
// vec3 shadowDistortion(vec3 clipPos, float len) {
// 	clipPos.xy  /= len + SHADOW_DISTORSION;
// 	clipPos.z   *= SHADOW_ZSCALE;
// 	clipPos.xy  *= (1 + SHADOW_DISTORSION) * SHADOW_SCALE;
// 	return clipPos;
// }

// float shadowDistortionDerivative(float len) {
// 	return ( SHADOW_DISTORSION * (1 + SHADOW_DISTORSION) * SHADOW_SCALE ) / sqrt(len + SHADOW_DISTORSION) ;
// }
// float shadowDistortionDerivativeInverse(float len) {
// 	return sqrt(len + SHADOW_DISTORSION) * (1. / ( SHADOW_DISTORSION * (1 + SHADOW_DISTORSION) * SHADOW_SCALE ) );
// }

// float getShadowBias(float NdotL) {
// 	return clamp(( sqrt(NdotL * -NdotL + 1) / NdotL ) * (SHADOW_BIAS / shadowMapResolution), 1e-6, 1e6);
// }

// float getShadowBias(float NdotL, float len) {
// 	float shadowBias = SHADOW_BIAS * shadowDistortionDerivativeInverse(len) * shadowMapResolution;
    
//     return clamp(( sqrt(NdotL * -NdotL + 1) / NdotL ) * (shadowBias / shadowMapResolution), 1e-6, 1e6);
// }


// Shadow Distortion taken from Shadow Tutorial pack by builderb0y

#define SHADOW_DISTORT_ENABLED //Toggles shadow map distortion
#define SHADOW_DISTORT_FACTOR 0.10 //Distortion factor for the shadow map. Has no effect when shadow distortion is disabled. [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.00]
#define SHADOW_BIAS 1.00 //Increase this if you get shadow acne. Decrease this if you get peter panning. [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.60 0.70 0.80 0.90 1.00 1.50 2.00 2.50 3.00 3.50 4.00 4.50 5.00 6.00 7.00 8.00 9.00 10.00]
#define Shadow_NormalBias //Offsets the shadow sample position by the surface normal instead of towards the sun

vec3 distort(vec3 pos) {
    float factor = length(pos.xy) + SHADOW_DISTORT_FACTOR;
    return vec3(pos.xy / factor, pos.z * 0.5);
}

//returns the reciprocal of the derivative of our distort function,
//multiplied by SHADOW_BIAS.
//if a texel in the shadow map contains a bigger area,
//then we need more bias. therefore, we need to know how much
//bigger or smaller a pixel gets as a result of applying sistortion.
float computeBias(vec3 pos) {
    //square(length(pos.xy) + SHADOW_DISTORT_FACTOR) / SHADOW_DISTORT_FACTOR
    float numerator = length(pos.xy) + SHADOW_DISTORT_FACTOR;
    numerator *= numerator;
    return SHADOW_BIAS / shadowMapResolution * numerator / SHADOW_DISTORT_FACTOR;
}



#ifndef shadowGbuffer

    vec3 shadowVisibility(vec3 shadowPos) {
        vec4 shadowColor = texture2D(shadowcolor0, shadowPos.xy);
        shadowColor.rgb = shadowColor.rgb * (1.0 - shadowColor.a);
        float visibility0 = step(shadowPos.z, texture2D(shadowtex0, shadowPos.xy).r);
        float visibility1 = step(shadowPos.z, texture2D(shadowtex1, shadowPos.xy).r);
        return mix(shadowColor.rgb * visibility1, vec3(1.0f), visibility0);
    }

    vec3 shadowVisibilityDepth(vec3 shadowPos, out float depthDiff) {
        vec4 shadowColor = texture2D(shadowcolor0, shadowPos.xy);
        shadowColor.rgb = shadowColor.rgb * (1.0 - shadowColor.a);
        float visibility0 = step(shadowPos.z, texture2D(shadowtex0, shadowPos.xy).r);

        depthDiff = shadowPos.z - 4.0 * (texture2D(shadowtex1, shadowPos.xy).r - 0.5);
        float visibility1 = step(0.0, -depthDiff);
        return mix(shadowColor.rgb * visibility1, vec3(1.0f), visibility0);
    }

    vec3 calcShadowPosView(vec3 viewPos, mat4 inverseModelViewMatrix) {
        vec4 playerPos = inverseModelViewMatrix * vec4(viewPos, 1.0);
        vec3 shadowPos = (shadowProjection * (shadowModelView * playerPos)).xyz;
        // float sClipLen = length(shadowPos.xy);

        // float distortFactor = getDistortFactor(shadowPos.xy);
        // shadowPos.xyz = distort(shadowPos.xyz, distortFactor); //apply shadow distortion
        // shadowPos = shadowDistortion(shadowPos.xyz);
        shadowPos = distort(shadowPos);

        return shadowPos * 0.5 + 0.5;
    }

    vec3 calcShadowPosScene(vec3 scenePos) {
        vec3 shadowPos = (shadowProjection * (shadowModelView * vec4(scenePos, 1.0))).xyz;
        // float sClipLen = length(shadowPos.xy);

        // float distortFactor = getDistortFactor(shadowPos.xy);
        // shadowPos.xyz = distort(shadowPos.xyz, distortFactor); //apply shadow distortion
        // shadowPos = shadowDistortion(shadowPos.xyz);
        shadowPos = distort(shadowPos);

        return shadowPos.xyz * 0.5 + 0.5; //convert from -1 ~ +1 to 0 ~ 1
    }

    void applyShadowBias(inout vec3 shadowPos, float NGdotL) {
        shadowPos.z -= Shadow_Bias / abs(NGdotL);
        // shadowPos.z -= getShadowBias(NGdotL) * shadowDistortionDerivativeInverse(length(shadowPos.xy));
    }

    vec4 applyShadowBiasClipSpace(vec4 shadowPos, float NGdotL) {
        return vec4(shadowPos.xy, shadowPos.z + (2 * Shadow_Bias / abs(NGdotL) * shadowPos.w), shadowPos.w);
        // shadowPos.z -= getShadowBias(NGdotL) * shadowDistortionDerivativeInverse(length(shadowPos.xy));
    }

    void applyShadowBias(inout float depth, float NGdotL) {
        depth += Shadow_Bias / abs(NGdotL);
        // depth += s
    }

    vec3 softShadows(vec3 shadowPos, float clipLen, float penumbra, int samples, float angle) {
        if(clamp(shadowPos.xy, 0.0, 1.0) != shadowPos.xy)
            return vec3(1.0);
        
        vec3 shadowVal = vec3(0.0);
        // float distortFactor = shadowDistortionDerivative(clipLen) * 6.0;
        // distortFactor = 1.0;
        for(int i = 0; i < samples; i++) {
            vec3 shadowPosTemp = shadowPos;
            shadowPosTemp.xy += penumbra /* * distortFactor */ * GetVogelDiskSample(i, samples, angle);
            shadowVal += shadowVisibility(shadowPosTemp);
        }

        return mix(shadowVal / samples, vec3(1.0), smoothstep(0.8, 0.9, min2(abs(shadowPos.xy * 2.0 - 1.0))));
    }

    vec3 pcssShadows(vec3 scenePos, vec2 texcoord, float NGdotL, vec3 sceneNormal, out float blockerDepth, vec2 screenSize, int frameCounter) {
        vec3 shadowPos = (shadowProjection * (shadowModelView * vec4(scenePos, 1.0))).xyz; //convert to shadow screen space
        // float distortFactor = getDistortFactor(shadowPos.xy);
        // shadowPos.xyz = distort(shadowPos.xyz, distortFactor); //apply shadow distortion
        // shadowPos.xyz = shadowPos.xyz * 0.5 + 0.5; //convert from -1 ~ +1 to 0 ~ 1
        // shadowPos.z -= Shadow_Bias * (distortFactor * distortFactor) / abs(NGdotL); //apply shadow bias

        // vec3 shadowPos = calcShadowPos(viewPos, gbufferModelViewInverse);

        // if(shadowPos.x < -1.0 || shadowPos.x > 1.0 || shadowPos.y < -1.0 || shadowPos.y > 1.0)
        //     shadowPos.z = 0.0;

        vec3 shadowVal = vec3(0.0);
        #ifdef ShadowNoiseAnimated
            float randomAngle = interleaved_gradient(ivec2(texcoord * screenSize), frameCounter) * TAU;
            // float randomAngle = texture2D(noisetex, texcoord * 20.0 + frameTimeCounter).r * TAU;
        #else
            float randomAngle = interleaved_gradient(ivec2(texcoord * screenSize), 0) * TAU;
            // float randomAngle = texture2D(noisetex, texcoord).r * TAU;
        #endif

        // randomAngle = 0.0;

        float blockerDist = 0.0;
        float size = 0.0;
        for(int i = 0; i < ShadowBlockSamples; i++) {
            // dist = max(dist, abs(texture2D(shadowtex0, shadowPos.xy + rotation * 0.01 * shadowKernel[i]).r - shadowPos.z));
            vec3 shadowPosTemp = shadowPos;
            shadowPosTemp.xy += ShadowMaxBlur * 0.2 * GetVogelDiskSample(i, ShadowBlockSamples, randomAngle);

            // float distortFactor = getDistortFactor(shadowPosTemp.xy);
            // shadowPosTemp.xyz = distort(shadowPosTemp.xyz, distortFactor); //apply shadow distortion
            // shadowPosTemp.xyz = shadowPosTemp.xyz * 0.5 + 0.5; //convert from -1 ~ +1 to 0 ~ 1
            // shadowPosTemp.z -= Shadow_Bias /* * (distortFactor * distortFactor) */ / abs(NGdotL); //apply shadow bias

            // shadowPosTemp = shadowDistortion(shadowPosTemp, length(shadowPosTemp.xy));
            shadowPosTemp = distort(shadowPosTemp);
            shadowPosTemp.xyz = shadowPosTemp.xyz * 0.5 + 0.5;

            // float a = texture2D(shadowtex0, shadowPosTemp.xy).r - shadowPosTemp.z;
            float sampleDepth = texture2D(shadowtex0, shadowPosTemp.xy).r;
            if(sampleDepth < shadowPos.z * 0.25 + 0.5) {
                blockerDist += abs(sampleDepth);
                size += 1.0;
            }
        }
        blockerDist /= size;


        float shadowClipLen = length(shadowPos.xy);

        // float distortFactor = getDistortFactor(shadowPos.xy);
        // shadowPos.xyz = distort(shadowPos.xyz, distortFactor); //apply shadow distortion

        float bias = computeBias(shadowPos);

        // shadowPos = shadowDistortion(shadowPos, length(shadowPos.xy));
        shadowPos = distort(shadowPos);
        shadowPos.xyz = shadowPos.xyz * 0.5 + 0.5; //convert from -1 ~ +1 to 0 ~ 1

        // shadowPos = calcShadowPos(viewPos, gbufferModelViewInverse);

        blockerDepth = shadowPos.z - blockerDist;

        // float penumbra = min(ShadowBlurScale * dist + ShadowMinBlur, ShadowMaxBlur);
        // float penumbra = min(ShadowBlurScale * blockerDepth / blockerDist + ShadowMinBlur, ShadowMaxBlur);
        float penumbra = min(ShadowBlurScale * (shadowPos.z - blockerDist) / blockerDist, ShadowMaxBlur);
        // penumbra = 0.0004;
        // float penumbra = 0.0000001 * (shadowPos.z - dist) / dist;
        // float penumbra = 0.4 * dist + 0.0001;
        // penumbra *= float(penumbra < 0.03);
        // float penumbra = 1000.0 * abs(shadowPos.z - texture2D(shadowtex0, shadowPos.xy).r);
        // penumbra = 2.0;
        // penumbra = 0.0;

        // shadowPos.z -= Shadow_Bias /* * (distortFactor * distortFactor) */ / abs(NGdotL); //apply shadow bias
        // applyShadowBias(shadowPos, NGdotL);
        
        // shadowPos.z -= getShadowBias(NGdotL, shadowClipLen);

        #ifdef Shadow_NormalBias
            //we are allowed to project the normal because shadowProjection is purely a scalar matrix.
			//a faster way to apply the same operation would be to multiply by shadowProjection[0][0].
			vec4 normal = shadowProjection * vec4(mat3(shadowModelView) * sceneNormal, 1.0);
			shadowPos.xyz += normal.xyz / normal.w * bias;
        #else
            shadowPos.z -= bias / abs(NGdotL);
        #endif

        // shadowPos.xyz += mat3(shadowProjection) * (mat3(shadowModelView) * normal) * (16.0 / shadowMapResolution);

        vec3 shadowResult = softShadows(shadowPos, shadowClipLen, penumbra, ShadowSamples, randomAngle);
        return shadowResult /* * (float(abs(NGdotL) >= 0.01)) */;
    }

    void volumetricFog(inout vec3 sceneColor, vec3 sceneOrigin, vec3 sceneEnd, vec2 texcoord, vec3 SunMoonColor, vec2 screenSize, float fogDensityMult, int frameCounter, float frameTimeCounter, vec3 cameraPosition) {
        #ifdef ShadowNoiseAnimated
            float randomVal = interleaved_gradient(ivec2(texcoord * screenSize), frameCounter);
            float randomAngle = randomVal * TAU;
        #else
            float randomVal = interleaved_gradient(ivec2(texcoord * screenSize), 0);
            float randomAngle = randomVal * TAU;
        #endif

        vec3 shadowOrigin = (shadowProjection * (shadowModelView * vec4(sceneOrigin, 1.0))).xyz;
        vec3 shadowEnd = clamp((shadowProjection * (shadowModelView * vec4(sceneEnd, 1.0))).xyz, vec3(-1.0), vec3(1.0));
        
        vec3 rayIncrement = (shadowOrigin - shadowEnd) / VolFog_Steps;
        // float startOffset = texture2D(noisetex, fract(texcoord * screenSize / 256 + sin(1000*frameTimeCounter))).r;
        // startOffset = fract(startOffset + mod(frameTimeCounter, 64.0) * goldenRatioConjugate);
        // vec3 currentViewPos = 0 * normalize(viewPos);
        vec3 shadowPos = shadowEnd - randomVal * rayIncrement * 1.8;
        // rayIncrement -= randomVal * rayIncrement * 1.8 / VolFog_Steps;
        vec3 shadowAmount = vec3(0.0);
        // vec3 noiseAmount  = vec3(VolFog_Steps);
        for(int i = 0; i < VolFog_Steps; i++) {
            shadowPos += rayIncrement;
            // vec3 shadowScreenPos = shadowDistortion(shadowPos) * 0.5 + 0.5;
            vec3 shadowScreenPos = distort(shadowPos) * 0.5 + 0.5;
            // float shadowDepth = texture2D(shadowtex0, shadowPos.xy).r;
            // if(shadowPos.z < shadowDepth) {
            //     shadowAmount += 1.0;
            // }
            // if(fogDensityMult > 0.1) {
            //     vec3 worldPos = currentScenePos + cameraPosition;
            //     noiseAmount -= 0.4 * SimplexPerlin3D(1.0 * worldPos + 0.5 * frameTimeCounter);
            //     noiseAmount -= 0.6 * SimplexPerlin3D(0.3 * worldPos + 0.3 * frameTimeCounter);
            // }

            // shadowAmount += noise * 0.5 + 0.5;

            #ifdef VolFog_SmoothShadows
                shadowAmount += softShadows(shadowScreenPos, VolFog_SmoothShadowBlur, VolFog_SmoothShadowSamples, randomAngle, shadowtex0, shadowtex1, shadowcolor0);
            #else
                #ifdef VolFog_Colored
                    shadowAmount += shadowVisibility(shadowScreenPos);
                #else
                    shadowAmount += step(shadowScreenPos.z, texture2D(shadowtex0, shadowScreenPos.xy).r);
                #endif
            #endif
        }
        shadowAmount /= VolFog_Steps;
        // noiseAmount /= VolFog_Steps;

        // float density = clamp(-1.0 + exp(length(viewPos) * 0.003), 0.0, 1.0);
        // vec3 fogColor = mix(vec3(0.5, 0.6, 0.7), vec3(0.0), 1.0-shadowAmount);
        // albedo.rgb = mix(albedo.rgb, fogColor, density);

        #ifdef inEnd
            vec3 coefs = 2 * vec3(0.006, 0.005, 0.007);
        #else
            vec3 coefs = mix(10.0, 500.0, fogDensityMult) * vec3(2.0, 1.5, 1.0)*vec3(0.0000038, 0.0000105, 0.0000331);
        #endif

        vec3 fogColorUse = mix(SunMoonColor*0.5, SunMoonColor, shadowAmount);
        fogColorUse *= mix(vec3(1.0), 2*vec3(1.8, 1.3, 1.03), shadowAmount * pow(linstep(0.85, 1.0, dot(normalize(sceneEnd), lightDir)), 2.0));
        // fogColorUse *= (noiseAmount * 0.8 + 1.2);
        // vec3 fogColorUse = SunMoonColor;
        // if(inNether)
        //     fogColorUse = fogColor;
        float dist = length(sceneEnd - sceneOrigin);
        // vec3 extColor = vec3(exp(-dist*be.x), exp(-dist*be.y), exp(-dist*be.z));
        // vec3 insColor = vec3(exp(-dist*bi.x), exp(-dist*bi.y), exp(-dist*bi.z));
        vec3 fogFactor = vec3(exp(-dist*coefs.r), exp(-dist*coefs.g), exp(-dist*coefs.b));
        // fogFactor = noiseAmount * 0.5 + 0.5;

        // albedo = sRGBToLinear(albedo);
        // albedo.rgb =  fogColor*(1.0-extColor) +  albedo.rgb*insColor;
        sceneColor = mix(fogColorUse, sceneColor, fogFactor);
        // albedo = linearToSRGB(albedo);

        // albedo.rgb = fogColor;

        // albedo.rgb += shadowAmount * 2*vec3(0.13, 0.1, 0.08);
    }


    void waterVolumetricFog(vec3 sceneOrigin, vec3 sceneEnd, vec3 directLight, vec3 ambientLight, vec3 waterColorSmooth, inout vec3 sceneColor, vec2 texcoord, vec2 screenSize, int frameCounter) {
        
        #ifdef ShadowNoiseAnimated
            float randomVal = interleaved_gradient(ivec2(texcoord * screenSize), frameCounter);
            float randomAngle = randomVal * TAU;
        #else
            float randomVal = interleaved_gradient(ivec2(texcoord * screenSize), 0);
            float randomAngle = randomVal * TAU;
        #endif

        // float rayLengthMult = length(sceneEnd - sceneOrigin) / min(length(sceneEnd - sceneOrigin), 1.0);

        vec3 shadowOrigin = (shadowProjection * (shadowModelView * vec4(sceneOrigin, 1.0))).xyz;
        vec3 shadowEnd = (shadowProjection * (shadowModelView * vec4(sceneEnd, 1.0))).xyz;

        vec3 rayIncrement = (shadowOrigin - shadowEnd) / VolWater_Steps;
        rayIncrement -= randomVal * rayIncrement * 1.8 / VolWater_Steps;
        vec3 shadowPos = shadowEnd + rayIncrement;

        // vec3 shadowScreenPos = shadowDistortion(shadowPos) * 0.5 + 0.5;
        vec3 shadowScreenPos = distort(shadowPos) * 0.5 + 0.5;

        #ifdef VolWater_Colored
            vec3 shadowAmount = shadowVisibility(shadowScreenPos);
        #else
            float shadowAmount += step(shadowScreenPos.z, texture2D(shadowtex1, shadowScreenPos.xy).r);
        #endif

        for(int i = 1; i < VolWater_Steps; i++) {
            shadowPos += rayIncrement;

            // shadowScreenPos = shadowDistortion(shadowPos) * 0.5 + 0.5;
            vec3 shadowScreenPos = distort(shadowPos) * 0.5 + 0.5;

            #ifdef VolWater_Colored
                shadowAmount = mix(shadowAmount, shadowVisibility(shadowScreenPos), vec3(3.0/VolWater_Steps));
            #else
                shadowAmount += mix(shadowAmount, step(shadowScreenPos.z, texture2D(shadowtex1, shadowScreenPos.xy).r), 3.0/VolWater_Steps);
            #endif
        }

        // shadowAmount /= VolWater_Steps;

        // vec3 fog = light * 0.25 * (shadowAmount * vec3(0.2, 0.5, 0.5) + vec3(0.05, 0.09, 0.12));
        // vec3 fog = mix(sRGBToLinear3(waterColorSmooth), vec3(0.25, 0.3, 0.4), 0.5);
        // fog = 0.25 * light * (shadowAmount * 0.9 + fog * 0.1);

        // vec3 fog = (light * 0.15 + 0.02) * mix(sRGBToLinear3(waterColorSmooth), vec3(0.25, 0.3, 0.4), 0.4);
        // fog = mix(fog, shadowAmount, shadowAmount);
        vec3 fog = (0.1 * directLight * shadowAmount) + (0.2 * ambientLight * mix(sRGBToLinear3(waterColorSmooth), vec3(0.25, 0.3, 0.4), 0.4));

        sceneColor = mix(fog, sceneColor, exp(-0.06 * length(sceneEnd - sceneOrigin)));
    }

#endif

#endif