#version 420 compatibility

uniform usampler2D colortex2;
uniform sampler2D  depthtex2;
uniform sampler2D  depthtex1;
uniform sampler2D  noisetex;

uniform mat4  gbufferModelView;
uniform mat4  gbufferProjectionInverse;
uniform mat4  gbufferModelViewInverse;
uniform mat4  gbufferProjection;
uniform vec3  cameraPosition;
uniform vec3  fogColor;
uniform float rainStrength;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;
uniform float fogDensityMult;
uniform float heldBlockLightValue;
uniform float heldBlockLightValue2;
uniform int   heldItemId;
uniform int   heldItemId2;
uniform int   frameCounter;
uniform int   worldTime;
uniform bool  cameraMoved;

const int noiseTextureResolution = 512;

#include "/lib/defines.glsl"
#include "/lib/material.glsl"
#include "/lib/kernels.glsl"
#include "/lib/functions.glsl"
#include "/lib/noise.glsl"
#include "/lib/TAA.glsl"
#include "/lib/spaceConvert.glsl"
#include "/lib/lighting.glsl"


// ------------------------ File Contents -----------------------
    // SSAO rendering/calculation
    // Outputs unfiltered SSAO to colortex9


in vec2 texcoord;
in vec3 viewVector;

/* RENDERTARGETS: 9 */
layout(location = 0) out vec4 SSAOOut;

void main() {

// ---------------------------- SSAO ----------------------------
    #ifdef SSAO
        float depth = texture(depthtex2, texcoord).r;
        uint normalRaw = texture(colortex2, texcoord).g;

        vec3 viewPos = calcViewPos(viewVector, depth);
        vec3 normalGeometry = NormalDecode(normalRaw);

        SSAOOut = vec4(mix(calcSSAO(normalToView(normalGeometry), viewPos, texcoord, depthtex2, noisetex), vec3(1.0), 0.0), 1.0);
    #else
        SSAOOut = vec4(1.0);
    #endif
}