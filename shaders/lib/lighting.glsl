#include "/lib/functions.glsl"


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
    float roughness = getRoughness(specMap);

    vec3 fresnel = calcFresnel(max(dot(halfwayDir, viewDir), 0.0), specMap, albedo);
    float geometry = GeometrySmith(normal, viewDir, lightDir, roughness);
    float distribution = DistributionGGX(normal, halfwayDir, roughness);

    vec3 diffuse = albedo / PI * (1.0 - fresnel) * (1.0 - metalness);
    vec3 specular = (fresnel * geometry * distribution) / max(4.0 * dot(viewDir, normal) * dot(lightDir, normal), 0.001);

    return (diffuse + specular) * light * max(dot(normal, lightDir), 0.0);
}

vec3 adjustLightMap(vec2 lmcoord, vec3 lightColor) {

    lmcoord = pow(lmcoord, vec2(2.0));

    vec3 skyAmbient = mix(vec3(0.06), 4 * lightColor, lmcoord.y);
    vec3 torchAmbient = mix(vec3(0.0), 1.5*vec3(15.0, 7.2, 2.9), lmcoord.x);

    return skyAmbient + torchAmbient;
}

vec3 calcAmbient(vec3 albedo, vec2 lmcoord, vec3 skyAmbient, vec4 specMap) {
    vec3 light = adjustLightMap(lmcoord, skyAmbient);
    
    float emissiveness = specMap.a > 254.5/255.0 ? 0.0 : specMap.a * EmissiveStrength;
    bool isHardcodedMetal = isMetallic(specMap) == 1;

    #ifdef AmbientMetalHardcodeAlbedo
        if(isHardcodedMetal) {
            vec3 F0, F82;
            int index = int(specMap.g * 255.0 + 0.5) - 230;
            hardcodeMetalValue(index, F0, F82);

            albedo = mix(0.2 * F0, 0.1 * F82, clamp(10.0 * getRoughness(specMap), 0.0, 1.0));
        }
    #else
        albedo *= (isHardcodedMetal ? AmbientMetalAlbedoMult : 1.0);
    #endif

    
    return albedo * (light * 0.2 + 10.0 * emissiveness);
}