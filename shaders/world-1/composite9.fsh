#version 430 compatibility

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


in vec2 texcoord;
in vec3 viewVector;
flat in float exposure;


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
}