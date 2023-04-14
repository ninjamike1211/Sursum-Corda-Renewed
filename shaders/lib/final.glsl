// #version 430 compatibility

#define viewBuffer 0 //[0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 -1 -2 -3 -4 -5 -6 -7 100 101 102 103 104 105 106]
#define viewBufferSweep 0.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

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

#include "/lib/defines.glsl"
#include "/lib/material.glsl"
#include "/lib/kernels.glsl"
#include "/lib/TAA.glsl"
#include "/lib/spaceConvert.glsl"
#include "/lib/SSBO.glsl"


// ------------------------ File Contents -----------------------
    // Final shader, allows displaying of various buffers


in vec2 texcoord;

uniform sampler2D  colortex0;
uniform sampler2D  colortex1;
uniform usampler2D colortex2;
uniform sampler2D  colortex3;
uniform sampler2D  colortex4;
uniform sampler2D  colortex5;
uniform sampler2D  colortex6;
uniform sampler2D  colortex7;
uniform sampler2D  colortex8;
uniform sampler2D  colortex9;
uniform sampler2D  colortex10;
uniform sampler2D  colortex11;
uniform sampler2D  colortex12;
uniform sampler2D  colortex13;
uniform sampler2D  colortex14;
uniform sampler2D  colortex15;
uniform sampler2D  depthtex0;
uniform sampler2D  depthtex1;
uniform sampler2D  depthtex2;
uniform sampler2D  shadowtex0;
uniform sampler2D  shadowtex1;
uniform sampler2D  shadowcolor0;
uniform sampler2D  shadowcolor1;
// uniform bool hasSkyLight;

/* RENDERTARGETS: 0 */
void main() {
    #if viewBuffer != 0
    if(texcoord.x > viewBufferSweep) {
    #endif
        #if viewBuffer == 0
            gl_FragData[0] = texture(colortex0, texcoord);
        #elif viewBuffer == 1
            gl_FragData[0] = texture(colortex1, texcoord);
        #elif viewBuffer == 2
            gl_FragData[0] = texture(colortex2, texcoord);
        #elif viewBuffer == 3
            gl_FragData[0] = texture(colortex3, texcoord);
        #elif viewBuffer == 4
            gl_FragData[0] = texture(colortex4, texcoord);
        #elif viewBuffer == 5
            gl_FragData[0] = texture(colortex5, texcoord);
        #elif viewBuffer == 6
            gl_FragData[0] = texture(colortex6, texcoord);
        #elif viewBuffer == 7
            gl_FragData[0] = texture(colortex7, texcoord);
        #elif viewBuffer == 8
            gl_FragData[0] = texture(colortex8, texcoord);
        #elif viewBuffer == 9
            gl_FragData[0] = texture(colortex9, texcoord);
        #elif viewBuffer == 10
            gl_FragData[0] = texture(colortex10, texcoord);
        #elif viewBuffer == 11
            gl_FragData[0] = texture(colortex11, texcoord);
        #elif viewBuffer == 12
            gl_FragData[0] = texture(colortex12, texcoord);
        #elif viewBuffer == 13
            gl_FragData[0] = texture(colortex13, texcoord);
        #elif viewBuffer == 14
            gl_FragData[0] = texture(colortex14, texcoord);
        #elif viewBuffer == 15
            gl_FragData[0] = texture(colortex15, texcoord);
        #elif viewBuffer == -1
            gl_FragData[0] = texture(depthtex0, texcoord);
        #elif viewBuffer == -2
            gl_FragData[0] = texture(depthtex1, texcoord);
        #elif viewBuffer == -3
            gl_FragData[0] = texture(depthtex1, texcoord);
        #elif viewBuffer == -4
            gl_FragData[0] = texture(shadowtex0, texcoord);
        #elif viewBuffer == -5
            gl_FragData[0] = texture(shadowtex1, texcoord);
        #elif viewBuffer == -6
            gl_FragData[0] = texture(shadowcolor0, texcoord);
        #elif viewBuffer == -7
            gl_FragData[0] = texture(shadowcolor1, texcoord);
        #elif viewBuffer == 100
            gl_FragData[0] = vec4(NormalDecode(texture(colortex2, texcoord).r) * 0.5 + 0.5, 1.0);
        #elif viewBuffer == 101
            gl_FragData[0] = vec4(NormalDecode(texture(colortex2, texcoord).g) * 0.5 + 0.5, 1.0);
        #elif viewBuffer == 102
            gl_FragData[0] = SpecularDecode(texture(colortex2, texcoord).b);
        #elif viewBuffer == 103
            gl_FragData[0] = vec4(SpecularDecode(texture(colortex2, texcoord).b).a);
        #elif viewBuffer == 104
            gl_FragData[0] = vec4(vec3(linearizeDepthNorm(texture(depthtex0, texcoord).r, near, far)), 1.0);
        #elif viewBuffer == 105
            gl_FragData[0] = vec4(vec3(linearizeDepthNorm(texture(depthtex1, texcoord).r, near, far)), 1.0);
        #elif viewBuffer == 106
            gl_FragData[0] = vec4(vec3(linearizeDepthNorm(texture(depthtex2, texcoord).r, near, far)), 1.0);
        #endif
    #if viewBuffer != 0
    }
    else {
        gl_FragData[0] = texture(colortex0, texcoord);
    }
    #endif

    // gl_FragData[0] = vec4(interleaved_gradient(ivec2(texcoord * vec2(viewWidth, viewHeight)), 0));
    // gl_FragData[0] = vec4(InterleavedGradientNoise(texcoord * vec2(viewWidth, viewHeight)));

    // vec4 specMap = texture(colortex4, texcoord);
    // float emissiveness = specMap.a > 254.5/255.0 ? 0.0 : specMap.a * EmissiveStrength;
    // if(texcoord.x > viewBufferSweep)
    //     gl_FragData[0] = vec4(emissiveness);

    // gl_FragData[0] = texture(colortex12, texcoord);

    // if(texcoord.x > 0.95)
    //     gl_FragData[0] = texture(colortex12, vec2(0.0)).aaaa;
    // else if(texcoord.x > 0.9)
    //     gl_FragData[0] = vec4(0.0, 0.0, texture(colortex12, vec2(0.0)).b, 1.0);
    // else if(texcoord.x > 0.85)
    //     gl_FragData[0] = vec4(0.0, texture(colortex12, vec2(0.0)).g, 0.0, 1.0);
    // else if(texcoord.x > 0.8)
    //     gl_FragData[0] = vec4(texture(colortex12, vec2(0.0)).r, 0.0, 0.0, 1.0);

    // gl_FragData[0] = vec4(length(texture(colortex6, texcoord).rg) > EPS);
    // gl_FragData[0] = vec4(abs(texture(colortex6, texcoord)));

    // if(texcoord.x > 0.95)
    //     gl_FragData[0] = vec4(cameraMoved);

    // if(texcoord.x > 0.9)
    //     gl_FragData[0] = vec4(sunAngle + 0.1);

    // if(texcoord.x > 0.9)
    //     gl_FragData[0] = vec4(isnan(gl_FragData[0]));

    // if(texcoord.x > 0.5)
    //     gl_FragData[0] = vec4(isinf(texture(colortex6, texcoord)));

    // if(texcoord.x > 0.975)
    //     gl_FragData[0] = vec4(0.0, 0.0, texelFetch(colortex12, ivec2(1,0), 0).b, 0.0);
    // else if(texcoord.x > 0.95)
    //     gl_FragData[0] = vec4(0.0, texelFetch(colortex12, ivec2(1,0), 0).g, 0.0, 0.0);
    // else if(texcoord.x > 0.925)
    //     gl_FragData[0] = vec4(texelFetch(colortex12, ivec2(1,0), 0).r, 0.0, 0.0, 0.0);
    // else if(texcoord.x > 0.9) {  
    //     vec3 centerDepthData = texelFetch(colortex12, ivec2(1,0), 0).rgb;
    //     gl_FragData[0] = vec4(centerDepthData.r + (centerDepthData.g / 255.0) + (centerDepthData.b / 255.0 / 256.0));
    // }
    // else if(texcoord.x > 0.875)
    //     gl_FragData[0] = vec4(texture(depthtex0, vec2(0.5)).r);

    // if(texcoord.x > 0.9)
    //     gl_FragData[0] = vec4(hasSkyLight);

    // if(texcoord.x > 0.95)
    //     gl_FragData[0] = vec4(ssbo.caveShadowMult);
    // else if(texcoord.x > 0.9)
    //     gl_FragData[0] = vec4(ssbo.moodVelocityAvg * 0.5 + 0.5);
    //     // gl_FragData[0] = vec4(0.5);
}