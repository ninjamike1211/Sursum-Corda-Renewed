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


// ------------------------ File Contents -----------------------
    // Shadows vertex shader


in vec4 at_tangent;
in vec2 mc_midTexCoord;
in vec3 at_midBlock;
in vec4 mc_Entity;

out vec2 texcoord;
out vec4 glColor;
out vec3 worldPosVertex;
flat out int entity;

#include "/lib/defines.glsl"
#include "/lib/functions.glsl"
#include "/lib/kernels.glsl"
#include "/lib/noise.glsl"
#include "/lib/sample.glsl"
#include "/lib/TAA.glsl"
#include "/lib/spaceConvert.glsl"
#include "/lib/shadows.glsl"
#include "/lib/waving.glsl"

void main() {

    vec2 halfSize = abs(texcoord - mc_midTexCoord);
	vec4 textureBounds = vec4(mc_midTexCoord.xy - halfSize, mc_midTexCoord.xy + halfSize);
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    glColor = gl_Color;
    entity = int(mc_Entity.x);
    vec3 glNormal = normalize(gl_NormalMatrix * gl_Normal);


// -------------------- Position Calculations -------------------
    vec4 modelPos = gl_Vertex;

    if(entity == 10030 && glColor.r < 0.5) {
        modelPos.y -= 0.2;
    }

    #ifdef wavingPlants
    if(entity > 10000) {
        vec3 worldPos = modelPos.xyz + cameraPosition;
        
        modelPos.xyz += wavingOffset(worldPos, entity, at_midBlock, glNormal, colortex12);
    }
    #endif

    vec3 viewPos = (gl_ModelViewMatrix * modelPos).xyz;
    vec3 scenePos = (shadowModelViewInverse * vec4(viewPos, 1.0)).xyz;
    worldPosVertex = scenePos + cameraPosition;

    gl_Position = gl_ProjectionMatrix * vec4(viewPos, 1.0);
    gl_Position.xyz = distort(gl_Position.xyz);
}