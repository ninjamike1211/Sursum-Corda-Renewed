#version 400 compatibility

uniform sampler2D colortex12;

uniform mat4 shadowModelViewInverse;
uniform float rainStrength;
uniform float frameTime;
uniform float frameTimeCounter;

uniform mat4  gbufferModelView;
uniform mat4  gbufferModelViewInverse;
uniform mat4  gbufferProjection;
uniform mat4  gbufferProjectionInverse;
uniform vec3  cameraPosition;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform int   frameCounter;
uniform bool  cameraMoved;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform mat4      shadowModelView;
uniform mat4      shadowProjection;
uniform float     fogDensityMult;
uniform float     eyeAltitude;

flat out vec2 singleTexSize;

in vec4 at_tangent;
in vec2 mc_midTexCoord;
in vec3 at_midBlock;
in vec4 mc_Entity;

out vec2 texcoord;
out vec4 glColor;
// out vec3 viewPos;
// out vec3 scenePos;
out vec3 worldPosVertex;
flat out vec3 glNormal;
// flat out vec4 textureBounds;
flat out int entity;
// flat out mat3 tbn;

#include "/lib/defines.glsl"
#include "/lib/kernels.glsl"
#include "/lib/noise.glsl"
#include "/lib/sample.glsl"
#include "/lib/TAA.glsl"
#include "/lib/spaceConvert.glsl"
#include "/lib/shadows.glsl"
#include "/lib/functions.glsl"
#include "/lib/waving.glsl"

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glColor = gl_Color;

    // isWater = mc_Entity.x == 9 ? 1 : 0;
    entity = int(mc_Entity.x);

    // vec3 glNormal = normalize(gl_NormalMatrix * gl_Normal);
    // vec3 tangent = normalize(gl_NormalMatrix * at_tangent.xyz);
    // vec3 binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);

    // tbn = mat3(	tangent.x, binormal.x, glNormal.x,
    //             tangent.y, binormal.y, glNormal.y,
    //             tangent.z, binormal.z, glNormal.z);

    // glNormal      = normalize((shadowModelViewInverse * vec4(gl_NormalMatrix * gl_Normal, 0.0)).xyz);
    // vec3 tangent  = normalize((shadowModelViewInverse * vec4(gl_NormalMatrix * at_tangent.xyz, 0.0)).xyz);
    glNormal = gl_NormalMatrix * gl_Normal;
    // vec3 tangent = gl_NormalMatrix * at_tangent.xyz;
    // // vec3 binormal = normalize((gbufferModelViewInverse * vec4(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w, 0.0)).xyz);
    // vec3 binormal = cross(tangent, glNormal);

    // tbn = mat3(	tangent, binormal, glNormal);


    vec4 modelPos = gl_Vertex;

    if(entity == 10030 && glColor.r < 0.5) {
        modelPos.y -= 0.2;
    }

    vec2 halfSize = abs(texcoord - mc_midTexCoord);
	vec4 textureBounds = vec4(mc_midTexCoord.xy - halfSize, mc_midTexCoord.xy + halfSize);
    // singleTexSize = textureBounds.zw-textureBounds.xy;

    #ifdef wavingPlants
    if(entity > 10000) {
        vec3 worldPos = modelPos.xyz + cameraPosition;
        
        modelPos.xyz += wavingOffset(worldPos, entity, at_midBlock, colortex12);
    }
    #endif

    vec3 viewPos = (gl_ModelViewMatrix * modelPos).xyz;
    vec3 scenePos = (shadowModelViewInverse * vec4(viewPos, 1.0)).xyz;
    worldPosVertex = scenePos + cameraPosition;

    // #ifdef MC_NORMAL_MAP
    // #ifdef POM
    // #ifdef POM_PDO

    // if(atlasSize.x > 0) {
    //     viewPos += (POM_Depth * vec3(0.0, 0.0, -1.0)) * tbn;
    // }

    // #endif
    // #endif
    // #endif

    gl_Position = gl_ProjectionMatrix * vec4(viewPos, 1.0);
    gl_Position.xyz = distort(gl_Position.xyz);
}