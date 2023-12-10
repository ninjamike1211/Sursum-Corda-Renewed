// #version 430 compatibility

#define viewBuffer 0 //[0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 -1 -2 -3 -4 -5 -6 -7 100 101 102 103 104 105 106]
#define viewBufferSweep 0.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

uniform mat4  gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform float near;
uniform float far;

#include "/lib/defines.glsl"
#include "/lib/material.glsl"
// #include "/lib/kernels.glsl"
// #include "/lib/TAA.glsl"
#include "/lib/spaceConvert.glsl"
// #include "/lib/SSBO.glsl"

layout(std430, binding = 0) buffer Histogram {
    uint HistogramGlobal[256];
    float averageLum;
};


// ------------------------ File Contents -----------------------
    // Final shader, allows displaying of various buffers


in vec2 texcoord;

uniform sampler2D  colortex0;
uniform sampler2D  colortex1;
uniform sampler2D  colortex2;
uniform sampler2D  colortex3;
uniform sampler2D  colortex4;
uniform sampler2D  colortex5;
uniform usampler2D colortex6;
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

uniform float sunAngle;
uniform float viewWidth;
uniform float viewHeight;

// #ifdef Use_ShadowMap
    uniform sampler2D  shadowtex0;
    uniform sampler2D  shadowtex1;
    uniform sampler2D  shadowcolor0;
    uniform sampler2D  shadowcolor1;
// #endif

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
            gl_FragData[0] = vec4(unpackNormalVec2(texture(colortex3, texcoord).rg) * 0.5 + 0.5, 1.0);
        #elif viewBuffer == 101
            gl_FragData[0] = vec4(unpackNormalVec2(texture(colortex3, texcoord).ba) * 0.5 + 0.5, 1.0);
        // #elif viewBuffer == 102
        //     gl_FragData[0] = SpecularDecode(texture(colortex2, texcoord).b);
        // #elif viewBuffer == 103
        //     gl_FragData[0] = vec4(SpecularDecode(texture(colortex2, texcoord).b).a);
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

    // ivec2 samplePos = ivec2(gl_FragCoord.xy / 16.0);
    // if(clamp(samplePos, 0, 15) == samplePos) {
    //     // gl_FragData[0] = vec4(HistogramGlobal[samplePos.x % 16, samplePos.y / 16] / (2.0 * viewWidth * viewHeight));
    //     gl_FragData[0] = vec4(averageLum);
    // }

    // if(texcoord.x > 0.8)
    //     gl_FragData[0] = vec4(screenToViewHand(texcoord, texture(depthtex0, texcoord).r, gbufferProjectionInverse), 1.0);
    // else if(texcoord.x > 0.6)
    //     gl_FragData[0] = texture(colortex14, texcoord);

    // gl_FragData[0] = vec4(texture(colortex14, texcoord).r == 0.0);

    // if(texcoord.x > 0.5)
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 247.968635/256.0);

        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 247.0/255.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 231.0/255.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 215.0/255.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 199.0/255.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 183.0/255.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 167.0/255.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 151.0/255.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 135.0/255.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 120.0/255.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 104.0/255.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 88.0/255.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 72.0/255.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 56.0/255.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 40.0/255.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 24.0/255.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 8.0/255.0);

        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 240.0/255.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 224.0/255.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 208.0/255.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 192.0/255.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 176.0/255.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 160.0/255.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 144.0/255.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 128.0/255.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 112.0/255.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 96.0/255.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 80.0/255.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 64.0/255.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 48.0/255.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 32.0/255.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 16.0/255.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 0.0/255.0);
        
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 15.0/15.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 14.0/15.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 13.0/15.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 12.0/15.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 11.0/15.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 10.0/15.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 9.0/15.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 8.0/15.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 7.0/15.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 6.0/15.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 5.0/15.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 4.0/15.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 3.0/15.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 2.0/15.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 1.0/15.0);
        // gl_FragData[0] = vec4(texture(colortex5, texcoord).r == 0.0/15.0);

}