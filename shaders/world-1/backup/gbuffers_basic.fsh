#version 400 compatibility

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 albedo;
layout(location = 1) out vec3 normal;

in vec4 glColor;
flat in vec3 glNormal;

uniform float alphaTestRef;

void main() {
    albedo = glColor;
    if (albedo.a < alphaTestRef) discard;

    normal = glNormal * 0.5 + 0.5;
}