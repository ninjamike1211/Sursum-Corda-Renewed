#version 400 compatibility

uniform sampler2D tex;

in vec2 texcoord;
in vec4 glcolor;

/* RENDERTARGETS: 2,4 */
layout(location = 0) out vec4 albedo;
layout(location = 1) out vec4 specMapOut;

void main() {

	albedo = texture(tex, texcoord) * glcolor;

	albedo.rgb = vec3(albedo.r);

	specMapOut = vec4(0.0, 0.0, 0.0, 0.5);
}