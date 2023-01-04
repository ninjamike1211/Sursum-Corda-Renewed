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

#endif