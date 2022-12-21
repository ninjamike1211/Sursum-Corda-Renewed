#version 400 compatibility

const float sunPathRotation = -20;

uniform float rainStrength;
// uniform mat4 gbufferModelView;
// uniform bool inEnd;
// uniform bool inNether;

// uniform sampler2D shadowtex0;
// uniform sampler2D shadowtex1;
// uniform sampler2D shadowcolor0;
// uniform mat4  gbufferModelViewInverse;
// uniform mat4  gbufferProjection;
// uniform mat4  gbufferProjectionInverse;
// uniform mat4  shadowModelView;
// uniform mat4  shadowProjection;
// uniform vec3  cameraPosition;
// uniform float near;
// uniform float far;
// uniform float viewWidth;
// uniform float viewHeight;
// uniform int   frameCounter;
// uniform int   worldTime;
// uniform bool  cameraMoved;

// uniform sampler2D noisetex;
uniform vec3 sunDir;
uniform vec3 moonDir;
// uniform vec3 sunPosition;
// uniform vec3 moonPosition;
uniform int moonPhase;
uniform float eyeAltitude;

uniform float sunHeight;
uniform float shadowHeight;

#include "/lib/defines.glsl"
#include "/lib/sky2.glsl"

in vec2 texcoord;

const int noiseTextureResolution = 512;

/* RENDERTARGETS: 10 */
layout(location = 0) out vec4 skyOut;

void main() { 

    //Ray direction
    vec3 ray_direction = unprojectSphere(texcoord);

    //Initialize color var
    vec3 color = vec3(0.0);

    //Render atmosphere
    // if(inEnd) {
    //     //Ray origin
    //     vec3 ray_origin = vec3(0.0, 6371e3 + 1.0 * (eyeAltitude + 1064), 0.0);   

    //     color = get_sky_color_end(ray_origin, ray_direction, vec3(0.0, cos(sunPathRotation * PI/180.0), sin(-sunPathRotation * PI/180.0)));
    // }
    // else if(inNether) {
    //     //Ray origin
    //     vec3 ray_origin = vec3(0.0, 6371e3 + eyeAltitude, 0.0);   

    //     color = get_sky_color_nether(ray_origin, ray_direction, vec3(0.0, 1.0, 0.0));
    // }
    // else {
        //Ray origin
        vec3 ray_origin = vec3(0.0, 6371e3 + 1.0 * (eyeAltitude + 1064), 0.0);   

        // if(clamp(texcoord, vec2(0.0), vec2(AS_RENDER_SCALE + 1e-3)) == texcoord)     
        color = get_sky_color(ray_origin, ray_direction, sunDir, moonDir, moonPhase);
        // color += 0.03 * step(0.9, texture2D(noisetex, texcoord).r);
    // }
  
    //Output
    skyOut = vec4(color, 1.0);
}