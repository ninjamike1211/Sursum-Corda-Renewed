#ifndef SPACECONVERT
#define SPACECONVERT

// #include "/lib/kernels.glsl"
// #include "/lib/TAA.glsl"


float linearizeDepthFast(float depth, float near, float far) {
	return (near * far) / (depth * (near - far) + far);
}

float linearizeDepthNorm(float depth, float near, float far) {
	return (linearizeDepthFast(depth, near, far) - near) / (far - near);
}

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position) {
	vec4 homoPos = projectionMatrix * vec4(position, 1.0);
	return homoPos.xyz / homoPos.w;
}

vec3 calcViewPos(vec3 viewVector, float depth, mat4 projectionMatrix) {
	float viewZ = -projectionMatrix[3][2] / ((depth * 2.0 - 1.0) + projectionMatrix[2][2]);
	return viewVector * viewZ;
}

vec3 screenToView(vec2 texcoord, float depth, int frameCounter, vec2 screenSize, mat4 inverseProjectionMatrix) {
	vec3 ndcPos = vec3(texcoord * 2.0 - 1.0, depth * 2.0 - 1.0);

	#ifdef TAA
		ndcPos.xy -= taaOffset(frameCounter, screenSize);
	#endif

	return projectAndDivide(inverseProjectionMatrix, ndcPos);
}

float convertHandDepth(float depth) {
	float ndcDepth = depth * 2.0 - 1.0;
	ndcDepth /= MC_HAND_DEPTH;
	return ndcDepth * 0.5 + 0.5;
}

vec3 viewToScreen(vec3 viewPos, int frameCounter, vec2 screenSize, mat4 projectionMatrix) {
	vec3 ndcPos = projectAndDivide(projectionMatrix, viewPos);
	
	#ifdef TAA
		ndcPos.xy += taaOffset(frameCounter, screenSize);
	#endif

	return ndcPos * 0.5 + 0.5;
}

vec3 viewToWorld(vec3 viewPos, vec3 cameraPosition, mat4 inverseModelViewMatrix) {
	vec3 scenePos = (inverseModelViewMatrix * vec4(viewPos, 1.0)).xyz;
	return scenePos + cameraPosition;
}

vec3 worldToView(vec3 worldPos, vec3 cameraPosition, mat4 modelViewMatrix) {
	vec3 scenePos = worldPos - cameraPosition;
	return (modelViewMatrix * vec4(scenePos, 1.0)).xyz;
}

vec3 calcViewVector(vec2 texcoord, int frameCounter, vec2 screenSize, mat4 inverseProjectionMatrix) {
	vec3 ndcPos = vec3(texcoord * 2.0 - 1.0, 0.0);

	#ifdef TAA
		ndcPos.xy -= taaOffset(frameCounter, screenSize);
	#endif

	vec3 viewVector = projectAndDivide(inverseProjectionMatrix, ndcPos);
	return viewVector / viewVector.z;
}

vec3 normalToView(vec3 normal, mat4 modelViewMatrix) {
	return (modelViewMatrix * vec4(normal, 0.0)).xyz;
}

// Creates a TBN matrix from a normal and a tangent
mat3 tbnNormalTangent(vec3 normal, vec3 tangent) {
    // For DirectX normal mapping you want to switch the order of these 
    vec3 bitangent = cross(normal, tangent);
    return mat3(tangent, bitangent, normal);
}

// Creates a TBN matrix from a normal and a tangent
mat3 tbnNormalTangent(vec3 normal, vec4 tangent) {
    // For DirectX normal mapping you want to switch the order of these 
    vec3 bitangent = cross(normal, tangent.xyz) * -sign(tangent.w);
    return mat3(tangent.xyz, bitangent, normal);
}

// Creates a TBN matrix from just a normal
// The tangent version is needed for normal mapping because
//   of face rotation
mat3 tbnNormal(vec3 normal) {
    // This could be
    // normalize(vec3(normal.y - normal.z, -normal.x, normal.x))
    vec3 tangent = normalize(cross(normal, vec3(0, 1, 1)));
    return tbnNormalTangent(normal, tangent);
}

#endif