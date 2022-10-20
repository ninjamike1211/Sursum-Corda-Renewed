#version 400 compatibility

uniform usampler2D colortex1;
uniform sampler2D depthtex0;
uniform sampler2D noisetex;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform bool inEnd;
uniform bool inNether;

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform mat4  gbufferModelViewInverse;
uniform mat4  gbufferProjection;
uniform mat4  shadowModelView;
uniform mat4  shadowProjection;
uniform vec3  cameraPosition;
uniform float rainStrength;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform int   frameCounter;
uniform int   worldTime;
uniform bool  cameraMoved;

uniform float     eyeAltitude;
uniform float     frameTimeCounter;
uniform float fogDensityMult;

#include "/defines.glsl"
#include "/kernels.glsl"
#include "/noise.glsl"
#include "/functions.glsl"
#include "/lighting.glsl"

in vec2 texcoord;
in vec3 viewVector;

/* RENDERTARGETS: 9 */
layout(location = 0) out vec4 SSAOOut;

void main() {

    #ifdef SSAO
        float depth = texture2D(depthtex0, texcoord).r;
        uvec2 normalRaw = texture2D(colortex1, texcoord).rg;

        vec3 viewPos = calcViewPos(viewVector, depth);
        vec3 normalGeometry = NormalDecode(normalRaw.y);

        SSAOOut = vec4(mix(calcSSAO(normalToView(normalGeometry), viewPos, texcoord, depthtex0, noisetex), vec3(1.0), 0.0), 1.0);
    #else
        SSAOOut = vec4(1.0);
    #endif

    // #ifdef SSAO

    //     vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight);
    //     vec3 occlusion = vec3(0.0);

    //     for(int i = 0; i < 5; i++) {
    //         vec2 offset = vec2((i-2), 0.0) * texelSize;

    //         occlusion += 0.2 * texture2D(colortex9, texcoord + offset).rgb;
    //     }

    //     SSAOOut = vec4(occlusion, 1.0);

    // #endif
}