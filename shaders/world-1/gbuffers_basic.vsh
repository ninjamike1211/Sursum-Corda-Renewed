#version 400 compatibility

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform bool inNether;
uniform bool inEnd;

uniform mat4  gbufferProjection;
uniform mat4  gbufferProjectionInverse;
uniform vec3  cameraPosition;
uniform float rainStrength;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform int   frameCounter;
uniform int   worldTime;
uniform bool  cameraMoved;

#include "/lib/defines.glsl"
#include "/lib/kernels.glsl"
#include "/lib/functions.glsl"

flat out vec4 glColor;
flat out vec3 glNormal;

#if defined TAA || defined MotionBlur
    uniform mat4 gbufferPreviousModelView;
    uniform mat4 gbufferPreviousProjection;
    uniform vec3 previousCameraPosition;
    
    out vec4 oldClipPos;
    out vec4 newClipPos;
#endif

void main() {
    gl_Position = ftransform();

    #if defined TAA || defined MotionBlur
        newClipPos = gl_Position;

        vec3 newViewPos = (gbufferProjectionInverse * gl_Position).xyz;
        vec3 newEyePlayerPos = mat3(gbufferModelViewInverse) * newViewPos;
        vec4 oldViewPos = gbufferPreviousModelView * vec4(newEyePlayerPos + cameraPosition - previousCameraPosition, 0.0);
        oldClipPos = gbufferPreviousProjection * oldViewPos;

        #if defined TAA
            int taaIndex = frameCounter % 16;
            gl_Position += vec4((TAAOffsets[taaIndex] * 2.0 - 1.0) * gl_Position.w / vec2(viewWidth, viewHeight), 0.0, 0.0);
        #endif
    #endif

    glColor = gl_Color;

    glNormal = normalize((gbufferModelViewInverse * vec4(gl_NormalMatrix * gl_Normal, 0.0)).xyz);
}