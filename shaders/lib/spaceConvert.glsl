#ifndef SPACECONVERT
#define SPACECONVERT

// #include "/lib/kernels.glsl"
// #include "/lib/TAA.glsl"

// uniform mat4  gbufferModelView;
// uniform mat4  gbufferModelViewInverse;
// uniform mat4  gbufferProjection;
// uniform mat4  gbufferProjectionInverse;
// uniform vec3  cameraPosition;
// uniform float near;
// uniform float far;
// uniform float viewWidth;
// uniform float viewHeight;
// uniform int   frameCounter;
// uniform bool  cameraMoved;

float linearizeDepthFast(float depth) {
	return (near * far) / (depth * (near - far) + far);
}

float linearizeDepthNorm(float depth) {
	return (linearizeDepthFast(depth) - near) / (far - near);
}

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position) {
	vec4 homoPos = projectionMatrix * vec4(position, 1.0);
	return homoPos.xyz / homoPos.w;
}

vec3 calcViewPos(vec3 viewVector, float depth) {
	float viewZ = -gbufferProjection[3][2] / ((depth * 2.0 - 1.0) + gbufferProjection[2][2]);
	return viewVector * viewZ;
}

vec3 screenToView(vec2 texcoord, float depth) {
	vec3 ndcPos = vec3(texcoord * 2.0 - 1.0, depth * 2.0 - 1.0);

	#ifdef TAA
		ndcPos.xy -= taaOffset();
	#endif

	return projectAndDivide(gbufferProjectionInverse, ndcPos);
}

vec3 viewToScreen(vec3 viewPos) {
	vec3 ndcPos = projectAndDivide(gbufferProjection, viewPos);
	
	#ifdef TAA
		ndcPos.xy += taaOffset();
	#endif

	return ndcPos * 0.5 + 0.5;
}

vec3 viewToWorld(vec3 viewPos) {
	vec3 scenePos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	return scenePos + cameraPosition;
}

vec3 worldToView(vec3 worldPos) {
	vec3 scenePos = worldPos - cameraPosition;
	return (gbufferModelView * vec4(scenePos, 1.0)).xyz;
}

vec3 calcViewVector(vec2 texcoord) {
	vec3 ndcPos = vec3(texcoord * 2.0 - 1.0, 0.0);

	#ifdef TAA
		ndcPos.xy -= taaOffset();
	#endif

	vec3 viewVector = projectAndDivide(gbufferProjectionInverse, ndcPos);
	return viewVector / viewVector.z;
}

vec3 normalToView(vec3 normal) {
	return (gbufferModelView * vec4(normal, 0.0)).xyz;
}

#endif