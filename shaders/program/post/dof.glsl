#define DOF_ImageDistance 0.01
#define DOF_MaxRadius 0.05
#define DOF_MinRadius 0.001

float getCoCFromDepth(float depthLinear, float centerDepthLinear) {
    float focalLength = 1.0 / (1.0 / centerDepthLinear + 1.0 / DOF_ImageDistance);
    float CoC = (focalLength * (depthLinear - centerDepthLinear)) / (depthLinear * (centerDepthLinear - focalLength));

    CoC = clamp(CoC, -DOF_MaxRadius, DOF_MaxRadius);

    return CoC / DOF_MaxRadius;
}


#ifdef DOF_COCPASS

    #include "/lib/defines.glsl"
    #include "/lib/functions.glsl"
    #include "/lib/spaceConvert.glsl"

    uniform sampler2D colortex0;
    uniform usampler2D colortex6;
    uniform sampler2D colortex12;
    uniform sampler2D depthtex0;
    uniform float centerDepthSmooth;
    uniform float aspectRatio;
    uniform float near;
    uniform float far;

    in vec2 texcoord;

    /* RENDERTARGETS: 12 */
    layout(location = 0) out float cocOut;

    void main() {
        float depth = texture(depthtex0, texcoord).r;
        uint mask = texture(colortex6, texcoord).r;
        // sceneColor = texture(colortex0, texcoord).rgb;
        // foregroundColor = vec3(0.0);

        // Hand depth fix
        if((mask & Mask_Hand) != 0) {
            depth = convertHandDepth(depth);
        }

        float depthLinear = linearizeDepthFast(depth, near, far);
        float centerDepthLinear = linearizeDepthFast(centerDepthSmooth, near, far);

        cocOut = getCoCFromDepth(depthLinear, centerDepthLinear);

        // if(cocOut < 0.0) {
        // 	foregroundColor = sceneColor;
        // 	sceneColor = vec3(0.0);
        // }

    }
#else
#ifdef DOF_APPLYPASS

    #include "/lib/defines.glsl"
    #include "/lib/functions.glsl"
    #include "/lib/sky.glsl"
    #include "/lib/sample.glsl"

    uniform sampler2D colortex0;
    uniform sampler2D colortex12;
    uniform sampler2D colortex13;
    uniform float aspectRatio;

    in vec2 texcoord;

    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec4 sceneColor;

    void main() {
        sceneColor = texture(colortex0, texcoord);
        float coc = texture(colortex12, texcoord).r * DOF_MaxRadius;

        if(abs(coc) >= DOF_MinRadius) {
            int samples = 128;
            int samplesUsed = 1;
            for(int i = 1; i < samples; i++) {
                vec2 sampleOffset = (abs(coc) - DOF_MinRadius) * GetVogelDiskSample(i, samples, 0.0) * vec2(1.0, aspectRatio);
                float sampleCoc = texture(colortex12, texcoord + sampleOffset).x * DOF_MaxRadius;

                if(sign(sampleCoc) == sign(coc)) {
                    sceneColor.rgb += texture(colortex0, texcoord + sampleOffset).rgb;
                    samplesUsed++;
                }

                // if(abs(sampleCoc) >= length(sampleOffset) && sampleCoc <= coc) {
                    // colorVal += texture(colortex0, texcoord + sampleOffset).rgb;
                    // samplesUsed++;
                // }
            }

            sceneColor.rgb /= samplesUsed;
        }
    }

#endif
#endif