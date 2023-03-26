// #version 150 compatibility
// #extension GL_ARB_explicit_attrib_location : enable

// // #include "/lib/material.glsl"

// in vec4 starData;

// /* DRAWBUFFERS:1 */
// layout(location = 0) out vec4 albedo;
// // layout(location = 1) out uvec3 specMapOut;

// void main() {
//     // if(starData.a > 0.5)
//     //     discard;
//     // color = vec4(0.0);

//     // color = vec4(step(0.5, starData.a));
//     // albedo = 0.5 * starData * starData.a;
//     albedo = vec4(starData.rgb, 1.0);
//     // albedo = vec4(1.0, 0.0, 0.5, 1.0);

//     // specMapOut = uvec3(0, 0, SpecularEncode(vec4(0.0, 0.0, 0.0, 0.5)));
// }

#version 420 compatibility
#extension GL_ARB_explicit_attrib_location : enable

#include "/lib/material.glsl"

in vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.

/* DRAWBUFFERS:1 */
layout(location = 0) out vec4 colorOut;


void main() {

    colorOut = vec4(starData.rgb * starData.a * 0.125, 1.0);
}