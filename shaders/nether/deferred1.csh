#version 430

uniform vec3 fogColor;
uniform float frameTimeCounter;

#include "/lib/defines.glsl"
#include "/lib/functions.glsl"
#include "/lib/sky.glsl"

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
const ivec3 workGroups = ivec3(1, 1, 1);

void main() {
    
    float flickerFactor = 0.4*cos(5*frameTimeCounter) + 0.3*cos(13*frameTimeCounter) + 0.3*cos(19*frameTimeCounter);

    skyLight.skyDirect = 0.25*fogColor * (flickerFactor * 0.1 + 1.0);
	skyLight.skyAmbient = 0.5*fogColor + vec3(0.5, 0.4, 0.3);
}