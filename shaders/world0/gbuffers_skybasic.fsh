
#version 430 compatibility
#extension GL_ARB_explicit_attrib_location : enable

#include "/lib/defines.glsl"
#include "/lib/material.glsl"

in vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.

/* DRAWBUFFERS:1 */
layout(location = 0) out vec4 colorOut;


void main() {

    colorOut = vec4(starData.rgb * starData.a * 0.125, 1.0);
}