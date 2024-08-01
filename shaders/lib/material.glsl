#ifndef MATERIAL
#define MATERIAL

#include "/lib/defines.glsl"
#include "/lib/functions.glsl"


vec3 extractNormalZ(vec2 normal) {
	// return vec3(normal, sqrt(1.0 - dot(normal.xy, normal.xy)));
	return vec3(normal, sqrt(max(1.0 - dot(normal.xy, normal.xy), 0.0)));
}

/*
	Normals encoding and decoding based on Spectrum by Zombye, a orthogonal approach
*/

vec2 packNormalVec2(vec3 normal) {
	normal.xy /= abs(normal.x) + abs(normal.y) + abs(normal.z);
	return (normal.z <= 0.0 ? (1.0 - abs(normal.yx)) * vec2(normal.x >= 0.0 ? 1.0 : -1.0, normal.y >= 0.0 ? 1.0 : -1.0) : normal.xy) * 0.5 + 0.5;
}

vec3 unpackNormalVec2(vec2 encodedNormal) {

	vec2 vecNorm = encodedNormal * 2.0 - 1.0;
	vec3 normal = vec3(vecNorm, 1.0 - abs(vecNorm.x) - abs(vecNorm.y));
	float t = max(-normal.z, 0.0);
	normal.xy += vec2(normal.x >= 0.0 ? -t : t, normal.y >= 0.0 ? -t : t);
	return normalize(normal);
}

uint NormalEncode(vec3 normal) {
	normal.xy /= abs(normal.x) + abs(normal.y) + abs(normal.z);
	vec2 result = (normal.z <= 0.0 ? (1.0 - abs(normal.yx)) * vec2(normal.x >= 0.0 ? 1.0 : -1.0, normal.y >= 0.0 ? 1.0 : -1.0) : normal.xy) * 0.5 + 0.5;

	return packUnorm2x16(result);
}
vec3 NormalDecode(uint encodedNormal) {

	vec2 vecNorm = unpackUnorm2x16(encodedNormal) * 2.0 - 1.0;
	vec3 normal = vec3(vecNorm, 1.0 - abs(vecNorm.x) - abs(vecNorm.y));
	float t = max(-normal.z, 0.0);
	normal.xy += vec2(normal.x >= 0.0 ? -t : t, normal.y >= 0.0 ? -t : t);
	return normalize(normal);
}

uint SpecularEncode(vec4 specMap) {
	return packUnorm4x8(specMap);
}

vec4 SpecularDecode(uint encodedSpecMap) {
	return unpackUnorm4x8(encodedSpecMap);
}

float getRoughness(vec4 specMap) {
	return max(pow(1.0 - specMap.r, 2.0), 0.005);
}

float getSubsurface(vec4 specMap) {
    return specMap.b > 64.5/255.0 ? (specMap.b - 65.0/255.0) * 255.0/190.0 : 0.0;
}

float getEmissiveStrength(vec4 specMap) {
	return specMap.a > 254.5/255.0 ? 0.0 : specMap.a * EmissiveStrength;
}

// Returns whether a material is metallic or not, 0 means non-metallic, 1 means hardcoded metal, 2 means albedo based metal
int isMetallic(vec4 specMap) {
	if(specMap.g < 229.5/255.0) {
        return 0;
    }
    else if(specMap.g < 237.5/255.0) {
        return 1;
    }
    else {
        return 2;
    }
}

uint mcEntityMask(uint mcEntity) {
    uint mask = 0;

    if(mcEntity == MCEntity_Water)
        mask |= Mask_Water;
    

    return mask;
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

// Concept based on code from CyanEmber and Bálint
vec3 getDirectionalLightmapDir(vec3 position, float lightmap) {
    vec2 lmDeriv = vec2(dFdx(lightmap), dFdy(lightmap));

	vec3 xVec = dFdx(position) / lmDeriv.x;
	vec3 yVec = dFdy(position) / lmDeriv.y; 

    if(isnan(length(xVec)) && isnan(length(yVec))) {
        return vec3(0.0);
    }
    if(isnan(length(xVec))) {
        return normalize(yVec);
    }
    if(isnan(length(yVec))) {
        return normalize(xVec);
    }

	vec3 perpendicular = yVec - xVec;
	vec3 orthogonal = cross(xVec, yVec);
	return normalize(cross(perpendicular, orthogonal));
}

vec3 calcLightmap(vec2 lmcoord, vec3 skyAmbientLight) {
    vec3 blockAmbient = vec3(0.8, 0.5, 0.2) * lmcoord.x;
    // vec3 blockAmbient = vec3(0.8, 0.5, 0.2) * (exp2(lmcoord.x*15.0)-1.0) * 0.05;
    vec3 skyAmbient   = skyAmbientLight * lmcoord.y + 0.0002;
    // vec3 skyAmbient   = skyAmbientLight * (exp2(min(15.0, lmcoord.y*15.0+3))-0.9) * 0.00005;

    return blockAmbient + skyAmbient;
}

// Hardcoded metals fresnel function by Jessie#7257
vec3 Lazanyi2019(float cosTheta, in vec3 f0, in vec3 f82) {
    vec3 a = 17.6513846 * (f0 - f82) + 8.16666667 * (1.0 - f0);
    return clamp(f0 + (1.0 - f0) * pow(1.0 - cosTheta, 5.0) - a * cosTheta * pow(1.0 - cosTheta, 6.0), 0.0, 1.0);
}

vec3 fresnelSchlick(float cosTheta, vec3 F0) {
    return F0 + (1.0 - F0) * pow(max(1.0 - cosTheta, 0.0), 5.0);
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

vec3 cookTorrancePBRLighting(vec3 albedo, vec3 viewDir, vec3 normal, vec4 specMap, vec3 light, vec3 lightDir) {
    vec3 halfwayDir = normalize(viewDir + lightDir);

    float metalness = step(229.5/255.0, specMap.g);
    float roughness = getRoughness(specMap);

    vec3 fresnel = calcFresnel(max(dot(halfwayDir, viewDir), 0.0), specMap, albedo);
    float geometry = max(GeometrySmith(normal, viewDir, lightDir, roughness), 0.001);
    float distribution = DistributionGGX(normal, halfwayDir, roughness);

    vec3 diffuse = albedo / PI * (1.0 - fresnel) * (1.0 - metalness);
    vec3 specular = (fresnel * geometry * distribution) / max(4.0 * dot(viewDir, normal) * dot(lightDir, normal), 0.001);

    return (diffuse + specular) * light * max(dot(normal, lightDir), 0.0);
}

vec3 cookTorrancePBRReflection(vec3 albedo, vec3 viewDir, vec3 normal, vec4 specMap, vec3 light, vec3 lightDir) {
    vec3 halfwayDir = normalize(viewDir + lightDir);

    float roughness = getRoughness(specMap);

    vec3 fresnel = calcFresnel(max(dot(halfwayDir, viewDir), 0.0), specMap, albedo);
    float geometry = max(GeometrySmith(normal, viewDir, lightDir, roughness), 0.001);
    float distribution = DistributionGGX(normal, halfwayDir, roughness);

    vec3 specular = (fresnel * geometry * distribution) / max(4.0 * dot(viewDir, normal) * dot(lightDir, normal), 0.001);

    return specular * light * max(dot(normal, lightDir), 0.0);
}

#endif