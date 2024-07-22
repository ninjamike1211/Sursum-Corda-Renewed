#version 430

uniform sampler2D colortex10;
uniform float rainStrength;
uniform float sunAngle;
uniform int moonPhase;

#include "/lib/defines.glsl"
#include "/lib/functions.glsl"
#include "/lib/sky.glsl"

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
const ivec3 workGroups = ivec3(1, 1, 1);

void main() {
    skyLight.skyDirect = sunLightSample(sunAngle, rainStrength, moonPhase);
	skyLight.skyAmbient = skyLightSample(colortex10);
}