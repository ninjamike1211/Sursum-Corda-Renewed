#version 400 compatibility

uniform mat4 gbufferModelViewInverse;

in vec4 at_tangent;
in float mc_Entity;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 scenePos;
flat out vec3 glNormal;
flat out vec4 tangent;
flat out uint mcEntity;

void main() {
	gl_Position = ftransform();
	scenePos = (gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex)).xyz;

	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = gl_MultiTexCoord1.xy / 240.0;
	glcolor  = gl_Color;

	glNormal = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));
	tangent  = vec4(normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * at_tangent.xyz)), at_tangent.w);

	mcEntity = uint(mc_Entity + 0.5);
}