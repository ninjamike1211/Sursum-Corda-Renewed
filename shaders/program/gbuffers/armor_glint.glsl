#ifdef VERTEX
    uniform float viewWidth;
    uniform float viewHeight;
    uniform int frameCounter;

    #include "/lib/defines.glsl"
    #include "/lib/spaceConvert.glsl"

    out vec2 lmcoord;
    out vec2 texcoord;
    out vec4 glcolor;

    void main() {
        gl_Position = ftransform();

        #ifdef TAA
            gl_Position.xy += taaOffset(frameCounter, vec2(viewWidth, viewHeight)) * gl_Position.w;
        #endif

        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        lmcoord = gl_MultiTexCoord1.xy / 240.0;
        glcolor = gl_Color;
    }
#else
    #include "/lib/functions.glsl"

    uniform sampler2D lightmap;
    uniform sampler2D gtexture;

    in vec2 lmcoord;
    in vec2 texcoord;
    in vec4 glcolor;

    /* DRAWBUFFERS:2 */
    layout(location = 0) out vec4 albedoOut;

    void main() {
        vec4 color = texture2D(gtexture, texcoord) * glcolor;
        color *= texture2D(lightmap, lmcoord);

        // color.rgb = sRGBToLinear3(color.rgb);

        albedoOut = color; //gcolor
    }
#endif