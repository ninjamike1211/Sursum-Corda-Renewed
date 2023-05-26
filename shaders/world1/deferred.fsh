#version 430 compatibility

const float sunPathRotation = -20;

uniform vec3  sunDir;
uniform vec3  moonDir;
uniform float rainStrength;
uniform float eyeAltitude;
uniform float sunHeight;
uniform float shadowHeight;
uniform int   moonPhase;

#include "/lib/defines.glsl"
#include "/lib/sky2.glsl"


// ------------------------ File Contents -----------------------
    // Sky atmospheric rendering
    // Outputs sky to colortex10


in vec2 texcoord;

/* RENDERTARGETS: 10 */
layout(location = 0) out vec4 skyOut;

void main() { 

// ---------------------- Sky Atmospherics ----------------------
    
    vec3 ray_direction = unprojectSphere(texcoord);
    vec3 ray_origin = vec3(0.0, 6371e3 + 1.0 * (eyeAltitude + 1064), 0.0);   
    
    skyOut.rgb = get_sky_color_end(ray_origin, ray_direction, vec3(0.0, cos(sunPathRotation * PI/180.0), sin(-sunPathRotation * PI/180.0)));
    skyOut.a = 1.0;

}
