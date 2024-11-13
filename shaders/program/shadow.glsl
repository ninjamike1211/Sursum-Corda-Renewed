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

    #define shadowGbuffer

    #include "/lib/defines.glsl"
    #include "/lib/shadows.glsl"
    #include "/lib/voxel.glsl"
    #include "/lib/weather.glsl"
    #include "/lib/water.glsl"

    void main() {

        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        glColor = gl_Color;


    // -------------------- Position Calculations -------------------
        vec4 modelPos = gl_Vertex;

        // // Fix for water inside cauldron incorrectly self-shadowing
        // if(entity == 10030 && glColor.r < 0.5) {
        //     modelPos.y -= 0.2;
        // }

        // Apply waving geometry
        #if defined(wavingPlants) || defined(Water_VertexOffset)
            int entity = int(mc_Entity.x + 0.5);
            vec3 worldPos = modelPos.xyz + cameraPosition;

            #ifdef Water_VertexOffset
            if(entity == MCEntity_Water) {
                modelPos.y += waterOffset(worldPos, frameTimeCounter);
            }
            #endif

            #ifdef wavingPlants
            if(entity > 10000 && entity < 10010) {
                vec3 viewNormal = normalize(gl_Normal);
                modelPos.xyz += wavingOffset(worldPos, entity, at_midBlock, viewNormal, frameTimeCounter, rainStrength);
            }
            #endif
        #endif

        gl_Position = gl_ModelViewProjectionMatrix * modelPos;

        // #ifndef TESSELLATION_SHADERS
            gl_Position.xyz = distort(gl_Position.xyz);
        // #endif

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
#ifdef Shadow_TCS

    #define shadowGbuffer
    #include "/lib/defines.glsl"
    #include "/lib/shadows.glsl"

    layout (vertices=3) out;

    in vec2 texcoord[];
    in vec4 glColor[];

    out vec2 texcoord_tes[];
    out vec4 glColor_tes[];

    float getTessLevel(float dist) {
        float denominator = dist + Shadow_Distort_Factor;
        float factor = Shadow_Distort_Factor / (denominator * denominator);
        return clamp(mix(Shadow_Max_Tessellation, 1.0, 0.01*factor), 1.0, Shadow_Max_Tessellation);
    }

    void main() {
        gl_TessLevelOuter[0] = getTessLevel(0.5*length(gl_in[1].gl_Position.xyz + gl_in[2].gl_Position.xyz));
		gl_TessLevelOuter[1] = getTessLevel(0.5*length(gl_in[2].gl_Position.xyz + gl_in[0].gl_Position.xyz));
		gl_TessLevelOuter[2] = getTessLevel(0.5*length(gl_in[0].gl_Position.xyz + gl_in[1].gl_Position.xyz));
		gl_TessLevelInner[0] = getTessLevel(0.33333333333333*length(gl_in[0].gl_Position.xyz + gl_in[1].gl_Position.xyz + gl_in[2].gl_Position.xyz));

        gl_out[gl_InvocationID].gl_Position = gl_in[gl_InvocationID].gl_Position;
        texcoord_tes[gl_InvocationID] = texcoord[gl_InvocationID];
        glColor_tes[gl_InvocationID] = glColor[gl_InvocationID];
    }

#else
#ifdef Shadow_TES

    #define shadowGbuffer
    #include "/lib/defines.glsl"
    #include "/lib/shadows.glsl"

    layout (triangles, fractional_odd_spacing, ccw) in;

    in vec2 texcoord_tes[];
    in vec4 glColor_tes[];
    
    out vec2 texcoord;
    out vec4 glColor;

    vec2 interpolate2D(vec2 v0, vec2 v1, vec2 v2) {
        return vec2(gl_TessCoord.x) * v0 + vec2(gl_TessCoord.y) * v1 + vec2(gl_TessCoord.z) * v2;
    }

    vec4 interpolate4D(vec4 v0, vec4 v1, vec4 v2) {
        return vec4(gl_TessCoord.x) * v0 + vec4(gl_TessCoord.y) * v1 + vec4(gl_TessCoord.z) * v2;
    } 

    void main() {
        texcoord = interpolate2D(texcoord_tes[0], texcoord_tes[1], texcoord_tes[2]);
        glColor = interpolate4D(glColor_tes[0], glColor_tes[1], glColor_tes[2]);

        gl_Position = interpolate4D(gl_in[0].gl_Position, gl_in[1].gl_Position, gl_in[2].gl_Position);
        gl_Position.xyz = distort(gl_Position.xyz);
    }

#else

    // #extension GL_ARB_conservative_depth : enable

    #define shadowGbuffer

    uniform sampler2D gtexture;
    uniform float alphaTestRef;

    #include "/lib/defines.glsl"


    // ------------------------ File Contents -----------------------
        // Shadows fragment shader
        // Applies water cuastics to shadows


    in vec2 texcoord;
    in vec4 glColor;

    #if Shadow_Transparent > 0
        /* RENDERTARGETS: 0 */
        layout(location = 0)  out vec4  shadowColor;
    #endif

    void main() {

        #if Shadow_Transparent > 0
            shadowColor = texture(gtexture, texcoord) * glColor;
            if (shadowColor.a < alphaTestRef) discard;
        #else
            float shadowAlpha = texture(gtexture, texcoord).a;
            if (shadowAlpha < alphaTestRef) discard;
        #endif
    }

#endif
#endif
#endif