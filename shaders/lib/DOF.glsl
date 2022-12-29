#ifdef VertexStage

    // uniform float centerDepthSmooth;
    uniform sampler2D colortex12;
    uniform sampler2D depthtex0;
    uniform mat4 gbufferModelView;
    uniform mat4  gbufferModelViewInverse;
    uniform mat4  gbufferProjection;
    uniform mat4  gbufferProjectionInverse;
    uniform vec3  cameraPosition;
    uniform float near;
    uniform float far;
    uniform float viewWidth;
    uniform float viewHeight;
    uniform int   frameCounter;
    uniform int   worldTime;
    uniform bool  cameraMoved;

    #include "/lib/defines.glsl"
    #include "/lib/kernels.glsl"
    #include "/lib/TAA.glsl"
    #include "/lib/spaceConvert.glsl"


    // ------------------------ File Contents -----------------------
        // Standard fullscreen post-process vertex shader
        // Calculate linear center depth


    out vec2 texcoord;
    flat out float centerDepthLinear;

    void main() {
        gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
        
        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

        // centerDepthLinear = linearizeDepthFast(centerDepthSmooth);
        // centerDepthLinear = linearizeDepthFast(texture(depthtex0, vec2(0.5)).r);

        vec2 centerDepthData = texelFetch(colortex12, ivec2(1,0), 0).ba;
        float centerDepth = centerDepthData.r + (centerDepthData.g / 255.0);
        centerDepthLinear = linearizeDepthFast(centerDepth);
    }

#endif
#ifdef FragmentStage

    uniform sampler2D colortex0;
    uniform sampler2D colortex3;
    uniform sampler2D depthtex0;
    uniform sampler2D depthtex1;
    uniform mat4  gbufferModelView;
    uniform mat4  gbufferModelViewInverse;
    uniform mat4  gbufferProjection;
    uniform mat4  gbufferProjectionInverse;
    uniform vec3  cameraPosition;
    uniform float near;
    uniform float far;
    uniform float viewWidth;
    uniform float viewHeight;
    uniform float aspectRatio;
    uniform int   frameCounter;
    uniform int   worldTime;
    uniform bool  cameraMoved;

    #include "/lib/defines.glsl"
    #include "/lib/kernels.glsl"
    #include "/lib/TAA.glsl"
    #include "/lib/spaceConvert.glsl"
    #include "/lib/sample.glsl"


    // ------------------------ File Contents -----------------------
        // Apply Depth of Field


    in vec2 texcoord;
    flat in float centerDepthLinear;

    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec4 colorOut;

    void main() {

        colorOut = texture(colortex0, texcoord);

    // ----------------------------- DOF ----------------------------
        #ifdef DOF
            // float currentDist = unpackCoC(texture(colortex14, texcoord).r);
            float isHand = texture(colortex3, texcoord).b;
            float depth = linearizeDepthFast(texture(depthtex1, texcoord).r);
            // float blockerDist = 0.0;
            // float count = 0.0;

            // for(int i = 0; i < DOF_Blocker_Samples; i++) {
            //     vec2 samplePos = texcoord + DOF_Factor * GetVogelDiskSample(i, DOF_Blocker_Samples, 0.0) * vec2(1.0, aspectRatio);
            //     float dist = (texture(colortex14, samplePos).r * 2.0 - 1.0) * DOF_Factor;

            //     if(currentDist - dist > -0.01) {
            //         blockerDist += abs(dist-currentDist);
            //         count++;
            //     }
            // }
            // float cof = blockerDist / count;
            // float coc = currentDist;
            // float coc = DOF_Factor / far * abs(depth - centerDepthLinear);
            float focalLength = 1.0 / (1.0 / centerDepthLinear + 1.0 / DOF_ImageDistance);
            // float coc = abs(DOF_FocalLength / (centerDepthLinear - DOF_FocalLength) * (1.0 - (centerDepthLinear / depth)));
            float coc = -(focalLength * (centerDepthLinear - depth)) / (depth * (centerDepthLinear - focalLength));
            // coc = min(abs(coc), 0.05);
            // cof = 0.003;

            if(isHand > 0.9)
            #ifdef DOF_HandBlur
                coc = min(0.0, coc*0.5 + 0.032);
            #else
                coc = 0.0;
            #endif

            #ifndef DOF_NearBlur
            else
                coc = max(0.0, coc);
            #endif

            // if(coc > 0.25 / viewHeight) {
                #ifdef DOF_VariableSampleCount
                    // int samples = int(mix(24, 384, clamp(pow(abs(coc) * 50.0, 1.7), 0.0, 1.0)) + 1);
                    float area = coc * coc * PI * 0.25;
                    float pixels = area * viewWidth * viewHeight;

                    int samples = clamp(int(pixels * DOF_SampleDensity), DOF_MinSamples, DOF_MaxSamples);
                #else
                    int samples = int(DOF_ConstSamples);
                #endif
                
                int samplesUsed = 1;

                for(int i = 0; i < samples; i++) {
                    vec2 samplePos = texcoord + coc * GetVogelDiskSample(i, samples, 0.0) * vec2(1.0, aspectRatio);
                    // float sampleDepth = linearizeDepthFast(texture(depthtex0, samplePos).r);
                    // if(depth - sampleDepth > 0.1)
                    //     // albedo.rgb += texture(colortex0, texcoord).rgb;
                    //     samplesUsed--;
                    // else
                        colorOut.rgb += texture(colortex0, samplePos).rgb;
                    
                    samplesUsed++;
                }

                colorOut.rgb /= samplesUsed;
            // }
        #endif
    }

#endif