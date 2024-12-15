#ifdef VERTEX

    uniform float viewWidth;
    uniform float viewHeight;
    uniform int frameCounter;

    #include "/lib/defines.glsl"
    #include "/lib/spaceConvert.glsl"

    flat out vec4 glcolor;
    out vec2 lmcoord;

    void main() {
        gl_Position = ftransform();
        
        #ifdef TAA
            gl_Position.xy += taaOffset(frameCounter, vec2(viewWidth, viewHeight)) * gl_Position.w;
        #endif

        glcolor = gl_Color;
        lmcoord = gl_MultiTexCoord1.xy / 240.0;
    }

#else

    #include "/lib/defines.glsl"

    flat in vec4 glcolor;
    in vec2 lmcoord;

    /* RENDERTARGETS: 2,3,4,5,6,7 */
    layout(location = 0) out vec4 albedoOut;
    layout(location = 1) out vec2 normalOut;
    layout(location = 2) out vec4 specularOut;
    layout(location = 3) out vec2 lightmapOut;
    layout(location = 4) out uint maskOut;
    layout(location = 5) out vec4 pomOut;

    void main() {
        albedoOut = glcolor;
        normalOut = vec2(0.0);
        specularOut = vec4(0.0);
        lightmapOut = lmcoord * lmcoord;
        maskOut = 0;
        pomOut = vec4(0.0);
    }

#endif