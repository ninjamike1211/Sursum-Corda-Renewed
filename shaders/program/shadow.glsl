#ifdef Shadow_Vertex

    // uniform sampler2D colortex12;

    uniform mat4  shadowModelViewInverse;
    uniform vec3  cameraPosition;
    uniform float rainStrength;
    uniform float frameTimeCounter;
    uniform int   renderStage;

    layout (r8ui) uniform uimage3D voxelImage;


    // ------------------------ File Contents -----------------------
        // Shadows vertex shader

    in vec3 at_midBlock;
    in vec4 mc_Entity;

    out vec2 texcoord;
    out vec4 glColor;
    // out vec3 worldPosVertex;
    // out vec3 glNormal;
    flat out int entity;

    #define shadowGbuffer

    #include "/lib/defines.glsl"
    #include "/lib/shadows.glsl"
    #include "/lib/voxel.glsl"

    void main() {

        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

        glColor = gl_Color;
        entity = int(mc_Entity.x);
        // glNormal = normalize(gl_NormalMatrix * gl_Normal);

        // float NdotL = dot(glNormal, vec3(0.0, 0.0, 1.0));


    // -------------------- Position Calculations -------------------
        // vec4 modelPos = gl_Vertex;

        // // Fix for water inside cauldron incorrectly self-shadowing
        // if(entity == 10030 && glColor.r < 0.5) {
        //     modelPos.y -= 0.2;
        // }

        // Apply waving geometry
        // #ifdef wavingPlants
        // if(entity > 10000) {
        //     vec3 worldPos = modelPos.xyz + cameraPosition;
            
        //     modelPos.xyz += wavingOffset(worldPos, entity, at_midBlock, glNormal, frameTimeCounter, rainStrength);
        // }
        // #endif

        // // Calculate world positions
        // vec3 shadowViewPos = (gl_ModelViewMatrix * modelPos).xyz;
        // vec3 scenePos = (shadowModelViewInverse * vec4(shadowViewPos, 1.0)).xyz;
        // worldPosVertex = scenePos + cameraPosition;

        // // Calculate clip position and shadow distortion
        // gl_Position = gl_ProjectionMatrix * vec4(shadowViewPos, 1.0);

        gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
        gl_Position.xyz = distort(gl_Position.xyz);

        #ifdef UseVoxelization
            bool isBlock = renderStage == MC_RENDER_STAGE_TERRAIN_SOLID ||
                renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT_MIPPED ||
                renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT ||
                renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT;
            
            if (isBlock && gl_VertexID % 4 == 0) {
                vec3 centerPos = gl_Vertex.xyz + at_midBlock / 64.0;
                ivec3 voxelPos = sceneToVoxel(centerPos, cameraPosition);

                if(clamp(voxelPos.xz, ivec2(0), ivec2(512)) == voxelPos.xz) {
                    uint blockID = uint(mc_Entity.x + 0.5);

                    if(blockID == 0) {
                        blockID = 64;
                    }

                    imageStore(voxelImage, voxelPos, uvec4(blockID));
                }
            }
        #endif

    }

#else

    // #extension GL_ARB_conservative_depth : enable

    #define shadowGbuffer

    uniform sampler2D tex;
    uniform float alphaTestRef;
    uniform float frameTimeCounter;

    // #include "/lib/functions.glsl"
    #include "/lib/defines.glsl"
    // #include "/lib/noise.glsl"
    // #include "/lib/water.glsl"
    #include "/lib/shadows.glsl"


    // ------------------------ File Contents -----------------------
        // Shadows fragment shader
        // Applies water cuastics to shadows


    in vec2 texcoord;
    in vec4 glColor;
    in vec3 worldPosVertex;
    in vec3 glNormal;
    flat in int entity;

    #if Shadow_Transparent > 0
        /* RENDERTARGETS: 0 */
        layout(location = 0)  out vec4  shadowColor;
    #endif

    void main() {

        #if Shadow_Transparent > 0
            shadowColor = texture(tex, texcoord) * glColor;
            if (shadowColor.a < alphaTestRef) discard;
        #else
            float shadowAlpha = texture(tex, texcoord).a;
            if (shadowAlpha < alphaTestRef) discard;
        #endif

        // if(entity == 10010) {
        //     shadowColor.a = 0.0;

        //     float waterHeight = 1.0 - abs(waterHeightFuncSimple(worldPosVertex.xz, frameTimeCounter));
        //     float caustics = Water_Depth * pow(waterHeight, 3.0) + 0.5*(1 - Water_Depth) * 0.8 + 0.2;

        //     // caustics += 1.0;
        //     // caustics *= 2.0;

        //     #ifndef Water_VanillaTexture
        //         shadowColor.rgb = glColor.rgb;
        //     #endif
        //     shadowColor.rgb *= caustics;
        // }
    }

#endif