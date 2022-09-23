uniform float rainStrength;
uniform mat4 gbufferModelViewInverse;
uniform sampler2D colortex10;
uniform sampler2D normals;
uniform float shadowAngle;
uniform float sunAngle;
uniform float sunHeight;
uniform float shadowHeight;
uniform int moonPhase;
// uniform vec3 lightDir;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform int renderStage;
uniform vec3 fogColor;
// uniform float frameTime;
// uniform ivec2 atlasSize;

uniform mat4 gbufferModelView;
uniform bool inEnd;
uniform bool inNether;

in vec4 at_tangent;
in vec2 mc_midTexCoord;
// in vec3 at_midBlock;

out vec2 texcoord;
out vec4 glColor;
flat out vec3 glNormal;
out vec2 lmcoord;
out vec3 viewPos;
out vec3 scenePos;
out vec3 tbnPos;
flat out vec4 textureBounds;
flat out vec2 singleTexSize;
flat out int entity;
flat out vec3 skyAmbient;
flat out vec3 skyDirect;
flat out mat3 tbn;
flat out vec3 lightDir;
flat out vec3 lightDirView;
// flat out mat3 tbnView;

uniform mat4  gbufferProjection;
uniform mat4  gbufferProjectionInverse;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform int   frameCounter;
uniform int   worldTime;
uniform bool  cameraMoved;

#include "/defines.glsl"
#include "/kernels.glsl"
#include "/noise.glsl"
#include "/functions.glsl"
#include "/sky2.glsl"
#include "/waving.glsl"

// out float isWaterBackface;

#if defined TAA || defined MotionBlur
    // uniform vec3 cameraPosition;
    uniform vec3 previousCameraPosition;
    uniform mat4 gbufferPreviousModelView;
    uniform mat4 gbufferPreviousProjection;

    in vec3 at_velocity;

    out vec4 oldClipPos;
    out vec4 newClipPos;
#endif

#ifdef mcEntity
    in vec4 mc_Entity;
#else
    uniform int blockEntityId;
#endif

#ifdef entities
    uniform int entityId;
#endif


void main() {

    glColor = gl_Color;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    vec2 halfSize = abs(texcoord - mc_midTexCoord);
	textureBounds = vec4(mc_midTexCoord.xy - halfSize, mc_midTexCoord.xy + halfSize);
    singleTexSize = halfSize * 2.0;

    #ifdef entities
        // Thanks Belmu#4066 for thanking Niemand#1929 for the nametag fix :)
        if(glColor.a >= 0.24 && glColor.a < 0.255) {
            gl_Position = vec4(10.0, 10.0, 10.0, 1.0);
            return;
        }

        // glColor.rgb = vec3(10.0);
    #endif

    #ifdef BeaconBeam
        if(glColor.a < 0.98) {
            gl_Position = vec4(10.0, 10.0, 10.0, 1.0);
            return;
        }
        else {
            glColor.rgb *= 1.0 / (luminance(glColor.rgb) * 0.7 + 0.3);
        }
    #endif


    #ifdef mcEntity
        entity = int(mc_Entity.x + 0.5);
    #else
        entity = blockEntityId;
    #endif
    
    vec4 modelPos = gl_Vertex;

    glNormal = normalize((gbufferModelViewInverse * vec4(gl_NormalMatrix * gl_Normal, 0.0)).xyz);

    #ifdef wavingPlants
        if(entity > 10000) {
            vec3 worldPos = modelPos.xyz + cameraPosition;
            
            modelPos.xyz += wavingOffset(worldPos, entity, texcoord, textureBounds);
        }
    #endif

    gl_Position = gl_ModelViewProjectionMatrix * modelPos;
    viewPos = (gl_ModelViewMatrix * modelPos).xyz;
    scenePos = (gbufferModelViewInverse * vec4(viewPos, 0.0)).xyz;

    // if (entity == 10010 /* water ID */) {
    //     // vec3 worldPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz + cameraPosition;
    //     vec3 pos = gl_Vertex.xyz + cameraPosition;
    //     vec3 posRound = floor(pos + 0.5);
    //     vec3 posDiff = abs(pos - posRound);
    //     // float maxDiff = max(max(posDiff.x, posDiff.y), posDiff.z);

    //     // if(maxDiff > 0.0 && maxDiff < 0.005) {
    //     //     isWaterBackface = 1.0;
    //     // }
    //     // else {
    //     //     isWaterBackface = 0.0;
    //     // }

    //     // isWaterBackface = step(0.0, maxDiff) * step(maxDiff, 0.005);
    //     isWaterBackface = float(clamp(posDiff, 0.0, 0.005) == posDiff);
    //     isWaterBackface *= float((textureBounds.z - textureBounds.x) <= 15.0 / atlasSize.x);

	// 	// if (gl_Normal.y > 0.01) {
	// 	// 	//the bottom face doesn't have a backface.
	// 	// }
	// 	// else if (gl_Normal.y < -0.01) {
	// 	// 	//sneaky back face of top needs weird checks.
	// 	// 	if (at_midBlock.y < 30.75) {
	// 	// 		gl_Position = vec4(10.0);
	// 	// 		return;
	// 	// 	}
	// 	// }
	// 	// else {
	// 	// 	if (dot(gl_Normal, at_midBlock) > 0.0) {
	// 	// 		gl_Position = vec4(10.0);
	// 	// 		return;
	// 	// 	}
	// 	// }
	// }

    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

    skyAmbient = netherAmbientLight;
    skyDirect = netherDirectLight;

    #if defined TAA || defined MotionBlur
        newClipPos = gl_Position;
        // glColor.rgb = at_velocity;

        // #if defined entities
        //     if(entityId == 10001) {
        //         vec4 oldViewPos = gbufferPreviousModelView * (vec4(scenePos, 0.0) + vec4(cameraPosition - previousCameraPosition, 0.0));
        //         oldClipPos = gbufferPreviousProjection * oldViewPos;
        //     }
        //     else {
        //         oldClipPos = gbufferPreviousProjection * vec4(viewPos - at_velocity, 1.0);
        //     }
        // #elif defined block
        //     // if(textureLod(normals, texcoord, 0.0).r < EPS) {
        //     if(cameraMoved && any(lessThanEqual(at_velocity, vec3(EPS)))) {
        //         vec4 oldViewPos = gbufferPreviousModelView * (vec4(scenePos, 0.0) + vec4(cameraPosition - previousCameraPosition, 0.0));
        //         oldClipPos = gbufferPreviousProjection * oldViewPos;
        //     }
        //     else {
        //         oldClipPos = gbufferPreviousProjection * vec4(viewPos - at_velocity, 1.0);
        //     }
        // #elif defined hand
        //     oldClipPos = gl_ProjectionMatrix * vec4(viewPos - at_velocity, 1.0);
        // #elif defined taaEntityVelocity
        //     oldClipPos = gbufferPreviousProjection * vec4(viewPos - at_velocity, 1.0);
        // #else
        //     vec4 oldViewPos = gbufferPreviousModelView * (vec4(scenePos, 0.0) + vec4(cameraPosition - previousCameraPosition, 0.0));
        //     oldClipPos = gbufferPreviousProjection * oldViewPos;
        // #endif

        #if defined hand
            oldClipPos = gl_ProjectionMatrix * vec4(viewPos - at_velocity, 1.0);
        #else
            if(cameraMoved && any(lessThanEqual(at_velocity, vec3(EPS)))) {
                vec4 oldViewPos = gbufferPreviousModelView * (vec4(scenePos, 0.0) + vec4(cameraPosition - previousCameraPosition, 0.0));
                oldClipPos = gbufferPreviousProjection * oldViewPos;
            }
            else {
                oldClipPos = gbufferPreviousProjection * vec4(viewPos - at_velocity, 1.0);
            }
        #endif

        #if defined TAA
            // int taaIndex = frameCounter % 16;
            // gl_Position += vec4((TAAOffsets[taaIndex] * 2.0 - 1.0) * gl_Position.w / vec2(viewWidth, viewHeight), 0.0, 0.0);
            gl_Position.xy += taaOffset() * gl_Position.w;
        #endif
    #endif


    vec3 tangent = normalize((gbufferModelViewInverse * vec4(gl_NormalMatrix * at_tangent.xyz, 0.0)).xyz);
    
    if(entity == 10020) {
        glNormal = round(glNormal);
        tangent = round(tangent);
    }
    
    // vec3 binormal = normalize((gbufferModelViewInverse * vec4(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w, 0.0)).xyz);
    vec3 binormal = cross(tangent, glNormal);

    tbn = mat3(	tangent, binormal, glNormal);

    tbnPos = scenePos * tbn;

    // vec3 glNormalView = normalize(gl_NormalMatrix * gl_Normal);
    // vec3 tangentView = normalize(gl_NormalMatrix * at_tangent.xyz);
    // vec3 binormalView = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);

    // tbnView = mat3(	tangentView, binormalView, glNormalView);

    // tbnViewPos = viewPos * tbnView;

    // vec3 lightDir = normalize(vec3(0.3, 1.0, 0.3) + 0.2 * vec3(
    //     0.6 * cos(frameTimeCounter * PI * 2 + 1.0) + 0.3 * cos(frameTimeCounter * PI * 10 + 2.0) + 0.1 * cos(frameTimeCounter * PI * 20 + 0.5), 0.0, 
    //     0.6 * cos(frameTimeCounter * PI * 3 + 4.0) + 0.3 * cos(frameTimeCounter * PI * 8  + 1.5) + 0.1 * cos(frameTimeCounter * PI * 22 + 0.2)
    // ));
    lightDir = normalize(vec3(0.5, 1.0, 0.5) + 0.2 * vec3(
        SimplexPerlin2D(frameTimeCounter * vec2(2.0, 3.0)), 0.0, SimplexPerlin2D(frameTimeCounter * vec2(2.5, 1.5))
    ));
    lightDirView = (gl_ModelViewMatrix * vec4(lightDir, 0.0)).xyz;
}