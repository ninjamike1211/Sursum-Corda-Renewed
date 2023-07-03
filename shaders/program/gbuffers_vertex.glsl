#include "/lib/defines.glsl"

uniform mat4  gbufferModelViewInverse;
uniform vec3  cameraPosition;

#if (defined wavingPlants) || (!defined inNether && !defined inEnd)
    uniform float rainStrength;
#endif

#if defined inNether || defined wavingPlants
    uniform float frameTimeCounter;
#endif

#if defined TAA
    uniform int frameCounter;
    uniform float viewWidth;
    uniform float viewHeight;
#endif

#if !defined inEnd && !defined inNether
    uniform sampler2D colortex10;
    uniform float sunHeight;
    uniform float shadowHeight;
    uniform int   moonPhase;
#endif

#ifdef inNether
    uniform vec3 fogColor;
#endif


#if defined TAA || defined MotionBlur
    uniform vec3 previousCameraPosition;
    uniform mat4 gbufferPreviousModelView;
    uniform mat4 gbufferPreviousProjection;

    in vec3 at_velocity;
#endif

#ifdef mcEntity
    in vec4 mc_Entity;
#else
    uniform int blockEntityId;
#endif

#ifdef entities
    uniform int entityId;
#endif

in vec4 at_tangent;
in vec2 mc_midTexCoord;

#ifdef wavingPlants
    in vec3 at_midBlock;
#endif

out VertexData {
    vec2 texcoord;
    vec4 glColor;
    vec2 lmcoord;
    vec3 viewPos;
    vec3 scenePos;
    vec3 tbnPos;
    flat mat3 tbn;
    flat vec4 textureBounds;
    flat vec3 glNormal;
    flat vec3 skyAmbient;
    flat vec3 skyDirect;
    flat int  entity;

    #ifdef inNether
        flat vec3 lightDir;
        flat vec3 lightDirView;
    #endif

    // #ifdef POM_TexSizeFix
        vec2 localTexcoord;
    // #endif

    #if defined TAA || defined MotionBlur
        vec4 oldClipPos;
        vec4 newClipPos;
    #endif

};

#include "/lib/SSBO.glsl"
#include "/lib/kernels.glsl"
#include "/lib/noise.glsl"
#include "/lib/TAA.glsl"
#include "/lib/spaceConvert.glsl"
#include "/lib/functions.glsl"
#include "/lib/sky2.glsl"
#include "/lib/waving.glsl"

// ------------------------ File Contents -----------------------
    // Gbuffers primary vertex shader
    // Calculates basic geometry values
    // Applies fixes/overrides for specific geometry
    // Position calculations, including waving geometry
    // Normals and TBN calculations
    // Motion vector calculations for TAA or Motion Blur



void main() {

// -------------------- Basic Geometry Values -------------------
    glColor = gl_Color;

    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_MultiTexCoord1 / 256.0).xy;

    #ifdef inNether
        skyDirect = netherDirectLight;
        skyAmbient = netherAmbientLight;

        lightDir = normalize(vec3(0.5, 1.0, 0.5) + 0.2 * vec3(
            SimplexPerlin2D(frameTimeCounter * vec2(2.0, 3.0)), 0.0, SimplexPerlin2D(frameTimeCounter * vec2(2.5, 1.5))
        ));
        lightDirView = (gl_ModelViewMatrix * vec4(lightDir, 0.0)).xyz;
    #elif defined inEnd
        skyDirect = endDirectLight;
        skyAmbient = endAmbientLight;
    #else
        skyDirect = sunLightSample(sunHeight, shadowHeight, rainStrength, moonPhase);
        skyAmbient = skyLightSample(colortex10);
    #endif

    vec2 halfSize = abs(texcoord - mc_midTexCoord);
	textureBounds = vec4(mc_midTexCoord.xy - halfSize, mc_midTexCoord.xy + halfSize);

    // #ifdef POM_TexSizeFix
        localTexcoord = (texcoord - textureBounds.xy) / (textureBounds.zw - textureBounds.xy);
    // #endif

    #ifdef entities
        entity = entityId;
    #elif defined mcEntity
        entity = int(mc_Entity.x + 0.5);
    #else
        entity = blockEntityId;
    #endif


// ---------------------- Fixes/Overrides -----------------------

    // Discard entity shadows (the circular texture under entities)
    if(entity == 11000) {
        gl_Position = vec4(10.0, 10.0, 10.0, 1.0);
        return;
    }
    
    // Thanks Belmu#4066 for thanking Niemand#1929 for the nametag fix :)
    #ifdef entities
        if(gl_Color.a >= 0.24 && gl_Color.a < 0.255) {
            gl_Position = vec4(10.0, 10.0, 10.0, 1.0);
            return;
        }
    #endif

    // Beacon Beam
    #ifdef BeaconBeam
        if(glColor.a < 0.98) {
            gl_Position = vec4(10.0, 10.0, 10.0, 1.0);
            return;
        }
        else {
            glColor.rgb *= 1.0 / (luminance(glColor.rgb) * 0.7 + 0.3);
        }
    #endif

    // Water inside filled cauldron
    if(entity == 10030 && glColor.r < 0.5) {
        entity = 10010;
        glColor *= 1.7;
    }


// ------------------- Position Calculations --------------------
    vec4 modelPos = gl_Vertex;

    #ifdef wavingPlants
        if(entity > 10000 && entity < 11000) {
            vec3 worldPos = modelPos.xyz + cameraPosition;
            
            modelPos.xyz += wavingOffset(worldPos, entity, at_midBlock, glNormal, frameTimeCounter, rainStrength);
        }
    #endif

    gl_Position = gl_ModelViewProjectionMatrix * modelPos;
    viewPos = (gl_ModelViewMatrix * modelPos).xyz;
    scenePos = (gbufferModelViewInverse * vec4(viewPos, 0.0)).xyz;


// ---------------------- Normals and TBN -----------------------
    vec3  normal = normalize(gl_NormalMatrix * gl_Normal);
    float viewDotN = dot(normalize(viewPos), normal);
    if(viewDotN > 0.0)
        normal *= -1.0;

        glNormal = normalize((gbufferModelViewInverse * vec4(normal,                           0.0)).xyz);
    vec3 tangent = normalize((gbufferModelViewInverse * vec4(gl_NormalMatrix * at_tangent.xyz, 0.0)).xyz);
    
    if(entity == 10020) {
        glNormal = round(glNormal);
        tangent = round(tangent);
    }
    
    vec3 bitangent = sign(at_tangent.w) * cross(tangent, glNormal);

    tbn = mat3(	tangent, bitangent, glNormal);

    tbnPos = scenePos * tbn;


// ----------------------- Motion Vectors -----------------------
    #if defined TAA || defined MotionBlur
        newClipPos = gl_Position;

        #if defined hand
            oldClipPos = gl_ProjectionMatrix * vec4(viewPos - at_velocity, 1.0);

        #elif defined noVelocity
            vec4 oldViewPos = gbufferPreviousModelView * (vec4(scenePos, 0.0) + vec4(cameraPosition - previousCameraPosition, 0.0));
            oldClipPos = gbufferPreviousProjection * oldViewPos;
        
        #else
            if(any(lessThanEqual(at_velocity, vec3(EPS)))) {
                vec4 oldViewPos = gbufferPreviousModelView * (vec4(scenePos, 0.0) + vec4(cameraPosition - previousCameraPosition, 0.0));
                oldClipPos = gbufferPreviousProjection * oldViewPos;
            }
            else {
                oldClipPos = gbufferPreviousProjection * vec4(viewPos - at_velocity, 1.0);
            }
        #endif

        #if defined TAA
            gl_Position.xy += taaOffset(frameCounter, vec2(viewWidth, viewHeight)) * gl_Position.w;
        #endif
    #endif

}