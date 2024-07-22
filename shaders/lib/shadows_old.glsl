
#include "/lib/sample.glsl"


// Shadow Distortion taken from Shadow Tutorial pack by builderb0y

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

    // Calculates the unfiltered colored shadow value from a given shadowScreenPos
    vec3 shadowVisibility(vec3 shadowPos) {
        #if Shadow_Transparent == 0
            return vec3(step(shadowPos.z, texture(shadowtex1, shadowPos.xy)));
        #elif Shadow_Transparent == 1
            return vec3(step(shadowPos.z, texture(shadowtex0, shadowPos.xy)));
        #else
            vec4 shadowColor = texture2D(shadowcolor0, shadowPos.xy);
            shadowColor.rgb = shadowColor.rgb * (1.0 - shadowColor.a);

            float visibility0 = step(shadowPos.z, texture2D(shadowtex0, shadowPos.xy).r);
            float visibility1 = step(shadowPos.z, texture2D(shadowtex1, shadowPos.xy).r);

            return mix(shadowColor.rgb * visibility1, vec3(1.0), visibility0);
        #endif
    }

    // Calculates the unfiltered colored shadow value from a given shadowScreenPos
    // and outputs the difference in depth from the position and the shadow map
    vec3 shadowVisibilityDepth(vec3 shadowPos, out float depthDiff) {
        vec4 shadowColor = texture2D(shadowcolor0, shadowPos.xy);
        shadowColor.rgb = shadowColor.rgb * (1.0 - shadowColor.a);
        float visibility0 = step(shadowPos.z, texture2D(shadowtex0, shadowPos.xy).r);

        depthDiff = shadowPos.z - 4.0 * (texture2D(shadowtex1, shadowPos.xy).r - 0.5);
        float visibility1 = step(0.0, -depthDiff);
        return mix(shadowColor.rgb * visibility1, vec3(1.0), visibility0);
    }

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

    // Applies bias to un-distorted shadow position with bias multiplier
    void applyShadowBias(inout vec3 shadowPos, float NdotL, float mult) {
        shadowPos.z -= mult * computeBias(shadowPos) / abs(NdotL);
    }

    // Applies normal offset bias with multiplier to un-distorted shadow position given worldspace alligned normal
    void applyShadowNormalBias(inout vec3 shadowPos, vec3 worldNormal, float mult) {
        //we are allowed to project the normal because shadowProjection is purely a scalar matrix.
        //a faster way to apply the same operation would be to multiply by shadowProjection[0][0].
        float bias = mult * computeBias(shadowPos);
        vec4 normal = shadowProjection * vec4(mat3(shadowModelView) * worldNormal, 1.0);
        shadowPos.xyz += normal.xyz / normal.w * bias;
    }

    // Applies normal offset bias to un-distorted shadow position given worldspace alligned normal
    void applyShadowNormalBias(inout vec3 shadowPos, vec3 worldNormal) {
        applyShadowNormalBias(shadowPos, worldNormal, 1.0);
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

    // Converts un-distorted shadowpos to distorted shadowpos and applies bias with multiplier
    void distortShadowPosBias(inout vec3 shadowPos, float NdotL, float mult) {
        applyShadowBias(shadowPos, NdotL, mult);
        shadowPos = distort(shadowPos);
        shadowPos = shadowPos * 0.5 + 0.5; //convert from -1 ~ +1 to 0 ~ 1
    }

    // Converts un-distorted shadowpos to distorted shadowpos and applies normal offset bias
    void distortShadowPosNormalBias(inout vec3 shadowPos, vec3 worldNormal) {
        applyShadowNormalBias(shadowPos, worldNormal);
        shadowPos = distort(shadowPos);
        shadowPos = shadowPos * 0.5 + 0.5; //convert from -1 ~ +1 to 0 ~ 1
    }

    // Converts un-distorted shadowpos to distorted shadowpos and applies normal offset bias with multiplier
    void distortShadowPosNormalBias(inout vec3 shadowPos, vec3 worldNormal, float mult) {
        applyShadowNormalBias(shadowPos, worldNormal, mult);
        shadowPos = distort(shadowPos);
        shadowPos = shadowPos * 0.5 + 0.5; //convert from -1 ~ +1 to 0 ~ 1
    }

    // Samples the shadow map using PCF filtering given shadowScreenPos already distorted and biased
    // and using a vogel disk for filtering
    vec3 sampleShadowPCF(vec3 shadowScreenPos, float penumbra, int samples, float ditherAngle) {
        
        vec3 shadowVal = vec3(0.0);
        for(int i = 0; i < samples; i++) {
            vec3 shadowPosTemp = shadowScreenPos;
            shadowPosTemp.xy += penumbra * GetVogelDiskSample(i, samples, ditherAngle);
            shadowVal += shadowVisibility(shadowPosTemp);
        }

        return shadowVal / samples;
    }

    // Samples the shadow map using PCF filtering given shadowScreenPos already distorted and biased
    // and using a vogel disk for filtering
    vec3 sampleShadowPCFDistortPerSample(vec3 shadowPos, float NdotL, float penumbra, int samples, float ditherAngle) {
        
        vec3 shadowVal = vec3(0.0);
        for(int i = 0; i < samples; i++) {
            vec3 shadowPosTemp = shadowPos;
            shadowPosTemp.xy += penumbra * GetVogelDiskSample(i, samples, ditherAngle);
            distortShadowPosBias(shadowPosTemp, NdotL);
            shadowVal += shadowVisibility(shadowPosTemp);
        }

        return shadowVal / samples;
    }

    // Samples the shadow map using PCF filtering given un-distorted shadowClipPos without bias.
    // Applies bias based on penumbra size, applies distortion, and uses a vogel disk for filtering
    vec3 sampleShadowPCFDistortBias(vec3 shadowClipPos, float NdotL, float penumbra, int samples, float ditherAngle) {

        distortShadowPosBias(shadowClipPos, NdotL, 1 + 800.0*penumbra);
        
        return sampleShadowPCF(shadowClipPos, penumbra, samples, ditherAngle);
    }

    // Samples the shadow map using PCF filtering given un-distorted shadowClipPos without bias.
    // Applies normal offset bias based on penumbra size, applies distortion, and uses a vogel disk for filtering
    vec3 sampleShadowPCFDistortNormalBias(vec3 shadowClipPos, vec3 worldNormal, float penumbra, int samples, float ditherAngle) {

        distortShadowPosNormalBias(shadowClipPos, worldNormal, 1 + 1800.0*penumbra);
        
        return sampleShadowPCF(shadowClipPos, penumbra, samples, ditherAngle);
    }

    float PCSSPenumbraSize(vec3 shadowClipPos, float ditherAngle) {
        float avgBlockerDepth = 0.0;
        float blockerCount = 0.0;
        for(int i = 0; i < ShadowBlockSamples; i++) {
            vec3 shadowPosBlocker = shadowClipPos;
            shadowPosBlocker.xy += ShadowMaxBlur * 0.2 * GetVogelDiskSample(i, ShadowBlockSamples, ditherAngle);
            distortShadowPos(shadowPosBlocker);

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
        
        // float penumbra = (shadowScreenPos.z - avgBlockerDepth) / avgBlockerDepth;
        // penumbra *= penumbra;
        return min(ShadowBlurScale * ((shadowClipPos.z * 0.25 + 0.5) - avgBlockerDepth) / avgBlockerDepth, ShadowMaxBlur);
    }

    // Samples the shadow map using PCSS filtering given un-distorted shadowClipPos without bias
    // applies variable penumbra PCF filtering
    vec3 sampleShadowPCSS(vec3 shadowClipPos, float NdotL, float ditherAngle) {

        float penumbra = PCSSPenumbraSize(shadowClipPos, ditherAngle);

        return sampleShadowPCFDistortPerSample(shadowClipPos, NdotL, penumbra, ShadowSamples, ditherAngle);
    }

    // Samples the shadow map using PCSS filtering given un-distorted shadowClipPos without bias
    // applies variable penumbra PCF filtering
    vec3 sampleShadowPCSSNormalBias(vec3 shadowClipPos, vec3 worldNormal, float ditherAngle) {

        float penumbra = PCSSPenumbraSize(shadowClipPos, ditherAngle);

        return sampleShadowPCFDistortNormalBias(shadowClipPos, worldNormal, penumbra, ShadowSamples, ditherAngle);
    }

#endif