#version 400 compatibility

uniform mat4 gbufferModelViewInverse;

in vec4 at_tangent;
in float mc_Entity;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
flat out mat3 tbn;
flat out uint mcEntity;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = gl_MultiTexCoord1.xy / 255.0;
	glcolor  = gl_Color;

	vec3 normal  = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));
	vec3 tangent = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * at_tangent.xyz));

	tbn = mat3(tangent, cross(tangent, normal), normal);

	mcEntity = uint(mc_Entity + 0.5);
}