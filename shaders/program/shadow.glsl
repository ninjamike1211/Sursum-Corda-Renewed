#ifdef Shadow_Vertex

    // uniform sampler2D colortex12;

    uniform mat4  shadowModelViewInverse;
    uniform float rainStrength;
    uniform float frameTimeCounter;
    uniform vec3  cameraPosition;


    // ------------------------ File Contents -----------------------
        // Shadows vertex shader

    in vec3 at_midBlock;
    in vec4 mc_Entity;

    out vec2 texcoord;
    out vec4 glColor;
    out vec3 worldPosVertex;
    out vec2 clipXY;
    out vec3 glNormal;
    flat out int entity;

    #define shadowGbuffer

    #include "/lib/SSBO.glsl"
    #include "/lib/defines.glsl"
    #include "/lib/functions.glsl"
    #include "/lib/TAA.glsl"
    #include "/lib/shadows.glsl"
    #include "/lib/waving.glsl"

    void main() {

        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

        glColor = gl_Color;
        entity = int(mc_Entity.x);
        glNormal = normalize(gl_NormalMatrix * gl_Normal);

        // float NdotL = dot(glNormal, vec3(0.0, 0.0, 1.0));


    // -------------------- Position Calculations -------------------
        vec4 modelPos = gl_Vertex;

        // Fix for water inside cauldron incorrectly self-shadowing
        if(entity == 10030 && glColor.r < 0.5) {
            modelPos.y -= 0.2;
        }

        // Apply waving geometry
        #ifdef wavingPlants
        if(entity > 10000) {
            vec3 worldPos = modelPos.xyz + cameraPosition;
            
            modelPos.xyz += wavingOffset(worldPos, entity, at_midBlock, glNormal, frameTimeCounter, rainStrength);
        }
        #endif

        // Calculate world positions
        vec3 shadowViewPos = (gl_ModelViewMatrix * modelPos).xyz;
        vec3 scenePos = (shadowModelViewInverse * vec4(shadowViewPos, 1.0)).xyz;
        worldPosVertex = scenePos + cameraPosition;

        // Calculate clip position and shadow distortion
        gl_Position = gl_ProjectionMatrix * vec4(shadowViewPos, 1.0);
        // float clipLen = length(gl_Position.xy);
        clipXY = gl_Position.xy;

        gl_Position.xyz = distort(gl_Position.xyz);
        // gl_Position.xyz = shadowDistortion(gl_Position.xyz);

        // float bias = getShadowBias(glNormal.z, clipLen);
        // gl_Position.z += bias;

    }

#else

    // #extension GL_ARB_conservative_depth : enable

    #define shadowGbuffer

    uniform sampler2D tex;
    uniform float alphaTestRef;
    uniform float frameTimeCounter;

    #include "/lib/functions.glsl"
    #include "/lib/defines.glsl"
    #include "/lib/noise.glsl"
    #include "/lib/water.glsl"
    #include "/lib/shadows.glsl"


    // ------------------------ File Contents -----------------------
        // Shadows fragment shader
        // Applies water cuastics to shadows


    in vec2 texcoord;
    in vec4 glColor;
    in vec3 worldPosVertex;
    in vec2 clipXY;
    in vec3 glNormal;
    flat in int entity;

    // layout(depth_greater) out float gl_FragDepth;
    layout(location = 0)  out vec4  shadowColor;

    void main() {

        vec2 texcoordFinal = texcoord;

        shadowColor = texture(tex, texcoordFinal) * glColor;
        if (shadowColor.a < alphaTestRef) discard;

        // float clipLen = length(clipXY);
        // float bias = getShadowBias(glNormal.z, clipLen);
        // gl_FragDepth += bias;

        shadowColor.rgb = shadowColor.rgb;

        if(entity == 10010) {
            shadowColor.a = 0.0;

            float waterHeight = (1.0 - abs(waterHeightFuncSimple(worldPosVertex.xz, frameTimeCounter) * 2.0 - 1.0));
            float caustics = Water_Depth * pow(waterHeight, 3.0) + 0.5*(1 - Water_Depth) * 0.8 + 0.2;

            // caustics += 1.0;
            // caustics *= 2.0;

            shadowColor.rgb = glColor.rgb * caustics;
        }
    }

#endif