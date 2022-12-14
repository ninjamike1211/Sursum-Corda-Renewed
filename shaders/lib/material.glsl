#ifndef  MATERIAL
#define MATERIAL

/*
	Normals encoding and decoding based on Spectrum by Zombye, a orthogonal approach
*/
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

float extractSubsurface(vec4 specMap) {
    return specMap.b > 64.5/255.0 ? (specMap.b - 65.0/255.0) * 255.0/190.0 : 0.0;
}

#endif