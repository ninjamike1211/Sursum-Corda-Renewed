
#include "/lib/sample.glsl"


// Shadow Distortion taken from Shadow Tutorial pack by builderb0y

vec3 distort(vec3 pos) {
    float factor = length(pos.xy) + Shadow_Distort_Factor;
    return vec3(pos.xy / factor, pos.z * 0.5);
}

//returns the reciprocal of the derivative of our distort function,
//multiplied by Shadow_Bias.
//if a texel in the shadow map contains a bigger area,
//then we need more bias. therefore, we need to know how much
//bigger or smaller a pixel gets as a result of applying sistortion.
float computeBias(vec3 pos) {
    //square(length(pos.xy) + Shadow_Distort_Factor) / Shadow_Distort_Factor
    float numerator = length(pos.xy) + Shadow_Distort_Factor;
    numerator *= numerator;
    return Shadow_Bias / shadowMapResolution * numerator / Shadow_Distort_Factor;
}


#ifndef shadowGbuffer

    // Converts viewPos to shadowClipPos without distortion or bias
    vec3 calcShadowPosView(vec3 viewPos, mat4 inverseModelViewMatrix) {
        vec4 playerPos = inverseModelViewMatrix * vec4(viewPos, 1.0);
        return (shadowProjection * (shadowModelView * playerPos)).xyz;
    }

    // Converts scenePos (feetPlayerPos) to shadowClipPos without distortion or bias
    vec3 calcShadowPosScene(vec3 scenePos) {
        return (shadowProjection * (shadowModelView * vec4(scenePos, 1.0))).xyz;
    }

    // Applies bias to un-distorted shadow position
    void applyShadowBias(inout vec3 shadowPos, float NdotL) {
        shadowPos.z -= computeBias(shadowPos) / abs(NdotL);
    }

    // Applies normal offset bias with multiplier to un-distorted shadow position given worldspace alligned normal
    void applyShadowNormalBias(inout vec3 shadowPos, vec3 worldNormal) {
        //we are allowed to project the normal because shadowProjection is purely a scalar matrix.
        //a faster way to apply the same operation would be to multiply by shadowProjection[0][0].
        float bias = computeBias(shadowPos);
        vec4 normal = shadowProjection * vec4(mat3(shadowModelView) * worldNormal, 1.0);
        shadowPos.xyz += normal.xyz / normal.w * bias;
    }

    // Converts un-distorted shadowpos to distorted shadowpos
    void distortShadowPos(inout vec3 shadowPos) {
        shadowPos = distort(shadowPos);
        shadowPos = shadowPos * 0.5 + 0.5; //convert from -1 ~ +1 to 0 ~ 1
    }

    // Converts un-distorted shadowpos to distorted shadowpos and applies bias
    void distortShadowPosBias(inout vec3 shadowPos, float NdotL) {
        applyShadowBias(shadowPos, NdotL);
        shadowPos = distort(shadowPos);
        shadowPos = shadowPos * 0.5 + 0.5; //convert from -1 ~ +1 to 0 ~ 1
    }

    // Converts un-distorted shadowpos to distorted shadowpos and applies normal offset bias
    void distortShadowPosNormalBias(inout vec3 shadowPos, vec3 worldNormal) {
        applyShadowNormalBias(shadowPos, worldNormal);
        shadowPos = distort(shadowPos);
        shadowPos = shadowPos * 0.5 + 0.5; //convert from -1 ~ +1 to 0 ~ 1
    }

    // Calculates the unfiltered colored shadow value from a given shadowScreenPos
    vec3 shadowVisibility(vec3 shadowScreenPos) {
        #if Shadow_Transparent == 0
            return vec3(step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy)));
        #elif Shadow_Transparent == 1
            return vec3(step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy)));
        #else
            vec4 shadowColor = texture2D(shadowcolor0, shadowScreenPos.xy);
            shadowColor.rgb = shadowColor.rgb * (1.0 - shadowColor.a);

            float visibility0 = step(shadowScreenPos.z, texture2D(shadowtex0, shadowScreenPos.xy).r);
            float visibility1 = step(shadowScreenPos.z, texture2D(shadowtex1, shadowScreenPos.xy).r);

            return mix(shadowColor.rgb * visibility1, vec3(1.0), visibility0);
        #endif
    }

    // Samples the shadow map without filtering, applying distortion and bias
    vec3 sampleShadow(vec3 shadowPos, float NdotL) {
        distortShadowPosBias(shadowPos, NdotL);
        return shadowVisibility(shadowPos);
    }
    
    // Samples the shadow map without filtering, applying distortion and normal offset bias
    vec3 sampleShadowNormalBias(vec3 shadowPos, vec3 worldNormal) {
        distortShadowPosNormalBias(shadowPos, worldNormal);
        return shadowVisibility(shadowPos);
    }

    // Samples the shadow map using PCF filtering, applying distortion and bias per sample
    vec3 sampleShadowPCF(vec3 shadowPos, float NdotL, float penumbra, int samples, float ditherAngle) {
        
        vec3 shadowVal = vec3(0.0);
        for(int i = 0; i < samples; i++) {
            vec3 shadowPosTemp = shadowPos;
            shadowPosTemp.xy += penumbra * GetVogelDiskSample(i, samples, ditherAngle);
            distortShadowPosBias(shadowPosTemp, NdotL);
            shadowVal += shadowVisibility(shadowPosTemp);
        }

        return shadowVal / samples;
    }

    // Samples the shadow map using PCF filtering, applying distortion and normal offset bias per sample
    vec3 sampleShadowPCFNormalBias(vec3 shadowPos, vec3 worldNormal, float penumbra, int samples, float ditherAngle) {
        
        vec3 shadowVal = vec3(0.0);
        for(int i = 0; i < samples; i++) {
            vec3 shadowPosTemp = shadowPos;
            shadowPosTemp.xy += penumbra * GetVogelDiskSample(i, samples, ditherAngle);
            distortShadowPosNormalBias(shadowPosTemp, worldNormal);
            shadowVal += shadowVisibility(shadowPosTemp);
        }

        return shadowVal / samples;
    }

    float PCSSBlockerDist(vec3 shadowClipPos, float NdotL, float ditherAngle) {
        float avgBlockerDepth = 0.0;
        float blockerCount = 0.0;
        for(int i = 0; i < Shadow_PCSS_BlockSamples; i++) {
            vec3 shadowPosBlocker = shadowClipPos;
            shadowPosBlocker.xy += Shadow_PCSS_BlockRadius * 0.2 * GetVogelDiskSample(i, Shadow_PCSS_BlockSamples, ditherAngle);
            distortShadowPosBias(shadowPosBlocker, NdotL);

            float blockerDepth = texture(shadowtex0, shadowPosBlocker.xy).r;
            if(blockerDepth < shadowPosBlocker.z) {
                avgBlockerDepth += blockerDepth;
                blockerCount++;
            }
        }

        if(blockerCount > 0.0)
            avgBlockerDepth /= blockerCount;
        else
            avgBlockerDepth = 0.0;
        
        return avgBlockerDepth;
    }

    float PCSSBlockerDistNormalBias(vec3 shadowClipPos, vec3 worldNormal, float ditherAngle) {
        float avgBlockerDepth = 0.0;
        float blockerCount = 0.0;
        for(int i = 0; i < Shadow_PCSS_BlockSamples; i++) {
            vec3 shadowPosBlocker = shadowClipPos;
            shadowPosBlocker.xy += Shadow_PCSS_BlockRadius * 0.2 * GetVogelDiskSample(i, Shadow_PCSS_BlockSamples, ditherAngle);
            distortShadowPosNormalBias(shadowPosBlocker, worldNormal);

            float blockerDepth = texture(shadowtex0, shadowPosBlocker.xy).r;
            if(blockerDepth < shadowPosBlocker.z) {
                avgBlockerDepth += blockerDepth;
                blockerCount++;
            }
        }

        if(blockerCount > 0.0)
            avgBlockerDepth /= blockerCount;
        else
            avgBlockerDepth = 0.0;
        
        return avgBlockerDepth;
    }

    // Calculates the PCSS penumbra size given shadow pos in clip space, and a dither value
    float PCSSPenumbraSize(vec3 shadowClipPos, float avgBlockerDepth) {
        return clamp(Shadow_PCSS_BlurScale * ((shadowClipPos.z * 0.25 + 0.5) - avgBlockerDepth) / avgBlockerDepth, Shadow_PCSS_MinBlur, Shadow_PCSS_MaxBlur);
    }

    // Samples the shadow map using PCSS filtering, applying distortion and bias
    vec3 sampleShadowPCSS(vec3 shadowClipPos, float NdotL, float ditherAngle) {

        float avgBlockerDepth = PCSSBlockerDist(shadowClipPos, NdotL, ditherAngle);
        float penumbra = PCSSPenumbraSize(shadowClipPos, avgBlockerDepth);

        return sampleShadowPCF(shadowClipPos, NdotL, penumbra, Shadow_PCF_Samples, ditherAngle);
    }

    // Samples the shadow map using PCSS filtering, applying distortion and normal offset bias
    vec3 sampleShadowPCSSNormalBias(vec3 shadowClipPos, vec3 worldNormal, float ditherAngle) {

        float avgBlockerDepth = PCSSBlockerDistNormalBias(shadowClipPos, worldNormal, ditherAngle);
        float penumbra = PCSSPenumbraSize(shadowClipPos, avgBlockerDepth);

        return sampleShadowPCFNormalBias(shadowClipPos, worldNormal, penumbra, Shadow_PCF_Samples, ditherAngle);
    }

#endif