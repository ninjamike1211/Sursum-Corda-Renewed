#version 420 compatibility

const float sunPathRotation = -20;

uniform vec3 fogColor;
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
    
    // vec3 ray_direction = unprojectSphere(texcoord);
    // vec3 ray_origin = vec3(0.0, 6371e3 + 1.0 * (eyeAltitude + 1064), 0.0);   
    
    // skyOut.rgb = get_sky_color_nether(ray_origin, ray_direction, vec3(0.0, 1.0, 0.0));
    // skyOut.a = 1.0;

    skyOut = vec4(fogColor*0.7, 1.0);
}

// const float sunPathRotation = -20;

// uniform float rainStrength;
// uniform sampler2D colortex0;
// uniform sampler2D colortex1;
// uniform sampler2D colortex2;
// uniform sampler2D colortex5;
// uniform sampler2D colortex7;
// uniform sampler2D colortex9;
// uniform sampler2D colortex10;
// uniform sampler2D depthtex0;
// uniform sampler2D depthtex1;
// uniform sampler2D noisetex;
// uniform vec3 lightDir;
// uniform vec3 sunDir;
// uniform vec3 sunDirView;
// uniform mat4 gbufferModelView;
// uniform mat4 gbufferModelViewInverse;
// uniform mat4 gbufferProjectionInverse;
// uniform vec3 cameraPosition;
// uniform float frameTimeCounter;
// uniform float eyeAltitude;
// uniform int isEyeInWater;
// uniform float wetness;
// uniform bool inEnd;
// uniform bool inNether;

// uniform mat4  gbufferProjection;
// uniform float near;
// uniform float far;
// uniform float viewWidth;
// uniform float viewHeight;
// uniform int   frameCounter;
// uniform int   worldTime;
// uniform bool  cameraMoved;

// uniform float sunHeight;
// uniform float shadowHeight;
// uniform int moonPhase;

// #include "/lib/defines.glsl"
// #include "/lib/kernels.glsl"
// #include "/lib/functions.glsl"
// #include "/lib/sky2.glsl"

// uniform vec3 moonDir;
// uniform vec3 fogColor;

// in vec2 texcoord;

// const int noiseTextureResolution = 512;

// /* RENDERTARGETS: 10 */
// layout(location = 0) out vec4 skyOut;

// void main() { 

//     //Ray direction
//     vec3 ray_direction = unprojectSphere(texcoord);

//     //Ray origin
//     vec3 ray_origin = vec3(0.0, 6371e3 + eyeAltitude, 0.0);

//     //Initialize color var
//     vec3 color = vec3(0.0);

//     //Render atmosphere
//     color = get_sky_color_nether(ray_origin, ray_direction, vec3(0.0, 1.0, 0.0));
  
//     //Output
//     skyOut = vec4(fogColor*0.7, 1.0);
// }