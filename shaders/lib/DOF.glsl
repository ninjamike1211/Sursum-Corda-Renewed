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

#ifdef FragmentStageCoC

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
    // float CoC = currentDist;
    // float CoC = DOF_Factor / far * abs(depth - centerDepthLinear);
    float focalLength = 1.0 / (1.0 / centerDepthLinear + 1.0 / DOF_ImageDistance);
    // float CoC = abs(DOF_FocalLength / (centerDepthLinear - DOF_FocalLength) * (1.0 - (centerDepthLinear / depth)));
    CoC = -(focalLength * (centerDepthLinear - depth)) / (depth * (centerDepthLinear - focalLength));
    // CoC = min(abs(CoC), 0.05);
    // cof = 0.003;

    if(isHand > 0.9)
    #ifdef DOF_HandBlur
        CoC = min(0.0, CoC*0.5 + 0.032);
    #else
        CoC = 0.0;
    #endif

    #ifndef DOF_NearBlur
    else
        CoC = max(0.0, CoC);
    #endif

    CoC = clamp(CoC, -DOF_MaxRadius, DOF_MaxRadius);
    CoC = CoC / DOF_MaxRadius * 0.5 + 0.5;

#endif

#ifdef FragmentStageBlur

    uniform sampler2D colortex0;
    uniform sampler2D colortex9;
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
    // uniform bool  isRiding;

    #include "/lib/defines.glsl"
    #include "/lib/kernels.glsl"
    #include "/lib/TAA.glsl"
    #include "/lib/spaceConvert.glsl"
    #include "/lib/sample.glsl"


    // ------------------------ File Contents -----------------------
        // Apply Depth of Field


    in vec2 texcoord;

    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec4 colorOut;

    void main() {

        colorOut = texture(colortex0, texcoord);

    // ----------------------------- DOF ----------------------------
        #ifdef DOF
        // if(!isRiding) {
            
            float depth = linearizeDepthFast(texture(depthtex1, texcoord).r);
            float CoC = (texture2D(colortex9, texcoord).r * 2.0 - 1.0) * DOF_MaxRadius;
            
            #ifdef DOF_NearTransitionBlur
                float accumCoC = CoC;
                int   blockerSamples = 1;

                for(int i = 0; i < 16; i++) {
                    vec2  samplePos = texcoord + 0.01 * GetVogelDiskSample(i, 16, 0.0) * vec2(1.0, aspectRatio);
                    float sampleCoC = (texture(colortex9, samplePos).r * 2.0 - 1.0) * DOF_MaxRadius;
                
                    // if(sampleCoC < 0.00 /* && abs(CoC) < 0.01 */) {
                        accumCoC += abs(sampleCoC);
                        blockerSamples++;
                    // }
                }

                accumCoC /= blockerSamples;
                CoC = accumCoC;
            #endif

            // if(CoC > 0.25 / viewHeight) {
                #ifdef DOF_VariableSampleCount
                    // int samples = int(mix(24, 384, clamp(pow(abs(CoC) * 50.0, 1.7), 0.0, 1.0)) + 1);
                    float area = CoC * CoC * PI * 0.25;
                    float pixels = area * viewWidth * viewHeight;

                    int samples = clamp(int(pixels * DOF_SampleDensity), DOF_MinSamples, DOF_MaxSamples);
                #else
                    int samples = int(DOF_ConstSamples);
                #endif
                
                int samplesUsed = 1;

                for(int i = 0; i < samples; i++) {
                    vec2  samplePos   = texcoord + CoC * GetVogelDiskSample(i, samples, 0.0) * vec2(1.0, aspectRatio);
                    float sampleDepth = linearizeDepthFast(texture(depthtex1, samplePos).r);

                    // if(sampleDepth - depth > -0.1) {
                        colorOut.rgb += texture(colortex0, samplePos).rgb;
                        samplesUsed++;
                    // }
                }

                colorOut.rgb /= samplesUsed;
            // }
        // }
        #endif
    }

#endif