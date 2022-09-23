#version 400 compatibility

uniform sampler2D texture;

in vec2 texcoord;
in vec4 glcolor;

/* DRAWBUFFERS:2 */
layout(location = 0) out vec4 albedo;

void main() {
	albedo = texture2D(texture, texcoord) * glcolor;

	// if(albedo.r < 0.1)
	// 	discard;

	albedo.rgb = vec3(albedo.r);
}