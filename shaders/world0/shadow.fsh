#version 400 compatibility

#define shadowGbuffer

// // uniform ivec2 atlasSize;
// uniform mat4 gbufferModelView;
// uniform bool inEnd;
// uniform bool inNether;

uniform sampler2D tex;
// // uniform sampler2D normals;
// uniform sampler2D colortex9; 
uniform float alphaTestRef;
// // uniform vec3 shadowLightPosition;
uniform vec3 cameraPosition;
// // uniform mat4 shadowModelViewInverse;
uniform float frameTimeCounter;
// // uniform mat4 gbufferModelViewInverse;
// // uniform mat4 shadowProjection;
// // uniform mat4 shadowModelView;
// // uniform mat4 shadowProjectionInverse;
// uniform vec3 lightDir;

// flat in vec2 singleTexSize;

// uniform sampler2D shadowtex0;
// uniform sampler2D shadowtex1;
// uniform sampler2D shadowcolor0;
// uniform mat4  gbufferModelViewInverse;
// uniform mat4  gbufferProjection;
// uniform mat4  gbufferProjectionInverse;
// uniform mat4  shadowModelView;
// uniform mat4  shadowProjection;
// uniform float rainStrength;
// uniform float near;
// uniform float far;
// uniform float viewWidth;
// uniform float viewHeight;
// uniform int   frameCounter;
// uniform int   worldTime;
// uniform bool  cameraMoved;

#include "/lib/defines.glsl"
#include "/lib/noise.glsl"
#include "/lib/water.glsl"

in vec2 texcoord;
in vec4 glColor;
// in vec3 viewPos;
// in vec3 scenePos;
in vec3 worldPosVertex;
// flat in vec3 glNormal;
// flat in vec4 textureBounds;
flat in int entity;

// flat in mat3 tbn;

layout(location = 0) out vec4 shadowColor;

void main() {

    // testOut = vec4(0.0);

    vec2 texcoordFinal = texcoord;

    shadowColor = texture(tex, texcoordFinal) * glColor;
    if (shadowColor.a < alphaTestRef) discard;

    if(entity == 10010) {
        shadowColor.a = 0.0;

        // vec3 worldPos = (shadowModelViewInverse * vec4(viewPos, 1.0)).xyz + cameraPosition;
        vec3 worldPos = worldPosVertex;
        // float caustics = texture(colortex9, fract(worldPos.xz * 0.1 + frameTimeCounter * 0.015)).r;
        // caustics = max(caustics, texture(colortex9, fract(worldPos.xz * 0.1 - frameTimeCounter * 0.02)).r);
        // caustics = max(caustics, texture(colortex9, fract(worldPos.xz * 0.1 - frameTimeCounter * vec2(-0.013, 0.013))).r);
        // caustics = max(caustics, texture(colortex9, fract(worldPos.xz * 0.1 - frameTimeCounter * vec2(0.009, -0.009))).r);

        float caustics = (pow(waterHeightFunc(worldPos.xz), 5.0) * 0.9 + 0.1) * 2.0;

        shadowColor.rgb = glColor.rgb * caustics * 2.0;

        // shadowColor.rgb = vec3(caustics);
    }

    // testOut.rgb = tbn * texture(normals, texcoord).rgb;
    // testOut.rgb = glNormal;
}