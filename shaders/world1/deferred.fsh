#version 400 compatibility

const float sunPathRotation = -20;

uniform float rainStrength;
uniform float sunHeight;
uniform float shadowHeight;
uniform int moonPhase;
uniform float eyeAltitude;

#include "/defines.glsl"
#include "/sky2.glsl"


in vec2 texcoord;

const int noiseTextureResolution = 512;

/* RENDERTARGETS: 10 */
layout(location = 0) out vec4 skyOut;

void main() { 

    //Ray direction
    vec3 ray_direction = unprojectSphere(texcoord);

    //Ray origin
    vec3 ray_origin = vec3(0.0, 6371e3 + 1.0 * (eyeAltitude + 1064), 0.0);   

    //Initialize color var
    vec3 color = vec3(0.0);

    //Render atmosphere
    color = get_sky_color_end(ray_origin, ray_direction, vec3(0.0, cos(sunPathRotation * PI/180.0), sin(-sunPathRotation * PI/180.0)));

    //Output
    skyOut = vec4(color, 1.0);
}