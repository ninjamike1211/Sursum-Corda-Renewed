
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 cameraPosition;
uniform float viewWidth;
uniform float viewHeight;
uniform int frameCounter;
uniform float frameTimeCounter;
uniform float rainStrength;

#define shadowGbuffer

#include "/lib/defines.glsl"
#include "/lib/spaceConvert.glsl"
#include "/lib/shadows.glsl"
#include "/lib/water.glsl"

in vec4 at_tangent;
in float mc_Entity;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 scenePos;
out vec4 shadowPos;
flat out vec3 glNormal;
flat out vec4 tangent;
flat out uint mcEntity;

void main() {
	mcEntity = uint(mc_Entity + 0.5);

	// gl_Position = ftransform();
	vec4 modelPos = gl_Vertex;
	scenePos = (gbufferModelViewInverse * (gl_ModelViewMatrix * modelPos)).xyz;

    #ifdef GBUFFERS_TRANSLUCENT_TERRAIN
        #ifdef Water_VertexOffset
        if(mcEntity == MCEntity_Water) {
            vec3 worldPos = scenePos + cameraPosition;
            scenePos.y += waterOffset(scenePos + cameraPosition, frameTimeCounter);
        }
        #endif
        gl_Position = gl_ProjectionMatrix * (gbufferModelView * vec4(scenePos, 1.0));
    #else
        gl_Position = ftransform();
    #endif

	#ifdef TAA
		gl_Position.xy += taaOffset(frameCounter, vec2(viewWidth, viewHeight)) * gl_Position.w;
	#endif

	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	// lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	// lmcoord = ((gl_TextureMatrix[1] * gl_MultiTexCoord1).xy - 1.0/32.0) * 16.0/15.0;
	lmcoord = (gl_MultiTexCoord1.xy - 8) / 240.0;
	glcolor  = gl_Color;

	shadowPos.xyz = (shadowProjection * (shadowModelView * vec4(scenePos, 1.0))).xyz;
	shadowPos.w = length(shadowPos.xy);
	shadowPos.xyz = distort(shadowPos.xyz) * 0.5 + 0.5;

	glNormal = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));
	tangent  = vec4(normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * at_tangent.xyz)), at_tangent.w);

}