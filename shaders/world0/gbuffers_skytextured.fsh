#version 420 compatibility

uniform sampler2D tex;

#include "/lib/material.glsl"

in vec2 texcoord;
in vec4 glcolor;

/* RENDERTARGETS: 1,2 */
layout(location = 0) out vec4  albedo;
layout(location = 1) out uvec3 specMapOut;

void main() {

	albedo = texture(tex, texcoord) * glcolor;

	albedo.rgb = vec3(albedo.r);

	specMapOut = uvec3(0, 0, SpecularEncode(vec4(0.0, 0.0, 0.0, 0.5)));
}