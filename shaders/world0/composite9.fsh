#version 420 compatibility

uniform sampler2D colortex0;
uniform sampler2D colortex13;
uniform sampler2D noisetex;
uniform float aspectRatio;
uniform float viewWidth;
uniform float viewHeight;

#include "/lib/defines.glsl"
#include "/lib/functions.glsl"


// ------------------------ File Contents -----------------------
    // Final composite shader
    // Applies tonemapping and gamma correction to final image
    // Applies lens flare effect


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

    flat in vec3  skyDirect;
#endif

/* RENDERTARGETS: 0,14 */
layout(location = 0) out vec4 colorOut;
layout(location = 1) out vec4 exposureOutput;

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
    colorOut = texture(colortex0, texcoord);
    

// ------------------------ Tone Mapping ------------------------
    // reinhard tone mapping
    // colorOut.rgb = vec3(1.0) - exp(-colorOut.rgb * exposure);
    // albedo.rgb /= albedo.rgb + vec3(1.0);
    // colorOut.rgb = reinhard_extended_luminance(colorOut.rgb, exposure * 10.0);
    colorOut.rgb = reinhard_jodie(colorOut.rgb);
    // colorOut.rgb = uncharted2_filmic(colorOut.rgb);
    // gamma correction 
    // if(depth == 1.0)
        colorOut = linearToSRGB(colorOut);

    colorOut.rgb += texture(noisetex, fract(texcoord * vec2(viewWidth, viewHeight) / 512.0)).r / 255.0;

    exposureOutput = vec4(exposure);


// ------------------------- Lens Flare -------------------------
    #ifdef LensFlare
    if(flareFade > 0.0) {

        vec2 spriteCoord0 = flareRotMat * ((texcoord - flareSprite01.xy) * vec2(aspectRatio, 1.0) * 25.0) / (flareFade * 0.5 + 0.5) * 0.5 + 0.5;
        vec2 spriteCoord1 = flareRotMat * ((texcoord - flareSprite01.zw) * vec2(aspectRatio, 1.0) * 28.0) / (flareFade * 0.5 + 0.5) * 0.5 + 0.5;
        vec2 spriteCoord2 = flareRotMat * ((texcoord - flareSprite23.xy) * vec2(aspectRatio, 1.0) * 35.0) / (flareFade * 0.5 + 0.5) * 0.5 + 0.5;
        vec2 spriteCoord3 = flareRotMat * ((texcoord - flareSprite23.zw) * vec2(aspectRatio, 1.0) * 15.0) / (flareFade * 0.5 + 0.5) * 0.5 + 0.5;
        vec2 spriteCoord4 = flareRotMat * ((texcoord - flareSprite45.xy) * vec2(aspectRatio, 1.0) * 31.0) / (flareFade * 0.5 + 0.5) * 0.5 + 0.5;
        vec2 spriteCoord5 = flareRotMat * ((texcoord - flareSprite45.zw) * vec2(aspectRatio, 1.0) * 0.8 / (length(flareSunCenterVec)+0.04)) * 0.5 + 0.5;

        vec3 flare = vec3(0.0);

        if(clamp(spriteCoord0, 0.0, 1.0) == spriteCoord0)
            flare += vec3(0.07, 0.1, 0.2) * texture(colortex13, spriteCoord0 * vec2(0.3333333, 1.0)).b /* * smoothstep(1.2, 0.6, length(spriteCoord0 * 2.0 - 1.0)) */;
        if(clamp(spriteCoord1, 0.0, 1.0) == spriteCoord1)
            flare += vec3(0.2, 0.1, 0.05) * texture(colortex13, spriteCoord1 * vec2(0.3333333, 1.0)).r /* * smoothstep(1.2, 0.5, length(spriteCoord1 * 2.0 - 1.0)) */;
        if(clamp(spriteCoord2, 0.0, 1.0) == spriteCoord2)
            flare += vec3(0.05, 0.2, 0.03) * texture(colortex13, spriteCoord2 * vec2(0.3333333, 1.0)).b;
        if(clamp(spriteCoord3, 0.0, 1.0) == spriteCoord3)
            flare += vec3(0.375, 0.075, 0.195) * texture(colortex13, spriteCoord3 * vec2(0.3333333, 1.0)).g /* * smoothstep(1.0, 0.1, length(spriteCoord3 * 2.0 - 1.0)) */;
        if(clamp(spriteCoord4, 0.0, 1.0) == spriteCoord4)
            flare += vec3(0.03, 0.07, 0.15) * texture(colortex13, spriteCoord4 * vec2(0.3333333, 1.0)).b;
        if(clamp(spriteCoord5, 0.0, 1.0) == spriteCoord5)
            flare += 0.1 * texture(colortex13, spriteCoord5 * vec2(0.3333333, 1.0) + vec2(0.3333333, 0.0)).rgb;

        flare *= flareFade * skyDirect * 0.25;
        colorOut.rgb += flare;

        // vec2 sunBlurCoord = flareRotMat * flareRotMat * ((texcoord - sunScreenPos.xy) * vec2(aspectRatio, 1.0) * 8.0) / (flareFade * 0.5 + 0.5) * 0.5 + 0.5;
        // if(clamp(sunBlurCoord, 0.0, 1.0) == sunBlurCoord)
        //     colorOut.rgb += vec3(0.6) * texture(colortex13, sunBlurCoord * vec2(0.3333333, 1.0) + vec2(0.6666667, 0.0)).g * flareFade * smoothstep(1.2, 0.0, length(sunBlurCoord * 2.0 - 1.0));

    }
    #endif
}