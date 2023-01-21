#version 400 compatibility

#define viewBuffer 0 //[0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 -1 -2 -3 -4 -5 -6 -7 100 101 102 103 104 105]
#define viewBufferSweep 0.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

uniform mat4 gbufferModelView;
uniform bool inEnd;
uniform bool inNether;
// uniform bool cameraMoved;

uniform mat4  gbufferModelViewInverse;
uniform mat4  gbufferProjection;
uniform mat4  gbufferProjectionInverse;
uniform vec3  cameraPosition;
uniform float rainStrength;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform int   frameCounter;
uniform int   worldTime;
uniform bool  cameraMoved;

#include "/lib/defines.glsl"
#include "/lib/kernels.glsl"
#include "/lib/noise.glsl"
#include "/lib/functions.glsl"

in vec2 texcoord;

uniform sampler2D colortex0;
uniform usampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D colortex8;
uniform sampler2D colortex9;
uniform sampler2D colortex10;
uniform sampler2D colortex11;
uniform sampler2D colortex12;
uniform sampler2D colortex13;
uniform sampler2D colortex14;
uniform sampler2D colortex15;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;

uniform vec3 fogColor;

/* RENDERTARGETS: 0 */
void main() {
    #if viewBuffer != 0
    if(texcoord.x > viewBufferSweep) {
    #endif
        #if viewBuffer == 0
            gl_FragColor = texture2D(colortex0, texcoord);
        #elif viewBuffer == 1
            gl_FragColor = texture2D(colortex1, texcoord);
        #elif viewBuffer == 2
            gl_FragColor = texture2D(colortex2, texcoord);
        #elif viewBuffer == 3
            gl_FragColor = texture2D(colortex3, texcoord);
        #elif viewBuffer == 4
            gl_FragColor = texture2D(colortex4, texcoord);
        #elif viewBuffer == 5
            gl_FragColor = texture2D(colortex5, texcoord);
        #elif viewBuffer == 6
            gl_FragColor = texture2D(colortex6, texcoord);
        #elif viewBuffer == 7
            gl_FragColor = texture2D(colortex7, texcoord);
        #elif viewBuffer == 8
            gl_FragColor = texture2D(colortex8, texcoord);
        #elif viewBuffer == 9
            gl_FragColor = texture2D(colortex9, texcoord);
        #elif viewBuffer == 10
            gl_FragColor = texture2D(colortex10, texcoord);
        #elif viewBuffer == 11
            gl_FragColor = texture2D(colortex11, texcoord);
        #elif viewBuffer == 12
            gl_FragColor = texture2D(colortex12, texcoord);
        #elif viewBuffer == 13
            gl_FragColor = texture2D(colortex13, texcoord);
        #elif viewBuffer == 14
            gl_FragColor = texture2D(colortex14, texcoord);
        #elif viewBuffer == 15
            gl_FragColor = texture2D(colortex15, texcoord);
        #elif viewBuffer == -1
            gl_FragColor = texture2D(depthtex0, texcoord);
        #elif viewBuffer == -2
            gl_FragColor = texture2D(depthtex1, texcoord);
        #elif viewBuffer == -3
            gl_FragColor = texture2D(depthtex1, texcoord);
        #elif viewBuffer == -4
            gl_FragColor = texture2D(shadowtex0, texcoord);
        #elif viewBuffer == -5
            gl_FragColor = texture2D(shadowtex1, texcoord);
        #elif viewBuffer == -6
            gl_FragColor = texture2D(shadowcolor0, texcoord);
        #elif viewBuffer == -7
            gl_FragColor = texture2D(shadowcolor1, texcoord);
        #elif viewBuffer == 100
            gl_FragColor = vec4(NormalDecode(texture2D(colortex1, texcoord).r) * 0.5 + 0.5, 1.0);
        #elif viewBuffer == 101
            gl_FragColor = vec4(NormalDecode(texture2D(colortex1, texcoord).g) * 0.5 + 0.5, 1.0);
        #elif viewBuffer == 102
            gl_FragColor = vec4(vec3(linearizeDepthNorm(texture2D(depthtex0, texcoord).r)), 1.0);
        #elif viewBuffer == 103
            gl_FragColor = vec4(vec3(linearizeDepthNorm(texture2D(depthtex1, texcoord).r)), 1.0);
        #elif viewBuffer == 104
            gl_FragColor = vec4(vec3(linearizeDepthNorm(texture2D(depthtex2, texcoord).r)), 1.0);
        #endif
    #if viewBuffer != 0
    }
    else {
        gl_FragColor = texture2D(colortex0, texcoord);
    }
    #endif

    // gl_FragColor = vec4(interleaved_gradient(ivec2(texcoord * vec2(viewWidth, viewHeight)), 0));
    // gl_FragColor = vec4(InterleavedGradientNoise(texcoord * vec2(viewWidth, viewHeight)));

    // vec4 specMap = texture2D(colortex4, texcoord);
    // float emissiveness = specMap.a > 254.5/255.0 ? 0.0 : specMap.a * EmissiveStrength;
    // if(texcoord.x > viewBufferSweep)
    //     gl_FragColor = vec4(emissiveness);

    // gl_FragColor = texture2D(colortex12, texcoord);

    // if(texcoord.x > 0.95)
    //     gl_FragColor = texture2D(colortex12, texcoord).aaaa;
    // else if(texcoord.x > 0.9)
    //     gl_FragColor = vec4(0.0, 0.0, texture2D(colortex12, texcoord).b, 1.0);
    // else if(texcoord.x > 0.85)
    //     gl_FragColor = vec4(0.0, texture2D(colortex12, texcoord).g * 0.5 + 0.5, 0.0, 1.0);
    // else if(texcoord.x > 0.8)
    //     gl_FragColor = vec4(texture2D(colortex12, texcoord).r, 0.0, 0.0, 1.0);

    // gl_FragColor = vec4(length(texture2D(colortex6, texcoord).rg) > EPS);
    // gl_FragColor = vec4(abs(texture2D(colortex6, texcoord)));

    // if(texcoord.x > 0.95)
    //     gl_FragColor = vec4(cameraMoved);
}