#version 400 compatibility

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform float eyeAltitude;
uniform float rainStrength;
uniform int worldTime;
uniform bool inEnd;
uniform bool inNether;

#include "/defines.glsl"
#include "/kernels.glsl"
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