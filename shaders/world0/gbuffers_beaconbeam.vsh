#version 430 compatibility

#include "/program/gbuffers/solid.vert"

// uniform mat4 gbufferModelViewInverse;
// uniform float viewWidth;
// uniform float viewHeight;
// uniform int frameCounter;

// #include "/lib/defines.glsl"
// #include "/lib/spaceConvert.glsl"

// in vec4 at_tangent;
// in float mc_Entity;

// out vec2 lmcoord;
// out vec2 texcoord;
// out vec4 glcolor;
// flat out vec3 glNormal;
// flat out vec4 tangent;
// flat out uint mcEntity;

// void main() {
// 	gl_Position = ftransform();

// 	#ifdef TAA
// 		gl_Position.xy += taaOffset(frameCounter, vec2(viewWidth, viewHeight)) * gl_Position.w;
// 	#endif

// 	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
// 	lmcoord = gl_MultiTexCoord1.xy / 240.0;
// 	glcolor  = gl_Color;

// 	glNormal = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));
// 	tangent  = vec4(normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * at_tangent.xyz)), at_tangent.w);

// 	mcEntity = uint(mc_Entity + 0.5);
// }