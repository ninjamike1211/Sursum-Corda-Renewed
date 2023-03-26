#ifndef MATERIAL
#define MATERIAL


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

float getEmissiveness(vec4 specMap) {
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

#endif