#version 400 compatibility

uniform vec3 lightDir;
uniform mat4 gbufferModelView;
uniform bool inEnd;
uniform bool inNether;
uniform ivec2 atlasSize;
uniform vec3 cameraPosition;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelViewInverse;
uniform float rainStrength;
uniform float frameTimeCounter;
// uniform sampler2D normals; // Not used, but no functions which use it are called, only needed for code in POM.glsl to compile
// uniform sampler2D texture; // Not used, but no functions which use it are called, only needed for code in POM.glsl to compile

flat out vec2 singleTexSize;

in vec4 at_tangent;
in vec2 mc_midTexCoord;
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

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform mat4  gbufferProjection;
uniform mat4  gbufferProjectionInverse;
uniform mat4  shadowModelView;
uniform mat4  shadowProjection;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform int   frameCounter;
uniform int   worldTime;
uniform bool  cameraMoved;
uniform float fogDensityMult;
uniform float eyeAltitude;

#include "/lib/defines.glsl"
#include "/lib/kernels.glsl"
#include "/lib/functions.glsl"
#include "/lib/noise.glsl"
#include "/lib/shadows.glsl"
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

    vec2 halfSize = abs(texcoord - mc_midTexCoord);
	vec4 textureBounds = vec4(mc_midTexCoord.xy - halfSize, mc_midTexCoord.xy + halfSize);
    // singleTexSize = textureBounds.zw-textureBounds.xy;

    #ifdef wavingPlants
    if(entity > 10000) {
        vec3 worldPos = modelPos.xyz + cameraPosition;
        
        modelPos.xyz += wavingOffset(worldPos, entity, texcoord, textureBounds);
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