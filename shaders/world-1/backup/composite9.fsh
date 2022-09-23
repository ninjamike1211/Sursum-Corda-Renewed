#version 420 compatibility

uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform sampler2D colortex6;
uniform sampler2D colortex13;
uniform sampler2D noisetex;
uniform mat4 gbufferModelView;
// uniform mat4 gbufferModelViewInverse;
uniform bool inEnd;
uniform bool inNether;
// uniform vec3 lightDir;
// uniform vec3 sunPosition;
uniform float aspectRatio;

#include "/functions.glsl"

in vec2 texcoord;
in vec3 viewVector;
flat in float exposure;

#ifdef LensFlare
    flat in vec2  sunScreenPos;
    flat in vec2  flareSunCenterVec;
    flat in float flareFade;
    flat in mat2  flareRotMat;
    flat in vec4  flareSprite01;
    flat in vec4  flareSprite23;
    flat in vec4  flareSprite45;
#endif

/* RENDERTARGETS: 0,14 */
layout(location = 0) out vec4 colorOut;
layout(location = 1) out vec4 exposureOutput;
// layout(location = 2) out vec4 testOut;

vec3 change_luminance(vec3 c_in, float l_out) {
    float l_in = luminance(c_in);
    return c_in * (l_out / l_in);
}

vec3 reinhard_extended_luminance(vec3 v, float max_white_l) {
    float l_old = luminance(v);
    float numerator = l_old * (1.0f + (l_old / (max_white_l * max_white_l)));
    float l_new = numerator / (1.0f + l_old);
    return change_luminance(v, l_new);
}

vec3 reinhard_jodie(vec3 v) {
    float l = luminance(v);
    vec3 tv = v / (1.0f + v);
    return mix(v / (1.0f + l), tv, tv);
}

vec3 uncharted2_tonemap_partial(vec3 x) {
    float A = 0.15f;
    float B = 0.50f;
    float C = 0.10f;
    float D = 0.20f;
    float E = 0.02f;
    float F = 0.30f;
    return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

vec3 uncharted2_filmic(vec3 v) {
    float exposure_bias = 2.0f;
    vec3 curr = uncharted2_tonemap_partial(v * exposure_bias);

    vec3 W = vec3(11.2f);
    vec3 white_scale = vec3(1.0f) / uncharted2_tonemap_partial(W);
    return curr * white_scale;
}

void main() {
    colorOut = texture2D(colortex0, texcoord);

// ------------------- Motion Blur -------------------
    #ifdef MotionBlur
        vec2 velocity = texture2D(colortex6, texcoord).xy;

        if(length(velocity) > 1.0 / viewWidth) {
            float isHand = texture2D(colortex3, texcoord).b;
            int samples = 1;
            
            for(int i = 1; i < MotionBlur_Samples+1; i++) {
                vec2 sampleCoord = texcoord + 0.75 * i * velocity / (MotionBlur_Samples+1);
                if(clamp(sampleCoord, 0.0, 1.0) == sampleCoord) {
                    if(isHand == texture2D(colortex3, sampleCoord).b) {
                        colorOut.rgb += texture2D(colortex0, sampleCoord).rgb;
                        samples++;
                    }
                }
            }
            
            colorOut.rgb /= samples;
        }
    #endif
    

    // reinhard tone mapping
    // albedo.rgb = vec3(1.0) - exp(-albedo.rgb * exposure);
    // albedo.rgb /= albedo.rgb + vec3(1.0);
    // albedo.rgb = reinhard_extended_luminance(albedo.rgb, exposure);
    colorOut.rgb = reinhard_jodie(colorOut.rgb);
    // albedo.rgb = uncharted2_filmic(albedo.rgb);
    // gamma correction 
    // if(depth == 1.0)
        colorOut = linearToSRGB(colorOut);

    colorOut.rgb += texture2D(noisetex, fract(texcoord * vec2(viewWidth, viewHeight) / 512.0)).r / 255.0;

    exposureOutput = vec4(exposure);
}