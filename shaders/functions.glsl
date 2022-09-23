#ifndef FUNCTIONS
#define FUNCTIONS

/*
// #include "/defines.glsl"
// #include "/kernels.glsl"

// uniform mat4  gbufferModelView;
// uniform mat4  gbufferModelViewInverse;
// uniform mat4  gbufferProjection;
// uniform mat4  gbufferProjectionInverse;
// uniform vec3  cameraPosition;
// uniform float rainStrength;
// uniform float near;
// uniform float far;
// uniform float viewWidth;
// uniform float viewHeight;
// uniform int   frameCounter;
// uniform int   worldTime;
// uniform bool  cameraMoved;
// uniform bool  inEnd;
// uniform bool  inNether;
*/

vec2 sincos(vec2 angle) {
	return vec2(sin(angle.x), cos(angle.y));
}

vec2 cossin(vec2 angle) {
	return vec2(cos(angle.x), sin(angle.y));
}

// https://www.titanwolf.org/Network/q/bb468365-7407-4d26-8441-730aaf8582b5/x
vec4 linearToSRGB(vec4 linear) {
	vec4 higher = (pow(abs(linear), vec4(1.0 / 2.4)) * 1.055) - 0.055;
	vec4 lower  = linear * 12.92;
	return mix(higher, lower, step(linear, vec4(0.0031308)));

	// return pow(linear, vec4(1.0 / 2.2));
}

vec4 sRGBToLinear(vec4 sRGB) {
	vec4 higher = pow((sRGB + 0.055) / 1.055, vec4(2.4));
	vec4 lower  = sRGB / 12.92;
	return mix(higher, lower, step(sRGB, vec4(0.04045)));

	// return pow(sRGB, vec4(2.2));
}

vec3 sRGBToLinear3(vec3 sRGB) {
	vec3 higher = pow((sRGB + 0.055) / 1.055, vec3(2.4));
	vec3 lower  = sRGB / 12.92;
	return mix(higher, lower, step(sRGB, vec3(0.04045)));

	// return pow(sRGB, vec4(2.2));
}

float luminance(vec3 v) {
    return dot(v, vec3(0.2126f, 0.7152f, 0.0722f));
}

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

// Vogel Disk sample function, from Tech#2594 (https://www.shadertoy.com/view/NdBGDR)
vec2 GetVogelDiskSample(int sampleIndex, int sampleCount, float phi) 
{
	const float goldenAngle = 2.399963;
	float sampleIndexF = float(sampleIndex);
	float sampleCountF = float(sampleCount);
	
	float r = sqrt((sampleIndexF + 0.5) / sampleCountF);
	float theta = sampleIndexF * goldenAngle + phi;
	
	float sine = sin(theta);
	float cosine = cos(theta);
	
	return vec2(cosine, sine) * r;
}

vec2 taaOffset() {
	if(cameraMoved)
		return vec2(0.0);
	
	int taaIndex = frameCounter % 16;
	return vec2((TAAOffsets[taaIndex] * 2.0 - 1.0) / vec2(viewWidth, viewHeight));
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

vec3 extractNormalZ(vec2 normal) {
	// return vec3(normal, sqrt(1.0 - dot(normal.xy, normal.xy)));
	return vec3(normal, sqrt(max(1.0 - dot(normal.xy, normal.xy), 0.0)));
}

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

vec3 normalToView(vec3 normal) {
	return (gbufferModelView * vec4(normal, 0.0)).xyz;
}

// vec2 OctWrap( vec2 v )
// {
//     return ( 1.0 - abs( v.yx ) ) * vec2( v.x >= 0.0 ? 1.0 : -1.0, v.y >= 0.0 ? 1.0 : -1.0 );
// }
 
// vec2 NormalEncode( vec3 n )
// {
//     n.xy /= (abs(n.x) + abs(n.y) + abs(n.z));
//     n.xy = n.z >= 0.0 ? n.xy : OctWrap( n.xy );
//     n.xy = n.xy * 0.5 + 0.5;
//     return n.xy;
// }
 
// vec3 NormalDecode( vec2 f )
// {
//     f = f * 2.0 - 1.0;
 
//     // https://twitter.com/Stubbesaurus/status/937994790553227264
//     vec3 n = vec3( f.x, f.y, 1.0 - abs( f.x ) - abs( f.y ) );
//     float t = clamp( -n.z, 0.0, 1.0);
//     n.xy += vec2(n.x >= 0.0  ? -t : t, n.y >= 0.0  ? -t : t);
//     return normalize( n );
// }

float dayTimeFactor() {
	float adjustedTime = mod(worldTime + 785.0, 24000.0);

	if(adjustedTime > 13570.0)
			return sin((adjustedTime - 3140.0) * PI / 10430.0);

	return sin(adjustedTime * PI / 13570.0);
}

vec3 skyLightColor() {
	if(inEnd) {
		return vec3(0.075, 0.04, 0.15);
	}
	else if(inNether) {
		return vec3(0.4, 0.02, 0.01);
	}
	else {
		float timeFactor = dayTimeFactor();
		vec3 night = mix(vec3(0.02, 0.02, 0.035), vec3(0.03), rainStrength);
		vec3 day = mix(mix(vec3(1.0, 0.6, 0.4), vec3(0.9, 0.87, 0.85), clamp(5.0 * (timeFactor - 0.2), 0.0, 1.0)), vec3(0.3), rainStrength);
		return mix(night, day, clamp(2.0 * (timeFactor + 0.4), 0.0, 1.0));
	}
}

// vec3 skyLightColor(int time, float rainStrength) {
// 	float a = 0.204068920917;
// 	float b = 0.4;
// 	float factor = (abs(sin(PI/12000 * time) + a) + b) / (1 + a + b);

// 	return vec3(factor * (1.0 - 0.3 * rainStrength));
// }

// float texBilinearWrap(vec2 texcoord, vec4 texcoordRange, float lod) {

// 	float lodFactor = exp2(-floor(lod));
// 	vec2 pixelCoord = texcoord * atlasSize * lodFactor - 0.5;
// 	vec4 texelRange = texcoordRange * atlasSize.xyxy * lodFactor - vec4(0.5, 0.5, 0.0, 0.0);
// 	ivec2 singleTexelSize = ivec2(texelRange.zw - texelRange.xy);

// 	ivec4 sampleCoords = ivec4(pixelCoord, ceil(pixelCoord));

// 	sampleCoords.xy -= ivec2(floor((sampleCoords.xy - texelRange.xy) / singleTexelSize) * singleTexelSize);
// 	sampleCoords.zw -= ivec2(floor((sampleCoords.zw - texelRange.xy) / singleTexelSize) * singleTexelSize);

// 	float topLeft      = texelFetch(normals, sampleCoords.xy, int(lod)).a;
// 	float topRight     = texelFetch(normals, sampleCoords.zy, int(lod)).a;
// 	float bottomLeft   = texelFetch(normals, sampleCoords.xw, int(lod)).a;
// 	float bottomRight  = texelFetch(normals, sampleCoords.zw, int(lod)).a;

// 	return mix(mix(topLeft, topRight, fract(pixelCoord.x)), mix(bottomLeft, bottomRight, fract(pixelCoord.x)), fract(pixelCoord.y));
// }

/*
    Texture Bicubic provided by swr#1793
*/
vec4 cubic(float v) {
    vec4 n  = vec4(1.0, 2.0, 3.0, 4.0) - v;
    vec4 s  = pow(n, vec4(3.0));
    float x = s.x;
    float y = s.y - 4.0 * s.x;
    float z = s.z - 4.0 * s.y + 6.0 * s.x;
    float w = 6.0 - x - y - z;
    return vec4(x, y, z, w) / 6.0;
}
 
vec4 textureBicubic(sampler2D tex, vec2 texCoords) {
    vec2 texSize    = textureSize(tex, 0);
    vec2 invTexSize = 1.0 / texSize;
 
    texCoords = texCoords * texSize - 0.5;
 
    vec2 fxy   = fract(texCoords);
    texCoords -= fxy;
 
    vec4 xcubic = cubic(fxy.x);
    vec4 ycubic = cubic(fxy.y);
 
    vec4 c = texCoords.xxyy + vec2(-0.5, 1.5).xyxy;
 
    vec4 s      = vec4(xcubic.xz + xcubic.yw, ycubic.xz + ycubic.yw);
    vec4 offset = c + vec4(xcubic.yw, ycubic.yw) / s;
 
    offset *= invTexSize.xxyy;
 
    vec4 sample0 = texture2D(tex, offset.xz);
    vec4 sample1 = texture2D(tex, offset.yz);
    vec4 sample2 = texture2D(tex, offset.xw);
    vec4 sample3 = texture2D(tex, offset.yw);
 
    float sx = s.x / (s.x + s.y);
    float sy = s.z / (s.z + s.w);
 
    return mix(mix(sample3, sample2, sx), mix(sample1, sample0, sx), sy);
}

vec4 textureBicubicWrap(sampler2D tex, vec2 texCoords, vec4 bounds) {
    vec2 texSize    = textureSize(tex, 0);
    vec2 invTexSize = 1.0 / texSize;
 
    texCoords = texCoords * texSize - 0.5;
 
    vec2 fxy   = fract(texCoords);
    texCoords -= fxy;
 
    vec4 xcubic = cubic(fxy.x);
    vec4 ycubic = cubic(fxy.y);
 
    vec4 c = texCoords.xxyy + vec2(-0.5, 1.5).xyxy;
 
    vec4 s      = vec4(xcubic.xz + xcubic.yw, ycubic.xz + ycubic.yw);
    vec4 offset = c + vec4(xcubic.yw, ycubic.yw) / s;
 
    offset *= invTexSize.xxyy;

	vec2 boundSize = bounds.zw - bounds.xy;
	offset = mod(offset - bounds.xxyy, boundSize.xxyy) + bounds.xxyy;
 
    vec4 sample0 = texture2D(tex, offset.xz);
    vec4 sample1 = texture2D(tex, offset.yz);
    vec4 sample2 = texture2D(tex, offset.xw);
    vec4 sample3 = texture2D(tex, offset.yw);
 
    float sx = s.x / (s.x + s.y);
    float sy = s.z / (s.z + s.w);
 
    return mix(mix(sample3, sample2, sx), mix(sample1, sample0, sx), sy);
}

#endif