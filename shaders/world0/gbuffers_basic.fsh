#version 400 compatibility

#include "/lib/defines.glsl"

flat in vec4 glcolor;
in vec2 lmcoord;

/* RENDERTARGETS: 2,3,4,5,6,7 */
layout(location = 0) out vec4 albedoOut;
layout(location = 1) out vec2 normalOut;
layout(location = 2) out vec4 specularOut;
layout(location = 3) out vec2 lightmapOut;
layout(location = 4) out uint maskOut;
layout(location = 5) out vec4 pomOut;

void main() {
	albedoOut = glcolor;
	normalOut = vec2(0.0);
	specularOut = vec4(0.0);
	lightmapOut = lmcoord * lmcoord;
	maskOut = 0;
	pomOut = vec4(0.0);
}