#version 400 compatibility

#define shadowGbuffer

// uniform ivec2 atlasSize;
uniform mat4 gbufferModelView;
uniform bool inEnd;
uniform bool inNether;

uniform sampler2D texture;
// uniform sampler2D normals;
uniform sampler2D colortex9; 
uniform float alphaTestRef;
// uniform vec3 shadowLightPosition;
uniform vec3 cameraPosition;
// uniform mat4 shadowModelViewInverse;
uniform float frameTimeCounter;
// uniform mat4 gbufferModelViewInverse;
// uniform mat4 shadowProjection;
// uniform mat4 shadowModelView;
// uniform mat4 shadowProjectionInverse;
uniform vec3 lightDir;

// flat in vec2 singleTexSize;

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform mat4  gbufferModelViewInverse;
uniform mat4  gbufferProjection;
uniform mat4  gbufferProjectionInverse;
uniform mat4  shadowModelView;
uniform mat4  shadowProjection;
uniform float rainStrength;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform int   frameCounter;
uniform int   worldTime;
uniform bool  cameraMoved;

#include "/defines.glsl"
#include "/kernels.glsl"
#include "/functions.glsl"
// #include "/parallax.glsl"
#include "/noise.glsl"
#include "/water.glsl"

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

    // #if defined MC_NORMAL_MAP && defined POM && defined POM_PDO
    //     if((entity < 10002 || entity > 10004) && atlasSize.x > 0) {
    //         if(entity == 10010) {
    //             // // vec3 worldPos = (shadowModelViewInverse * vec4(viewPos, 1.0)).xyz + cameraPosition;
    //             // vec3 worldPos = worldPosVertex;

    //             // // vec3 worldPosInitial = worldPos;
    //             // waterParallaxMapping(worldPos, vec2(1.0));

    //             // vec3 shadowViewPos = (shadowModelView * vec4(worldPos - cameraPosition + vec3(0.0, 0.0, 0.0), 1.0)).xyz;
    //             // // vec3 screenPos = (gl_ProjectionMatrix * vec4(shadowViewPos, 1.0)).xyz * 0.5 + 0.5;
    //             // // vec3 screenPos = projectAndDivide(shadowProjection, shadowViewPos) * 0.5 + 0.5;
    //             // vec4 shadowClipPos = gl_ProjectionMatrix * vec4(shadowViewPos, 1.0);
    //             // shadowClipPos.z *= 0.5;
    //             // vec3 screenPos = (shadowClipPos.xyz / shadowClipPos.w) * 0.5 + 0.5;

    //             // gl_FragDepth = screenPos.z;

    //             gl_FragDepth = gl_FragCoord.z;
    //         }
    //         else {
    //             // // vec2 texcoordDx = dFdx(texcoord) / (textureBounds.zw-textureBounds.xy);
    //             // // vec3 viewDx = dFdx(scenePos);
    //             // // vec3 tbnDx = tbn * viewDx;
    //             // // vec2 texWorldSizeX = tbnDx.xy / texcoordDx;

    //             // // vec2 texcoordDy = dFdy(texcoord) / (textureBounds.zw-textureBounds.xy);
    //             // // vec3 viewDy = dFdy(scenePos);
    //             // // vec3 tbnDy = tbn * viewDy;
    //             // // vec2 texWorldSizeY = tbnDy.xy / texcoordDy;

    //             // // vec2 texWorldSize = max(texWorldSizeX, texWorldSizeY);
    //             // vec2 texWorldSize = vec2(1.0);

    //             float lod = textureQueryLod(texture, texcoord).x;
    //             // // vec3 viewDirTBN = tbn * normalize(viewPos);
    //             // vec2 norm;

    //             // gl_FragDepth = parallaxDepthOffset(texcoordFinal, viewPos, tbn, textureBounds, texWorldSize, lod, 1.0, norm);

    //             // testOut.rgb = vec3(abs(gl_FragDepth - gl_FragCoord.z));

    //             // // gl_FragDepth = gl_FragCoord.z;

    //             vec3 shadowTexcoord;
    //             bool onEdge;
    //             vec2 norm;

    //             float offset = parallaxMapping(texcoordFinal, viewPos, tbn, textureBounds, vec2(1.0), lod, POM_Layers, 1.0, shadowTexcoord, onEdge, norm);

    //             vec3 viewPosFinal = viewPos - tbn[2] * offset;
    //             vec4 clipPos = shadowProjection * vec4(viewPosFinal, 1.0);
    //             clipPos.z *= 0.5;
    //             vec3 screenPos = (clipPos.xyz / clipPos.w) * 0.5 + 0.5;

    //             // gl_FragDepth = gl_FragCoord.z;
    //             // gl_FragDepth = screenPos.z;

    //             testOut.rgb = vec3(offset);
    //         }
    //     }
    //     else {
    //         gl_FragDepth = gl_FragCoord.z;
    //     }
    // #endif


    shadowColor = texture2D(texture, texcoordFinal) * glColor;
    if (shadowColor.a < alphaTestRef) discard;

    if(entity == 10010) {
        shadowColor.a *= 0.1;

        // vec3 worldPos = (shadowModelViewInverse * vec4(viewPos, 1.0)).xyz + cameraPosition;
        vec3 worldPos = worldPosVertex;
        // float caustics = texture2D(colortex9, fract(worldPos.xz * 0.1 + frameTimeCounter * 0.015)).r;
        // caustics = max(caustics, texture2D(colortex9, fract(worldPos.xz * 0.1 - frameTimeCounter * 0.02)).r);
        // caustics = max(caustics, texture2D(colortex9, fract(worldPos.xz * 0.1 - frameTimeCounter * vec2(-0.013, 0.013))).r);
        // caustics = max(caustics, texture2D(colortex9, fract(worldPos.xz * 0.1 - frameTimeCounter * vec2(0.009, -0.009))).r);

        float caustics = (pow(waterHeightFunc(worldPos.xz), 5.0) * 0.9 + 0.1) * 2.0;

        shadowColor.rgb = glColor.rgb * caustics;

        // shadowColor.rgb = vec3(caustics);
    }

    // testOut.rgb = tbn * texture2D(normals, texcoord).rgb;
    // testOut.rgb = glNormal;
}