#version 400 compatibility

#define ExposureSpeed 1000

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform sampler2D colortex0;
uniform int worldTime;
uniform float rainStrength;
uniform bool inEnd;
uniform bool inNether;

#include "/functions.glsl"

out vec2 texcoord;
out vec3 viewVector;
flat out vec3 SunMoonColor;

void main() {
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    vec4 ray = gbufferProjectionInverse * vec4(texcoord * 2.0 - 1.0, 0.0, 1.0);
	viewVector = (ray.xyz / ray.w);
	viewVector /= viewVector.z;

    SunMoonColor = skyLightColor(worldTime, rainStrength);
}