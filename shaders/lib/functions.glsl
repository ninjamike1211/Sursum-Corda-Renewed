#ifndef FUNCTIONS
#define FUNCTIONS

vec2 sincos(vec2 angle) {
	return vec2(sin(angle.x), cos(angle.y));
}

vec2 cossin(vec2 angle) {
	return vec2(cos(angle.x), sin(angle.y));
}

float min2(vec2 val) {
	return min(val.x, val.y);
}

float min3(vec3 val) {
	return min(min(val.x, val.y), val.z);
}

float linstep(float edge0, float edge1, float x) {
	return clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
}

vec3 linstep(vec3 edge0, vec3 edge1, vec3 x) {
	return vec3(linstep(edge0.x, edge1.x, x.x), linstep(edge0.y, edge1.y, x.y), linstep(edge0.z, edge1.z, x.z));
}

float smootherstep(float edge0, float edge1, float x) {
  x = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
  return ((6.0 * x - 15.0) * x + 10.0) * x * x * x;
}

float luminance(vec3 v) {
    return dot(v, vec3(0.2126f, 0.7152f, 0.0722f));
}

// https://www.titanwolf.org/Network/q/bb468365-7407-4d26-8441-730aaf8582b5/x
vec4 linearToSRGB(vec4 linear) {
	vec4 higher = (pow(abs(linear), vec4(1.0 / 2.4)) * 1.055) - 0.055;
	vec4 lower  = linear * 12.92;
	return mix(higher, lower, step(linear, vec4(0.0031308)));

	// return pow(linear, vec4(1.0 / 2.2));
}

vec3 linearToSRGB3(vec3 linear) {
	vec3 higher = (pow(abs(linear), vec3(1.0 / 2.4)) * 1.055) - 0.055;
	vec3 lower  = linear * 12.92;
	return mix(higher, lower, step(linear, vec3(0.0031308)));

	// return pow(linear, vec3(1.0 / 2.2));
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

	// return pow(sRGB, vec3(2.2));
}

vec3 ACESFilm(vec3 x) {
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;

    return clamp((x*(a*x+b))/(x*(c*x+d)+e), 0.0, 1.0);
}

//=================================================================================================
//
//  Baking Lab
//  by MJP and David Neubelt
//  http://mynameismjp.wordpress.com/
//
//  All code licensed under the MIT license
//
//=================================================================================================

// The code in this file was originally written by Stephen Hill (@self_shadow), who deserves all
// credit for coming up with this fit and implementing it. Buy him a beer next time you see him. :)

// sRGB => XYZ => D65_2_D60 => AP1 => RRT_SAT
const mat3 ACESInputMat = mat3
(
    vec3(0.59719, 0.07600, 0.02840),
    vec3(0.35458, 0.90834, 0.13383),
    vec3(0.04823, 0.01566, 0.83777)
);

// ODT_SAT => XYZ => D60_2_D65 => sRGB
const mat3 ACESOutputMat = mat3
(
    vec3( 1.60475, -0.10208, -0.00327),
    vec3(-0.53108,  1.10813, -0.07276),
    vec3(-0.07367, -0.00605,  1.07602)
);

vec3 RRTAndODTFit(vec3 v)
{
    vec3 a = v * (v + 0.0245786) - 0.000090537;
    vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
    return a / b;
}

vec3 ACESFitted(vec3 color)
{
    color = ACESInputMat * color;

    // Apply RRT and ODT
    color = RRTAndODTFit(color);

    color = ACESOutputMat * color;

    // Clamp to [0, 1]
    color = clamp(color, 0.0, 1.0);

    return color;
}

#endif